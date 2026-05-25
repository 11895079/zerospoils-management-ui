import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── SharedPreferences keys ───────────────────────────────────────────────────
const String _pendingFeedbackKey = 'pending_feedback_submissions_v1';
const String _deviceFingerprintKey = 'feedback_device_fingerprint_v1';

/// Versioned separately so old rate-state is silently discarded on first run
/// after this migration rather than causing a parse error.
const String _rateLimitStateKey = 'feedback_rate_state_v2';

// ─── Rate-limit policy ────────────────────────────────────────────────────────
// Client-side constants mirror back-end Firestore Security Rules enforcement.
// The server is the authoritative source of truth and will silently drop
// over-limit writes regardless; these constants keep the client in sync and
// reduce unnecessary network calls.

/// At most one item is flushed per hour window.
const int _hourWindowMs = 60 * 60 * 1000;

/// Burst detection: more than [_burstLimit] successful sends within
/// [_burstWindowMs] triggers a 1-hour client-side flush pause.
const int _burstWindowMs = 5 * 60 * 1000;
const int _burstLimit = 3;
const int _burstPauseMs = 60 * 60 * 1000;

/// Daily cap: after [_dailyLimit] successful sends in a calendar day the
/// client enters a block period. Repeat offenders (violationCount > 1) receive
/// an escalated block.
const int _dailyLimit = 24;
const int _initialBlockMs = 24 * 60 * 60 * 1000; // 1st violation: 24 h
const int _escalatedBlockMs = 72 * 60 * 60 * 1000; // 2nd+ violation: 72 h

/// Queue is bounded so SharedPreferences stays small.
const int _maxPendingFeedbackQueue = 100;

/// Number of recent message-content hashes retained for content dedup.
const int _maxRecentHashes = 10;
// ─────────────────────────────────────────────────────────────────────────────

enum FeedbackSubmitOutcome {
  /// Accepted and immediately flushed to the server (rare fast-path).
  submitted,

  /// Accepted locally; will be flushed in a background attempt.
  /// Callers should treat this as a user-visible success — the payload is
  /// durable in SharedPreferences until confirmed by Firestore.
  queued,
}

class FeedbackSubmissionRequest {
  const FeedbackSubmissionRequest({
    required this.message,
    required this.category,
    required this.source,
    required this.locale,
    this.email,
  });

  final String message;
  final String category;
  final String source;
  final String locale;
  final String? email;
}

// ─── Internal rate-limit state ────────────────────────────────────────────────

class _RateLimitState {
  _RateLimitState({
    this.lastSentMs = 0,
    this.dailyCount = 0,
    this.dailyDate = '',
    this.blockedUntilMs = 0,
    this.violationCount = 0,
    List<int>? burstTimestamps,
    List<String>? recentHashes,
  }) : burstTimestamps = burstTimestamps ?? [],
       recentHashes = recentHashes ?? [];

  /// Epoch ms of the last successfully flushed document.
  int lastSentMs;

  /// Count of items flushed on [dailyDate].
  int dailyCount;

  /// ISO-8601 date string (yyyy-MM-dd) for which [dailyCount] is valid.
  String dailyDate;

  /// Epoch ms until which all flush attempts are blocked (0 = unblocked).
  int blockedUntilMs;

  /// Incremented each time the daily cap is hit; drives block-duration
  /// escalation.
  int violationCount;

  /// Epoch ms timestamps of recent successful sends (pruned to burst window).
  List<int> burstTimestamps;

  /// Stable content hashes of recently sent message bodies for dedup.
  List<String> recentHashes;

  factory _RateLimitState.fromJson(Map<String, dynamic> json) =>
      _RateLimitState(
        lastSentMs: json['last_sent_ms'] as int? ?? 0,
        dailyCount: json['daily_count'] as int? ?? 0,
        dailyDate: json['daily_date'] as String? ?? '',
        blockedUntilMs: json['blocked_until_ms'] as int? ?? 0,
        violationCount: json['violation_count'] as int? ?? 0,
        burstTimestamps:
            (json['burst_timestamps'] as List<dynamic>?)
                ?.whereType<int>()
                .toList() ??
            [],
        recentHashes:
            (json['recent_hashes'] as List<dynamic>?)
                ?.whereType<String>()
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
    'last_sent_ms': lastSentMs,
    'daily_count': dailyCount,
    'daily_date': dailyDate,
    'blocked_until_ms': blockedUntilMs,
    'violation_count': violationCount,
    'burst_timestamps': burstTimestamps,
    'recent_hashes': recentHashes,
  };
}

// ─── Service ──────────────────────────────────────────────────────────────────

class FeedbackSubmissionService {
  FeedbackSubmissionService({
    FirebaseFirestore? firestore,
    String? Function()? userIdProvider,
    @visibleForTesting int Function()? nowMs,
  }) : _firestore = firestore,
       _userIdProvider = userIdProvider ?? _defaultUserIdProvider,
       _nowMs = nowMs ?? (() => DateTime.now().millisecondsSinceEpoch);

