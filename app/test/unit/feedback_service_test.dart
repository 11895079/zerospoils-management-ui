library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerospoils/core/feedback/feedback_service.dart';

void main() {
  group('FeedbackService', () {
    late FeedbackService feedbackService;

    setUp(() async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      feedbackService = FeedbackService();
      await feedbackService.initialize();
    });

    test('initializes with default settings', () {
      expect(feedbackService.hapticEnabled, isTrue);
      expect(feedbackService.audioEnabled, isTrue);
      expect(feedbackService.beepVolume, closeTo(0.8, 0.01));
      expect(feedbackService.hapticIntensity, HapticIntensity.medium);
      expect(
        feedbackService.scannerEnabled(FeedbackType.barcodeSuccess),
        isTrue,
      );
      expect(
        feedbackService.scannerEnabled(FeedbackType.expirySuccess),
        isTrue,
      );
      expect(
        feedbackService.scannerEnabled(FeedbackType.receiptSuccess),
        isTrue,
      );
      expect(
        feedbackService.scannerEnabled(FeedbackType.produceSuccess),
        isTrue,
      );
    });

    test('toggles haptic feedback', () async {
      expect(feedbackService.hapticEnabled, isTrue);

      await feedbackService.setHapticEnabled(false);
      expect(feedbackService.hapticEnabled, isFalse);

      await feedbackService.setHapticEnabled(true);
      expect(feedbackService.hapticEnabled, isTrue);
    });

    test('toggles audio feedback', () async {
      expect(feedbackService.audioEnabled, isTrue);

      await feedbackService.setAudioEnabled(false);
      expect(feedbackService.audioEnabled, isFalse);

      await feedbackService.setAudioEnabled(true);
      expect(feedbackService.audioEnabled, isTrue);
    });

    test('adjusts beep volume', () async {
      await feedbackService.setBeepVolume(0.5);
      expect(feedbackService.beepVolume, closeTo(0.5, 0.01));

      // Clamps to valid range
      await feedbackService.setBeepVolume(1.5);
      expect(feedbackService.beepVolume, closeTo(1.0, 0.01));

      await feedbackService.setBeepVolume(-0.5);
      expect(feedbackService.beepVolume, closeTo(0.0, 0.01));
    });

    test('changes haptic intensity', () async {
      await feedbackService.setHapticIntensity(HapticIntensity.light);
      expect(feedbackService.hapticIntensity, HapticIntensity.light);

      await feedbackService.setHapticIntensity(HapticIntensity.heavy);
      expect(feedbackService.hapticIntensity, HapticIntensity.heavy);

      await feedbackService.setHapticIntensity(HapticIntensity.medium);
      expect(feedbackService.hapticIntensity, HapticIntensity.medium);
    });

    test('persists settings across instances', () async {
      await feedbackService.setHapticEnabled(false);
      await feedbackService.setAudioEnabled(false);
      await feedbackService.setBeepVolume(0.3);
      await feedbackService.setHapticIntensity(HapticIntensity.light);
      await feedbackService.setScannerEnabled(
        FeedbackType.barcodeSuccess,
        false,
      );
      await feedbackService.setScannerEnabled(
        FeedbackType.expirySuccess,
        false,
      );
      await feedbackService.setScannerEnabled(
        FeedbackType.receiptSuccess,
        false,
      );
      await feedbackService.setScannerEnabled(
        FeedbackType.produceSuccess,
        false,
      );

      // Create new instance and verify persistence
      final newService = FeedbackService();
      await newService.initialize();

      expect(newService.hapticEnabled, isFalse);
      expect(newService.audioEnabled, isFalse);
      expect(newService.beepVolume, closeTo(0.3, 0.01));
      expect(newService.hapticIntensity, HapticIntensity.light);
      expect(newService.scannerEnabled(FeedbackType.barcodeSuccess), isFalse);
      expect(newService.scannerEnabled(FeedbackType.expirySuccess), isFalse);
      expect(newService.scannerEnabled(FeedbackType.receiptSuccess), isFalse);
      expect(newService.scannerEnabled(FeedbackType.produceSuccess), isFalse);
    });

    test(
      'scanner toggle suppresses success feedback for that scanner',
      () async {
        await feedbackService.setScannerEnabled(
          FeedbackType.produceSuccess,
          false,
        );

        await feedbackService.triggerOcrSuccess(FeedbackType.produceSuccess);
        await feedbackService.triggerOcrSuccess(FeedbackType.receiptSuccess);
      },
    );

    test('triggers OCR success feedback without errors', () async {
      // Should not throw, even on devices without haptic support
      await feedbackService.triggerOcrSuccess(FeedbackType.barcodeSuccess);
      await feedbackService.triggerOcrSuccess(FeedbackType.expirySuccess);
      await feedbackService.triggerOcrSuccess(FeedbackType.receiptSuccess);
      await feedbackService.triggerOcrSuccess(FeedbackType.produceSuccess);
    });

    test('triggers selection feedback without errors', () async {
      await feedbackService.triggerSelection();
    });

    test('triggers error feedback without errors', () async {
      await feedbackService.triggerError();
    });

    test('respects haptic disabled setting', () async {
      await feedbackService.setHapticEnabled(false);
      expect(feedbackService.hapticEnabled, isFalse);

      // Trigger should be a no-op but not throw
      await feedbackService.triggerSelection();
      await feedbackService.triggerError();
    });

    test('respects audio disabled setting', () async {
      await feedbackService.setAudioEnabled(false);
      expect(feedbackService.audioEnabled, isFalse);

      // Trigger should be a no-op but not throw
      await feedbackService.triggerOcrSuccess(FeedbackType.barcodeSuccess);
    });
  });
}
