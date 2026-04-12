import 'package:flutter_test/flutter_test.dart';
import 'package:zerospoils/core/ocr/expiry_ocr_capture_session.dart';
import 'package:zerospoils/domain/utils/expiry_date_parser.dart';

void main() {
  group('ExpiryOcrCaptureSession', () {
    final detection = ExpiryDateParseResult(
      date: DateTime(2026, 3, 18),
      format: 'MM/DD/YYYY',
    );

    test('does not auto capture when auto capture is disabled', () {
      final session = ExpiryOcrCaptureSession(autoCaptureEnabled: false);

      final feedback = session.registerDetection(
        detection,
        timestamp: DateTime(2026, 1, 1, 12),
      );

      expect(feedback.shouldTriggerHaptic, isTrue);
      expect(feedback.shouldAutoCapture, isFalse);
    });

    test('auto capture is capped at five photos', () {
      final session = ExpiryOcrCaptureSession(autoCaptureEnabled: true);
      final start = DateTime(2026, 1, 1, 12);

      for (var index = 0; index < 5; index++) {
        final feedback = session.registerDetection(
          detection,
          timestamp: start.add(Duration(seconds: index * 3)),
        );
        expect(feedback.shouldAutoCapture, isTrue);
        session.registerPhotoCaptured();
      }

      final overflowFeedback = session.registerDetection(
        detection,
        timestamp: start.add(const Duration(seconds: 18)),
      );

      expect(session.photoCount, 5);
      expect(overflowFeedback.shouldAutoCapture, isFalse);
    });

    test('debounces repeated haptic feedback for unchanged detection', () {
      final session = ExpiryOcrCaptureSession(autoCaptureEnabled: true);
      final start = DateTime(2026, 1, 1, 12);

      final first = session.registerDetection(detection, timestamp: start);
      final second = session.registerDetection(
        detection,
        timestamp: start.add(const Duration(milliseconds: 500)),
      );

      expect(first.shouldTriggerHaptic, isTrue);
      expect(second.shouldTriggerHaptic, isFalse);
    });
  });
}
