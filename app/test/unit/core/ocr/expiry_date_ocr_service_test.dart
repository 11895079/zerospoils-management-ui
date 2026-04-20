import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zerospoils/core/ocr/expiry_date_ocr_service.dart';

class ThrowingImagePicker extends ImagePicker {
  ThrowingImagePicker(this.error);

  final PlatformException error;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    throw error;
  }
}

class ReturningImagePicker extends ImagePicker {
  ReturningImagePicker(this.filePath);

  final String filePath;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    return XFile(filePath);
  }
}

void main() {
  group('MlKitExpiryDateOcrService', () {
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test(
      'maps permission-related PlatformExceptions to permissionDenied',
      () async {
        final service = MlKitExpiryDateOcrService(
          imagePicker: ThrowingImagePicker(
            PlatformException(code: 'camera_access_denied'),
          ),
        );

        final result = await service.scanExpiryDate();

        expect(result.failure, ExpiryDateOcrFailure.permissionDenied);
      },
    );

    test('maps non-permission PlatformExceptions to unknown', () async {
      final service = MlKitExpiryDateOcrService(
        imagePicker: ThrowingImagePicker(
          PlatformException(code: 'camera_unavailable'),
        ),
      );

      final result = await service.scanExpiryDate();

      expect(result.failure, ExpiryDateOcrFailure.unknown);
    });

    test('returns noDateDetected when OCR finds no readable date text', () async {
      final service = MlKitExpiryDateOcrService(
        imagePicker: ReturningImagePicker('/tmp/nonexistent-expiry-image.jpg'),
      );

      final result = await service.scanExpiryDate();

      expect(result.failure, ExpiryDateOcrFailure.noDateDetected);
    });
  });
}
