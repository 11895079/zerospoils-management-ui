library;

import 'package:flutter_test/flutter_test.dart';
import 'package:zerospoils/core/distribution/app_distribution_service.dart';

// ---------------------------------------------------------------------------
// Fake client for unit testing — no real Firebase
// ---------------------------------------------------------------------------

class _FakeClient implements AppDistributionClient {
  _FakeClient({
    this.hasUpdate = false,
    this.isSignedIn = true,
    this.isNewReleaseError,
    this.isTesterSignedInError,
    this.checkDelay = Duration.zero,
  });

  final bool hasUpdate;
  final bool isSignedIn;
  final Object? isNewReleaseError;
  final Object? isTesterSignedInError;
  final Duration checkDelay;

  int isNewReleaseCalls = 0;
  int updateIfNewReleaseCalls = 0;
  int isTesterSignedInCalls = 0;

  @override
  Future<bool> isNewReleaseAvailable() async {
    isNewReleaseCalls++;
    if (checkDelay > Duration.zero) {
      await Future<void>.delayed(checkDelay);
    }
    if (isNewReleaseError != null) throw isNewReleaseError!;
    return hasUpdate;
  }

  @override
  Future<void> updateIfNewReleaseAvailable() async {
    updateIfNewReleaseCalls++;
  }

  @override
  Future<bool> isTesterSignedIn() async {
    isTesterSignedInCalls++;
    if (isTesterSignedInError != null) throw isTesterSignedInError!;
    return isSignedIn;
  }
}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

AppDistributionService _serviceWith(_FakeClient client) {
  final service = AppDistributionService.instance;
  service.client = client;
  return service;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('AppDistributionService.checkForUpdate()', () {
    test('returns false when no update is available', () async {
      final client = _FakeClient(hasUpdate: false);
      final service = _serviceWith(client);

      final result = await service.checkForUpdate();

      expect(result, isFalse);
      expect(client.isNewReleaseCalls, 1);
      expect(client.updateIfNewReleaseCalls, 0);
    });

    test('returns true and calls update prompt when update is available',
        () async {
      final client = _FakeClient(hasUpdate: true);
      final service = _serviceWith(client);

      final result = await service.checkForUpdate();

      expect(result, isTrue);
      expect(client.updateIfNewReleaseCalls, 1);
    });

    test('swallows Exception and returns false when network fails', () async {
      final client = _FakeClient(
        isNewReleaseError: Exception('SocketException: no route to host'),
      );
      final service = _serviceWith(client);

      final result = await service.checkForUpdate();

      expect(result, isFalse, reason: 'should return false on network error');
    });

    test('returns false when call times out (>10 s)', () async {
      // 15-second delay exceeds the service's 10-second timeout.
      final client = _FakeClient(checkDelay: const Duration(seconds: 15));
      final service = _serviceWith(client);

      // The service applies a 10 s timeout internally; use a 12 s outer
      // timeout to avoid the test hanging indefinitely.
      final result = await service
          .checkForUpdate()
          .timeout(const Duration(seconds: 12));

      expect(result, isFalse, reason: 'timeout should be handled gracefully');
    });
  });

  group('AppDistributionService.isTesterSignedIn()', () {
    test('returns true when tester is signed in', () async {
      final client = _FakeClient(isSignedIn: true);
      final service = _serviceWith(client);

      final result = await service.isTesterSignedIn();

      expect(result, isTrue);
    });

    test('returns false and does not throw when check fails', () async {
      final client = _FakeClient(
        isTesterSignedInError: Exception('Firebase unavailable'),
      );
      final service = _serviceWith(client);

      final result = await service.isTesterSignedIn();

      expect(result, isFalse);
    });
  });

  group('AppDistributionService.initialize()', () {
    test('calls checkForUpdate on active build', () async {
      final client = _FakeClient(hasUpdate: false);
      final service = _serviceWith(client);

      // In tests kDebugMode is true, so _isActive = true and checkForUpdate
      // is called.
      await service.initialize();

      expect(client.isNewReleaseCalls, greaterThanOrEqualTo(1));
    });

    test('does not throw when checkForUpdate fails', () async {
      final client = _FakeClient(
        isNewReleaseError: Exception('network unavailable'),
      );
      final service = _serviceWith(client);

      // initialize() swallows errors so app startup is never blocked.
      await expectLater(service.initialize(), completes);
    });
  });
}

