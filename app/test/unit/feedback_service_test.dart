library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerospoils/core/feedback/audio_feedback_player.dart';
import 'package:zerospoils/core/feedback/feedback_service.dart';

class _RecordingAudioFeedbackPlayer implements AudioFeedbackPlayer {
  final List<double> playedVolumes = <double>[];

  @override
  Future<void> playBeep({required double volume}) async {
    playedVolumes.add(volume);
  }
}

void main() {
  group('FeedbackService', () {
    late FeedbackService feedbackService;
    late _RecordingAudioFeedbackPlayer audioPlayer;

    setUp(() async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      audioPlayer = _RecordingAudioFeedbackPlayer();
      feedbackService = FeedbackService(audioPlayer: audioPlayer);
      await feedbackService.initialize();
    });

    test('preview beep uses slider volume when audio is enabled', () async {
      await feedbackService.setAudioEnabled(true);
      await feedbackService.previewBeepVolume(0.42);

      expect(audioPlayer.playedVolumes, hasLength(1));
      expect(audioPlayer.playedVolumes.single, closeTo(0.42, 0.001));
    });

    test('preview beep is skipped when audio is disabled', () async {
      await feedbackService.setAudioEnabled(false);
      await feedbackService.previewBeepVolume(0.9);

      expect(audioPlayer.playedVolumes, isEmpty);
    });

    test('ocr success beep uses persisted beep volume', () async {
      await feedbackService.setAudioEnabled(true);
      await feedbackService.setHapticEnabled(false);
      await feedbackService.setBeepVolume(0.61);

      await feedbackService.triggerOcrSuccess(FeedbackType.barcodeSuccess);

      expect(audioPlayer.playedVolumes, hasLength(1));
      expect(audioPlayer.playedVolumes.single, closeTo(0.61, 0.001));
    });

    test('initializes with default settings', () {
      expect(feedbackService.hapticEnabled, isTrue);
      expect(feedbackService.audioEnabled, isTrue);
      expect(feedbackService.beepVolume, closeTo(0.6, 0.01));
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
      final newService = FeedbackService(
        audioPlayer: _RecordingAudioFeedbackPlayer(),
      );
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

    test('scanner toggle disables feedback for that scanner only', () async {
      await feedbackService.setScannerEnabled(
        FeedbackType.produceSuccess,
        false,
      );

      // Disabled scanner is reported as such.
      expect(
        feedbackService.scannerEnabled(FeedbackType.produceSuccess),
        isFalse,
      );
      // Other scanner types remain unaffected.
      expect(
        feedbackService.scannerEnabled(FeedbackType.receiptSuccess),
        isTrue,
      );
      expect(
        feedbackService.scannerEnabled(FeedbackType.barcodeSuccess),
        isTrue,
      );
      expect(
        feedbackService.scannerEnabled(FeedbackType.expirySuccess),
        isTrue,
      );

      // Triggering still completes without error (dispatch is skipped
      // internally; verifying the absence of platform calls would require
      // injecting a platform-channel mock, which is out of scope here).
      await feedbackService.triggerOcrSuccess(FeedbackType.produceSuccess);
      await feedbackService.triggerOcrSuccess(FeedbackType.receiptSuccess);
    });

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
