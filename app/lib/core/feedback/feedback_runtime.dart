library;

import 'dart:async';

import 'feedback_service.dart';

/// Lightweight runtime accessor that lazily initializes a single feedback
/// service instance for screens that are not wired through Riverpod.
class FeedbackRuntime {
  static FeedbackService? _service;
  static Future<FeedbackService>? _initializing;

  static Future<FeedbackService> _getService() {
    if (_service != null) {
      return Future.value(_service);
    }

    final inFlight = _initializing;
    if (inFlight != null) {
      return inFlight;
    }

    _initializing = () async {
      final service = FeedbackService();
      await service.initialize();
      _service = service;
      return service;
    }();

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
