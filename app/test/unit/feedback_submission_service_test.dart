import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerospoils/core/feedback/feedback_submission_service.dart';

// ─── Firestore fakes ──────────────────────────────────────────────────────────

class FakeDocumentReference extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  final FakeFirestore _parent;
  final String _docId;

  FakeDocumentReference(this._parent, this._docId);

  @override
  String get id => _docId;

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    if (_parent.shouldThrow) throw Exception('Firestore write error');
    _parent.writes.add({'id': _docId, 'data': Map<String, dynamic>.from(data)});
  }
}

class FakeCollectionReference extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  final FakeFirestore _parent;

  FakeCollectionReference(this._parent);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      FakeDocumentReference(_parent, path ?? '');
}

class FakeFirestore extends Fake implements FirebaseFirestore {
  final List<Map<String, dynamic>> writes = [];
  bool shouldThrow = false;

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      FakeCollectionReference(this);
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

const String _queueKey = 'pending_feedback_submissions_v1';
const String _rateLimitKey = 'feedback_rate_state_v2';

FeedbackSubmissionRequest makeRequest({String message = 'test feedback'}) =>
    FeedbackSubmissionRequest(
      message: message,
      category: 'bug_report',
      source: 'test',
      locale: 'en',
    );

/// Pre-populates the queue with a minimal valid payload so flush tests can
/// call [FeedbackSubmissionService.flushForTesting] directly without going
/// through [submit], which would fire a concurrent unawaited flush.
Future<void> queueRawItem({
  String message = 'test feedback',
  String userId = 'user-123',
  String deviceFingerprint = 'test-fp',
}) async {
  final prefs = await SharedPreferences.getInstance();
  final current = prefs.getStringList(_queueKey) ?? [];
  current.add(
    jsonEncode({
      'message': message,
      'category': 'bug_report',
      'source': 'test',
      'email': null,
      'device_fingerprint': deviceFingerprint,
      'platform': 'android',
      'app_version': '1.0',
      'build_number': '1',
      'locale': 'en',
      'user_id': userId,
      'created_at_client': '2026-01-01T00:00:00.000',
      'status': 'new',
    }),
  );
  await prefs.setStringList(_queueKey, current);
}

Future<void> setRateState({
  int lastSentMs = 0,
  int dailyCount = 0,
  String? dailyDate,
  int blockedUntilMs = 0,
  int violationCount = 0,
  List<int> burstTimestamps = const [],
  List<String> recentHashes = const [],
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    _rateLimitKey,
    jsonEncode({
      'last_sent_ms': lastSentMs,
      'daily_count': dailyCount,
      'daily_date': dailyDate ?? '',
      'blocked_until_ms': blockedUntilMs,
      'violation_count': violationCount,
      'burst_timestamps': burstTimestamps,
      'recent_hashes': recentHashes,
    }),
  );
}

Future<List<dynamic>> readQueue() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getStringList(_queueKey) ?? [];
  return raw.map(jsonDecode).toList();
}

Future<Map<String, dynamic>> readRateState() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_rateLimitKey);
  if (raw == null) return {};
  return jsonDecode(raw) as Map<String, dynamic>;
}

String stableHash(String message) {
  final s = message.trim().toLowerCase();
  var h = 5381;
  for (var i = 0; i < s.length; i++) {
    h = ((h * 33) ^ s.codeUnitAt(i)) & 0x7FFFFFFF;
  }
  return h.toRadixString(16);
}

