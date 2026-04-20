import 'dart:convert';
import 'dart:io';

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
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  group('MlKitExpiryDateOcrService', () {
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      tempDir = Directory.systemTemp.createTempSync('expiry_ocr_test_');
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
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
      final imageFile = File('${tempDir.path}/blank.png')
        ..writeAsBytesSync(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAoMBgA6j4z8AAAAASUVORK5CYII=',
          ),
        );

      final service = MlKitExpiryDateOcrService(
        imagePicker: ReturningImagePicker(imageFile.path),
      );

      final result = await service.scanExpiryDate();

      expect(
        result.failure,
        anyOf(
          ExpiryDateOcrFailure.noDateDetected,
          ExpiryDateOcrFailure.unknown,
        ),
      );
    });
  });
}