  final FirebaseFirestore? _firestore;
  final String? Function() _userIdProvider;
  final int Function() _nowMs;

  // ─── Public API ─────────────────────────────────────────────────────────────

  /// Accepts a feedback submission.
  ///
  /// The payload is always persisted to the local queue before this method
  /// returns, so the caller can treat every non-exception outcome as a
  /// user-visible success — the feedback is durable regardless of network
  /// state or back-end rate limits. A best-effort background flush is launched
  /// after queuing; its result does not affect the return value.
  ///
  /// Throws [StateError('AUTH_REQUIRED')] when the current user is not signed
  /// in, which is the only error callers need to surface.
  Future<FeedbackSubmitOutcome> submit(
    FeedbackSubmissionRequest request,
  ) async {
    final userId = _userIdProvider();
    if (userId == null || userId.isEmpty) {
      throw StateError('AUTH_REQUIRED');
    }

    final payload = await _buildSerializablePayload(request, userId);

    // Step 1 — Persist locally first.  Success is guaranteed to the caller
    // regardless of connectivity or server-side rate limits.
    await _queuePayload(payload);

    // Step 2 — Best-effort background flush.  Intentionally not awaited; the
    // outcome does not affect the returned value or user-visible behaviour.
    unawaited(_tryFlushBackground());

    return FeedbackSubmitOutcome.queued;
  }

  // ─── Background flush ────────────────────────────────────────────────────────

  Future<void> _tryFlushBackground() async {
    try {
      final firestore = _resolveFirestore();
      if (firestore == null) return;

      final prefs = await SharedPreferences.getInstance();
      final state = _loadRateLimitState(prefs);
      final now = _nowMs();

      // Hard block period (daily cap or burst enforcement).
      if (state.blockedUntilMs > now) {
        debugPrint(
          '[FeedbackSubmissionService] Flush blocked until '
          '${DateTime.fromMillisecondsSinceEpoch(state.blockedUntilMs).toIso8601String()}',
        );
        return;
      }

      // 1-hour send window: at most one successful flush per window.
      if (now - state.lastSentMs < _hourWindowMs) {
        return;
      }

      // Burst guard: trim stale timestamps and check the live window count.
      state.burstTimestamps = state.burstTimestamps
          .where((ts) => now - ts < _burstWindowMs)
          .toList();
      if (state.burstTimestamps.length >= _burstLimit) {
        debugPrint(
          '[FeedbackSubmissionService] Burst detected — pausing flush for 1 h',
        );
        state.blockedUntilMs = now + _burstPauseMs;
        await _saveRateLimitState(prefs, state);
        return;
      }

      await _flushOne(firestore, prefs, state, now);
    } catch (e) {
      // Background errors are swallowed — items remain queued for the next
      // attempt.  The user is never notified.
      debugPrint('[FeedbackSubmissionService] Background flush error: $e');
    }
  }

  /// Sends the oldest non-duplicate item from the local queue, then updates
  /// rate-limit state and enforces the daily cap.
  Future<void> _flushOne(
    FirebaseFirestore firestore,
    SharedPreferences prefs,
    _RateLimitState state,
    int now,
  ) async {
    final rawQueue = prefs.getStringList(_pendingFeedbackKey);
    if (rawQueue == null || rawQueue.isEmpty) return;

    final remaining = <String>[];
    var didSend = false;

    for (final entry in rawQueue) {
      // Keep everything after the first successful send for the next window.
      if (didSend) {
        remaining.add(entry);
        continue;
      }

      Map<String, dynamic>? decoded;
      try {
        final raw = jsonDecode(entry);
        if (raw is Map<String, dynamic>) decoded = raw;
      } catch (_) {
        continue; // Malformed entry — drop silently.
      }
      if (decoded == null) continue;

      // Content dedup: identical message body seen recently → drop the
      // duplicate from the queue without sending it.
      final hash = _stableHash(decoded['message'] as String? ?? '');
      if (state.recentHashes.contains(hash)) {
        continue;
      }

      try {
        await _sendToFirestore(firestore, decoded, now);
        didSend = true;

        // Advance rate-limit state after a confirmed send.
        state.lastSentMs = now;
        state.burstTimestamps = [...state.burstTimestamps, now];
        _incrementDailyCount(state, now);
        state.recentHashes = [
          ...state.recentHashes.take(_maxRecentHashes - 1),
          hash,
        ];
      } catch (_) {
        remaining.add(entry); // Transient failure — keep for retry.
      }
    }

    // Persist updated queue.
    if (remaining.isEmpty) {
      await prefs.remove(_pendingFeedbackKey);
    } else {
      await prefs.setStringList(_pendingFeedbackKey, remaining);
    }

    // Persist updated rate state.
    await _saveRateLimitState(prefs, state);

    // Enforce daily cap: block future flushes with escalating duration.
    if (didSend && state.dailyCount >= _dailyLimit) {
      state.violationCount++;
      final blockDuration = state.violationCount > 1
          ? _escalatedBlockMs
          : _initialBlockMs;
      state.blockedUntilMs = now + blockDuration;
      await _saveRateLimitState(prefs, state);
      debugPrint(
        '[FeedbackSubmissionService] Daily cap reached — '
        'blocked for ${blockDuration ~/ 3600000} h '
        '(violation #${state.violationCount})',
      );
    }
  }

