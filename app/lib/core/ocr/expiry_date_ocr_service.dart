import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/utils/expiry_date_parser.dart';

enum ExpiryDateOcrFailure {
  cancelled,
  permissionDenied,
  noDateDetected,
  unavailable,
  unknown,
}

class ExpiryDateOcrScanResult {
  const ExpiryDateOcrScanResult._({this.parsed, this.failure});

  const ExpiryDateOcrScanResult.success(ExpiryDateParseResult parsed)
    : this._(parsed: parsed);

  const ExpiryDateOcrScanResult.failure(ExpiryDateOcrFailure failure)
    : this._(failure: failure);

  final ExpiryDateParseResult? parsed;
  final ExpiryDateOcrFailure? failure;

  bool get isSuccess => parsed != null;
}

abstract class ExpiryDateOcrService {
  Future<ExpiryDateOcrScanResult> scanExpiryDate({
    String preferredDateFormat = 'MM/DD/YYYY',
  });
}

final expiryDateOcrServiceProvider = Provider<ExpiryDateOcrService>((ref) {
  return MlKitExpiryDateOcrService();
});

class MlKitExpiryDateOcrService implements ExpiryDateOcrService {
  MlKitExpiryDateOcrService({
    ImagePicker? imagePicker,
    ExpiryDateParser? parser,
  }) : _imagePicker = imagePicker ?? ImagePicker(),
       _parser = parser ?? const ExpiryDateParser();

  final ImagePicker _imagePicker;
  final ExpiryDateParser _parser;

  bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<ExpiryDateOcrScanResult> scanExpiryDate({
    String preferredDateFormat = 'MM/DD/YYYY',
  }) async {
    if (!_isSupportedPlatform) {
      return const ExpiryDateOcrScanResult.failure(
        ExpiryDateOcrFailure.unavailable,
      );
    }

    TextRecognizer? textRecognizer;
    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (photo == null) {
        return const ExpiryDateOcrScanResult.failure(
          ExpiryDateOcrFailure.cancelled,
        );
      }

      textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final input = InputImage.fromFilePath(photo.path);
      final result = await textRecognizer.processImage(input);

      final parsed = _parser.parse(
        result.text,
        preferredDateFormat: preferredDateFormat,
      );
      if (parsed == null) {
        return const ExpiryDateOcrScanResult.failure(
          ExpiryDateOcrFailure.noDateDetected,
        );
      }

      return ExpiryDateOcrScanResult.success(parsed);
    } on PlatformException catch (error) {
      if (_isPermissionDenied(error)) {
        return const ExpiryDateOcrScanResult.failure(
          ExpiryDateOcrFailure.permissionDenied,
        );
      }

      return const ExpiryDateOcrScanResult.failure(
        ExpiryDateOcrFailure.unknown,
      );
    } catch (_) {
      return const ExpiryDateOcrScanResult.failure(
        ExpiryDateOcrFailure.unknown,
      );
    } finally {
      await textRecognizer?.close();
    }
  }

  bool _isPermissionDenied(PlatformException error) {
    final code = error.code.toLowerCase();
    final message = (error.message ?? '').toLowerCase();

    return code.contains('permission') ||
        code.contains('denied') ||
        message.contains('permission') ||
        message.contains('denied');
  }
}