// Fixed epoch for deterministic time control (arbitrary, but stable).
const int _t0 = 1_748_000_000_000;
const int _hourMs = 60 * 60 * 1000;
const int _dayMs = 24 * _hourMs;

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  late FakeFirestore fakeFirestore;
  var fakeNow = _t0;

  /// Returns a service where [submit]'s unawaited flush is suppressed by
  /// passing a null firestore, so flush tests can drive [flushForTesting]
  /// independently.  Use [makeFlushService] when you need a real firestore.
  FeedbackSubmissionService makeSubmitService({String? userId = 'user-123'}) =>
      FeedbackSubmissionService(
        firestore: null, // suppresses the unawaited flush from submit()
        userIdProvider: () => userId,
        nowMs: () => fakeNow,
      );

  FeedbackSubmissionService makeFlushService({bool firestoreNull = false}) =>
      FeedbackSubmissionService(
        firestore: firestoreNull ? null : fakeFirestore,
        userIdProvider: () => 'user-123',
        nowMs: () => fakeNow,
      );

  setUp(() {
    SharedPreferences.resetStatic();
    SharedPreferences.setMockInitialValues({});
    fakeFirestore = FakeFirestore();
    fakeNow = _t0;
  });

  // ─── submit() — auth guard ────────────────────────────────────────────────

  group('submit() — auth guard', () {
    test('throws AUTH_REQUIRED when userId is null', () {
      final svc = makeSubmitService(userId: null);
      expect(
        () => svc.submit(makeRequest()),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'AUTH_REQUIRED',
          ),
        ),
      );
    });

    test('throws AUTH_REQUIRED when userId is empty string', () {
      final svc = makeSubmitService(userId: '');
      expect(
        () => svc.submit(makeRequest()),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'AUTH_REQUIRED',
          ),
        ),
      );
    });
  });

  // ─── submit() — queue-first guarantee ────────────────────────────────────

  group('submit() — queue-first guarantee', () {
    test('always returns queued', () async {
      final svc = makeSubmitService();
      final outcome = await svc.submit(makeRequest());
      expect(outcome, FeedbackSubmitOutcome.queued);
    });

    test('persists payload to SharedPreferences before returning', () async {
      final svc = makeSubmitService();
      await svc.submit(makeRequest(message: 'my feedback'));

      final queue = await readQueue();
      expect(queue, hasLength(1));
      expect(queue.first['message'], 'my feedback');
      expect(queue.first['category'], 'bug_report');
      expect(queue.first['user_id'], 'user-123');
    });

    test('queues even when Firestore is unavailable', () async {
      // makeSubmitService already uses null firestore; redundant but explicit.
      final svc = makeSubmitService();
      await svc.submit(makeRequest());

      final queue = await readQueue();
      expect(queue, hasLength(1));
    });

    test('accumulates multiple submissions in the queue', () async {
      final svc = makeSubmitService();
      await svc.submit(makeRequest(message: 'alpha'));
      await svc.submit(makeRequest(message: 'beta'));

      final queue = await readQueue();
      expect(queue, hasLength(2));
      expect(queue.map((e) => e['message']).toList(), ['alpha', 'beta']);
    });

    test('drops oldest entries when queue exceeds 100-item cap', () async {
      final svc = makeSubmitService();
      for (var i = 0; i < 101; i++) {
        await svc.submit(makeRequest(message: 'item $i'));
      }

      final queue = await readQueue();
      expect(queue.length, lessThanOrEqualTo(100));
      // Oldest item (item 0) dropped; newest (item 100) survives.
      expect(queue.any((e) => e['message'] == 'item 100'), isTrue);
      expect(queue.any((e) => e['message'] == 'item 0'), isFalse);
    });
  });

  // ─── flush — basic send ───────────────────────────────────────────────────

  group('flush — basic send', () {
    test('sends queued item to Firestore', () async {
      await queueRawItem();
      await makeFlushService().flushForTesting();

      expect(fakeFirestore.writes, hasLength(1));
    });

    test('removes sent item from queue', () async {
      await queueRawItem();
      await makeFlushService().flushForTesting();

      expect(await readQueue(), isEmpty);
    });

    test('updates lastSentMs in rate state after flush', () async {
      await queueRawItem();
      await makeFlushService().flushForTesting();

      final state = await readRateState();
      expect(state['last_sent_ms'], _t0);
    });

    test(
      'document ID encodes userId, device fingerprint, and hour window',
      () async {
        await queueRawItem(userId: 'u1', deviceFingerprint: 'fp1');
        await makeFlushService().flushForTesting();

        final docId = fakeFirestore.writes.first['id'] as String;
        expect(docId, startsWith('u1_fp1_'));
      },
    );

    test(
      'sends only the oldest item per flush when multiple are queued',
      () async {
        await queueRawItem(message: 'first');
        await queueRawItem(message: 'second');
        await makeFlushService().flushForTesting();

        expect(fakeFirestore.writes, hasLength(1));
        expect(fakeFirestore.writes.first['data']['message'], 'first');

        // Second item remains queued.
        final queue = await readQueue();
        expect(queue, hasLength(1));
        expect(queue.first['message'], 'second');
      },
    );

    test('skips flush when queue is empty', () async {
      await makeFlushService().flushForTesting();
      expect(fakeFirestore.writes, isEmpty);
    });

    test('skips flush when Firestore is unavailable', () async {
      await queueRawItem();
      await expectLater(
        makeFlushService(firestoreNull: true).flushForTesting(),
        completes,
      );
      expect(fakeFirestore.writes, isEmpty);
    });
  });

  // ─── flush — 1-hour window ────────────────────────────────────────────────

  group('flush — 1-hour window', () {
    test('skips flush when last send was less than 1 hour ago', () async {
      await setRateState(lastSentMs: _t0 - (_hourMs - 1000)); // 59 min ago
      await queueRawItem();
      await makeFlushService().flushForTesting();

      expect(fakeFirestore.writes, isEmpty);
    });

    test('flushes when exactly 1-hour window has elapsed', () async {
      await setRateState(lastSentMs: _t0 - _hourMs - 1); // just past 1 h
      await queueRawItem();
      await makeFlushService().flushForTesting();

      expect(fakeFirestore.writes, hasLength(1));
    });
  });

  // ─── flush — block period ─────────────────────────────────────────────────

  group('flush — block period', () {
    test('skips flush while blockedUntilMs is in the future', () async {
      await setRateState(blockedUntilMs: _t0 + _hourMs);
      await queueRawItem();
      await makeFlushService().flushForTesting();

      expect(fakeFirestore.writes, isEmpty);
    });

    test('flushes normally once block period has expired', () async {
      await setRateState(blockedUntilMs: _t0 - 1); // expired 1 ms ago
      await queueRawItem();
      await makeFlushService().flushForTesting();

      expect(fakeFirestore.writes, hasLength(1));
    });
  });

  // ─── flush — burst detection ──────────────────────────────────────────────

  group('flush — burst detection', () {
    const burstWindowMs = 5 * 60 * 1000;

    test('allows send when under burst limit', () async {
      // 2 timestamps in the burst window — under the limit of 3.
      await setRateState(
        lastSentMs: _t0 - _hourMs - 1,
        burstTimestamps: [
          _t0 - burstWindowMs + 10000,
          _t0 - burstWindowMs + 20000,
        ],
      );
      await queueRawItem();
      await makeFlushService().flushForTesting();

      expect(fakeFirestore.writes, hasLength(1));
    });

    test(
      'blocks send and sets blockedUntilMs when burst limit is reached',
      () async {
        // 3 timestamps in the burst window — at the limit.
        await setRateState(
          lastSentMs: _t0 - _hourMs - 1,
          burstTimestamps: [
            _t0 - burstWindowMs + 1000,
            _t0 - burstWindowMs + 2000,
            _t0 - burstWindowMs + 3000,
          ],
        );
        await queueRawItem();
        await makeFlushService().flushForTesting();

        expect(fakeFirestore.writes, isEmpty);
        final state = await readRateState();
        expect(state['blocked_until_ms'], greaterThan(_t0));
      },
    );

    test('stale timestamps outside burst window do not count', () async {
      // 3 timestamps all older than the burst window.
      await setRateState(
        lastSentMs: _t0 - _hourMs - 1,
        burstTimestamps: [
          _t0 - burstWindowMs - 3000,
          _t0 - burstWindowMs - 2000,
          _t0 - burstWindowMs - 1000,
        ],
      );
      await queueRawItem();
      await makeFlushService().flushForTesting();

      // Stale entries pruned → under limit → flush proceeds.
      expect(fakeFirestore.writes, hasLength(1));
    });
  });

  // ─── flush — daily cap ────────────────────────────────────────────────────

  group('flush — daily cap', () {
    String todayStr() {
      final dt = DateTime.fromMillisecondsSinceEpoch(_t0);
      return '${dt.year}-'
          '${dt.month.toString().padLeft(2, '0')}-'
          '${dt.day.toString().padLeft(2, '0')}';
    }

    test('sends successfully when under daily limit', () async {
      await setRateState(
        lastSentMs: _t0 - _hourMs - 1,
        dailyCount: 10,
        dailyDate: todayStr(),
      );
      await queueRawItem();
      await makeFlushService().flushForTesting();

      expect(fakeFirestore.writes, hasLength(1));
    });

    test(
      'sets 24-h block and increments violationCount when daily cap is hit',
      () async {
        // Pre-set count to 23 so this flush tips it to 24.
        await setRateState(
          lastSentMs: _t0 - _hourMs - 1,
          dailyCount: 23,
          dailyDate: todayStr(),
          violationCount: 0,
        );
        await queueRawItem();
        await makeFlushService().flushForTesting();

        // The send should have gone through.
        expect(fakeFirestore.writes, hasLength(1));

        final state = await readRateState();
        expect(state['daily_count'], 24);
        expect(state['violation_count'], 1);
        expect(
          state['blocked_until_ms'],
          closeTo(_t0 + 24 * _hourMs, 1000),
          reason: 'first violation should block for 24 h',
        );
      },
    );

    test('escalates to 72-h block on second violation', () async {
      await setRateState(
        lastSentMs: _t0 - _hourMs - 1,
        dailyCount: 23,
        dailyDate: todayStr(),
        violationCount: 1, // already had one violation
      );
      await queueRawItem();
      await makeFlushService().flushForTesting();

      final state = await readRateState();
      expect(state['violation_count'], 2);
      expect(
        state['blocked_until_ms'],
        closeTo(_t0 + 72 * _hourMs, 1000),
        reason: 'second violation should block for 72 h',
      );
    });

    test('resets daily count when the calendar date changes', () async {
      await setRateState(
        lastSentMs: _t0 - _hourMs - 1,
        dailyCount: 23,
        dailyDate: '2000-01-01', // stale date
      );
      await queueRawItem();
      await makeFlushService().flushForTesting();

      final state = await readRateState();
      expect(state['daily_count'], 1); // reset to 1, not 24
      expect(state['daily_date'], todayStr());
      expect(state['blocked_until_ms'], 0); // no block triggered
    });
  });

  // ─── flush — content dedup ────────────────────────────────────────────────

  group('flush — content dedup', () {
    test('drops item whose hash is already in recentHashes', () async {
      final hash = stableHash('test feedback');
      await setRateState(lastSentMs: _t0 - _hourMs - 1, recentHashes: [hash]);
      await queueRawItem(message: 'test feedback');
      await makeFlushService().flushForTesting();

      // Should not have reached Firestore.
      expect(fakeFirestore.writes, isEmpty);
      // Should also have been removed from the queue (not kept for retry).
      expect(await readQueue(), isEmpty);
    });

    test('sends item whose hash is not in recentHashes', () async {
      final hash = stableHash('old message');
      await setRateState(lastSentMs: _t0 - _hourMs - 1, recentHashes: [hash]);
      await queueRawItem(message: 'new different message');
      await makeFlushService().flushForTesting();

      expect(fakeFirestore.writes, hasLength(1));
    });

    test('adds sent message hash to recentHashes in rate state', () async {
      await queueRawItem(message: 'unique message');
      await makeFlushService().flushForTesting();

      final state = await readRateState();
      final hashes = (state['recent_hashes'] as List).cast<String>();
      expect(hashes, contains(stableHash('unique message')));
    });

    test('dedup is case-insensitive and trims whitespace', () async {
      // Hash stored for lowercase trimmed form.
      final hash = stableHash('test feedback'); // same as '  Test Feedback  '
      await setRateState(lastSentMs: _t0 - _hourMs - 1, recentHashes: [hash]);
      await queueRawItem(message: '  Test Feedback  ');
      await makeFlushService().flushForTesting();

      expect(fakeFirestore.writes, isEmpty);
    });
  });

  // ─── flush — error handling ───────────────────────────────────────────────

  group('flush — error handling', () {
    test('keeps item in queue when Firestore write throws', () async {
      fakeFirestore.shouldThrow = true;
      await queueRawItem();
      await makeFlushService().flushForTesting();

      expect(await readQueue(), hasLength(1));
    });

    test('does not update lastSentMs after Firestore failure', () async {
      fakeFirestore.shouldThrow = true;
      await queueRawItem();
      await makeFlushService().flushForTesting();

      final state = await readRateState();
      // lastSentMs should remain 0 (default), not _t0.
      expect(state['last_sent_ms'] ?? 0, isNot(_t0));
    });

    test('silently drops malformed JSON entries from queue', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_queueKey, ['not-valid-json']);

      await expectLater(makeFlushService().flushForTesting(), completes);
      // Malformed entry is dropped; queue becomes empty.
      expect(await readQueue(), isEmpty);
    });

    test(
      'processes valid entries even when preceded by malformed ones',
      () async {
        final prefs = await SharedPreferences.getInstance();
        // Corrupt first entry followed by a valid one.
        await prefs.setStringList(_queueKey, [
          'not-valid-json',
          jsonEncode({
            'message': 'valid entry',
            'category': 'bug_report',
            'source': 'test',
            'email': null,
            'device_fingerprint': 'test-fp',
            'platform': 'android',
            'app_version': '1.0',
            'build_number': '1',
            'locale': 'en',
            'user_id': 'user-123',
            'created_at_client': '2026-01-01T00:00:00.000',
            'status': 'new',
          }),
        ]);

        await makeFlushService().flushForTesting();

        expect(fakeFirestore.writes, hasLength(1));
        expect(fakeFirestore.writes.first['data']['message'], 'valid entry');
      },
    );
  });

  // ─── rate state persistence ───────────────────────────────────────────────

  group('rate state persistence', () {
    test('rate state from one instance is respected by the next', () async {
      // First flush sets lastSentMs = _t0.
      await queueRawItem(message: 'first');
      await makeFlushService().flushForTesting();
      expect(fakeFirestore.writes, hasLength(1));

      // Advance clock by 30 min — still within the 1-h window.
      fakeNow = _t0 + 30 * 60 * 1000;
      await queueRawItem(message: 'second');
      await makeFlushService().flushForTesting();

      // Second service instance should also be blocked.
      expect(fakeFirestore.writes, hasLength(1));
    });

    test(
      'corrupt rate state is silently discarded and treated as fresh',
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_rateLimitKey, '{not valid json}');

        await queueRawItem();
        // Should not throw; corrupt state is treated as zero/default.
        await expectLater(makeFlushService().flushForTesting(), completes);
        // Flush proceeds as if fresh state (no prior send).
        expect(fakeFirestore.writes, hasLength(1));
      },
    );
  });
}
