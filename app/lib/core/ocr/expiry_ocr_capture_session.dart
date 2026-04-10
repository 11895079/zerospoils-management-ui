import '../../domain/utils/expiry_date_parser.dart';

class ExpiryOcrDetectionFeedback {
  const ExpiryOcrDetectionFeedback({
    required this.shouldTriggerHaptic,
    required this.shouldAutoCapture,
  });

  final bool shouldTriggerHaptic;
  final bool shouldAutoCapture;
}

class ExpiryOcrCaptureSession {
  ExpiryOcrCaptureSession({
    required this.autoCaptureEnabled,
    this.maxPhotos = 5,
    this.autoCaptureCooldown = const Duration(seconds: 2),
    this.hapticCooldown = const Duration(seconds: 2),
  });

  bool autoCaptureEnabled;
  final int maxPhotos;
  final Duration autoCaptureCooldown;
  final Duration hapticCooldown;

  int photoCount = 0;
  DateTime? _lastAutoCaptureAt;
  DateTime? _lastHapticAt;
  String? _lastDetectionSignature;

  bool get hasReachedPhotoLimit => photoCount >= maxPhotos;

  ExpiryOcrDetectionFeedback registerDetection(
    ExpiryDateParseResult detection, {
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();
    final signature = '${detection.date.toIso8601String()}|${detection.format}';

    final shouldTriggerHaptic =
        signature != _lastDetectionSignature ||
        _lastHapticAt == null ||
        now.difference(_lastHapticAt!) >= hapticCooldown;

    if (shouldTriggerHaptic) {
      _lastDetectionSignature = signature;
      _lastHapticAt = now;
    }

    final shouldAutoCapture =
        autoCaptureEnabled &&
        !hasReachedPhotoLimit &&
        (_lastAutoCaptureAt == null ||
            now.difference(_lastAutoCaptureAt!) >= autoCaptureCooldown);

    if (shouldAutoCapture) {
      _lastAutoCaptureAt = now;
    }

    return ExpiryOcrDetectionFeedback(
      shouldTriggerHaptic: shouldTriggerHaptic,
      shouldAutoCapture: shouldAutoCapture,
    );
  }

  void registerPhotoCaptured() {
    if (!hasReachedPhotoLimit) {
      photoCount += 1;
    }
  }
}
