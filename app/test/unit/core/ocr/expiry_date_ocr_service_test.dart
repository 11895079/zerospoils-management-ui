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
  });
}
