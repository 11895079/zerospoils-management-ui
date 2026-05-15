import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _pendingFeedbackKey = 'pending_feedback_submissions_v1';
const String _deviceFingerprintKey = 'feedback_device_fingerprint_v1';
const int _feedbackRateWindowMs = 10 * 60 * 1000;
const String _feedbackIngestUrl = String.fromEnvironment(
  'FEEDBACK_INGEST_URL',
  defaultValue: '',
);

enum FeedbackSubmitOutcome { submitted, queued }

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

class FeedbackSubmissionService {
  FeedbackSubmissionService({
    FirebaseFirestore? firestore,
    String? Function()? userIdProvider,
  }) : _firestore = firestore,
       _userIdProvider = userIdProvider ?? _defaultUserIdProvider;

  final FirebaseFirestore? _firestore;
  final String? Function() _userIdProvider;

  Future<FeedbackSubmitOutcome> submit(
    FeedbackSubmissionRequest request,
  ) async {
    final userId = _userIdProvider();
    if (userId == null || userId.isEmpty) {
      throw StateError('AUTH_REQUIRED');
    }

    final payload = await _buildSerializablePayload(request, userId);
    final ingestEnabled = _feedbackIngestUrl.isNotEmpty;
    final firestore = ingestEnabled ? null : _resolveFirestore();

    if (!ingestEnabled && firestore == null) {
      await _queuePayload(payload);
      return FeedbackSubmitOutcome.queued;
    }

    try {
      if (ingestEnabled) {
        await _flushPendingToIngestApi();
        await _sendToIngestApi(payload, userId);
      } else {
        await _flushPending(firestore!);
        await _sendToFirestore(firestore, payload);
      }
      return FeedbackSubmitOutcome.submitted;
    } catch (_) {
      await _queuePayload(payload);
      return FeedbackSubmitOutcome.queued;
    }
  }

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
  ) async {
    final userId = payload['user_id'] as String?;
    final deviceFingerprint = payload['device_fingerprint'] as String?;
    if (userId == null ||
        userId.isEmpty ||
        deviceFingerprint == null ||
        deviceFingerprint.isEmpty) {
      throw StateError('INVALID_FEEDBACK_PAYLOAD');
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final timeWindowId = nowMs ~/ _feedbackRateWindowMs;
    final feedbackId = '${userId}_${deviceFingerprint}_$timeWindowId';

    final firestorePayload = Map<String, dynamic>.from(payload)
      ..['created_at'] = FieldValue.serverTimestamp();

    await firestore
        .collection('feedback_submissions')
        .doc(feedbackId)
        .set(firestorePayload);
  }

  Future<void> _sendToIngestApi(
    Map<String, dynamic> payload,
    String userId,
  ) async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw StateError('AUTH_REQUIRED');
    }

    final appCheckToken = await FirebaseAppCheck.instance.getToken();

    final response = await http.post(
      Uri.parse(_feedbackIngestUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
        if (appCheckToken != null && appCheckToken.isNotEmpty)
          'X-Firebase-AppCheck': appCheckToken,
      },
      body: jsonEncode({...payload, 'user_id': userId}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('INGEST_REJECTED_${response.statusCode}');
    }
  }

  FirebaseFirestore? _resolveFirestore() {
    if (_firestore != null) {
      return _firestore;
    }

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
    if (kIsWeb) {
      return 'web';
    }

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
    await prefs.setStringList(_pendingFeedbackKey, current);
  }

  Future<void> _flushPending(FirebaseFirestore firestore) async {
    final prefs = await SharedPreferences.getInstance();
    final rawQueue = prefs.getStringList(_pendingFeedbackKey);

    if (rawQueue == null || rawQueue.isEmpty) {
      return;
    }

    final remaining = <String>[];

    for (final entry in rawQueue) {
      try {
        final decoded = jsonDecode(entry);
        if (decoded is! Map<String, dynamic>) {
          continue;
        }
        await _sendToFirestore(firestore, decoded);
      } catch (_) {
        remaining.add(entry);
      }
    }

    if (remaining.isEmpty) {
      await prefs.remove(_pendingFeedbackKey);
    } else {
      await prefs.setStringList(_pendingFeedbackKey, remaining);
    }
  }

  Future<void> _flushPendingToIngestApi() async {
    final userId = _userIdProvider();
    if (userId == null || userId.isEmpty) {
      throw StateError('AUTH_REQUIRED');
    }

    final prefs = await SharedPreferences.getInstance();
    final rawQueue = prefs.getStringList(_pendingFeedbackKey);

    if (rawQueue == null || rawQueue.isEmpty) {
      return;
    }

    final remaining = <String>[];

    for (final entry in rawQueue) {
      try {
        final decoded = jsonDecode(entry);
        if (decoded is! Map<String, dynamic>) {
          continue;
        }
        await _sendToIngestApi(decoded, userId);
      } catch (_) {
        remaining.add(entry);
      }
    }

    if (remaining.isEmpty) {
      await prefs.remove(_pendingFeedbackKey);
    } else {
      await prefs.setStringList(_pendingFeedbackKey, remaining);
    }
  }

  Future<String> _loadOrCreateDeviceFingerprint() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceFingerprintKey);

    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final random = Random.secure();
    final partA = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final partB = random.nextInt(1 << 32).toRadixString(36).padLeft(7, '0');
    final fingerprint = '${partA}_$partB';
    await prefs.setString(_deviceFingerprintKey, fingerprint);
    return fingerprint;
  }
}
