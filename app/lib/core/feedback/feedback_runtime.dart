library;

import 'dart:async';

import 'feedback_service.dart';

/// Lightweight runtime accessor that lazily initializes a single feedback
/// service instance for screens that are not wired through Riverpod.
class FeedbackRuntime {
  static FeedbackService? _service;
  static Future<FeedbackService>? _initializing;

  static Future<FeedbackService> _initializeService() async {
    final service = FeedbackService();
    await service.initialize();
    _service = service;
    _initializing = null;
    return service;
  }

  static Future<FeedbackService> _getService() {
    if (_service != null) {
      return Future.value(_service);
    }

    final inFlight = _initializing;
    if (inFlight != null) {
      return inFlight;
    }

    _initializing = _initializeService();

    // If initialization fails, clear the in-flight future so later calls can retry.
    _initializing = _initializing!.catchError((Object error, StackTrace stack) {
      _initializing = null;
      throw error;
    });

    return _initializing!;
  }

  static Future<void> triggerOcrSuccess(FeedbackType type) async {
    try {
      final service = await _getService();
      await service.triggerOcrSuccess(type);
    } catch (_) {
      // Non-blocking by design; ignore feedback failures.
    }
  }

  static Future<void> triggerSelection() async {
    try {
      final service = await _getService();
      await service.triggerSelection();
    } catch (_) {
      // Non-blocking by design; ignore feedback failures.
    }
  }
}