  // ─── Rate-limit state helpers ─────────────────────────────────────────────

  _RateLimitState _loadRateLimitState(SharedPreferences prefs) {
    final raw = prefs.getString(_rateLimitStateKey);
    if (raw == null) return _RateLimitState();
    try {
      return _RateLimitState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return _RateLimitState(); // Corrupt state — start fresh.
    }
  }

  Future<void> _saveRateLimitState(
    SharedPreferences prefs,
    _RateLimitState state,
  ) => prefs.setString(_rateLimitStateKey, jsonEncode(state.toJson()));

  void _incrementDailyCount(_RateLimitState state, int nowMs) {
    final today = _isoDate(nowMs);
    if (state.dailyDate != today) {
      // New calendar day — reset the daily counter.
      state.dailyDate = today;
      state.dailyCount = 0;
    }
    state.dailyCount++;
  }

  String _isoDate(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${dt.year}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }

  /// Deterministic (non-randomised) hash for content dedup across app restarts.
  /// Uses a djb2-style mix that is stable across Dart versions.
  String _stableHash(String message) {
    final s = message.trim().toLowerCase();
    var h = 5381;
    for (var i = 0; i < s.length; i++) {
      // ignore: avoid_js_rounded_ints
      h = ((h * 33) ^ s.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return h.toRadixString(16);
  }

  // ─── Firestore write ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _buildSerializablePayload(
    FeedbackSubmissionRequest request,
    String userId,
  ) async {
    String appVersion = 'unknown';
    String buildNumber = 'unknown';
    final deviceFingerprint = await _loadOrCreateDeviceFingerprint();

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
    } catch (_) {
      // Fall back to unknown values when package metadata is unavailable.
    }

    return {
      'message': request.message.trim(),
      'category': request.category,
      'source': request.source,
      'email': request.email?.trim(),
      'device_fingerprint': deviceFingerprint,
      'platform': _platformName(),
      'app_version': appVersion,
      'build_number': buildNumber,
      'locale': request.locale,
      'user_id': userId,
      'created_at_client': DateTime.now().toIso8601String(),
      'status': 'new',
    };
  }

  Future<void> _sendToFirestore(
    FirebaseFirestore firestore,
    Map<String, dynamic> payload,
    int nowMs,
  ) async {
    final userId = payload['user_id'] as String?;
    final deviceFingerprint = payload['device_fingerprint'] as String?;
    if (userId == null ||
        userId.isEmpty ||
        deviceFingerprint == null ||
        deviceFingerprint.isEmpty) {
      throw StateError('INVALID_FEEDBACK_PAYLOAD');
    }

    // Document ID uses a 1-hour window so Firestore naturally deduplicates
    // submissions within the same window (later .set() overwrites earlier).
    // The back-end Security Rules mirror this window for server-side enforcement.
    final hourWindowId = nowMs ~/ _hourWindowMs;
    final feedbackId = '${userId}_${deviceFingerprint}_$hourWindowId';

    final firestorePayload = Map<String, dynamic>.from(payload)
      ..['created_at'] = FieldValue.serverTimestamp();

    await firestore
        .collection('feedback_submissions')
        .doc(feedbackId)
        .set(firestorePayload);
  }

  // ─── Infrastructure helpers ────────────────────────────────────────────────

  FirebaseFirestore? _resolveFirestore() {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  static String? _defaultUserIdProvider() {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  String _platformName() {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }

  Future<void> _queuePayload(Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_pendingFeedbackKey) ?? <String>[];
    current.add(jsonEncode(payload));
    if (current.length > _maxPendingFeedbackQueue) {
      // Drop oldest entries to keep the SharedPreferences queue bounded.
      current.removeRange(0, current.length - _maxPendingFeedbackQueue);
    }
    await prefs.setStringList(_pendingFeedbackKey, current);
  }

  Future<String> _loadOrCreateDeviceFingerprint() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceFingerprintKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final random = Random.secure();
    final partA = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final partB = random.nextInt(1 << 32).toRadixString(36).padLeft(7, '0');
    final fingerprint = '${partA}_$partB';
    await prefs.setString(_deviceFingerprintKey, fingerprint);
    return fingerprint;
  }
}
