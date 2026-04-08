import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ocr/expiry_date_ocr_service.dart';
import '../screens/expiry_ocr_capture_screen.dart';

typedef ExpiryOcrCaptureLauncher =
    Future<ExpiryDateOcrScanResult> Function({
      required BuildContext context,
      required String preferredDateFormat,
    });

final expiryOcrCaptureLauncherProvider = Provider<ExpiryOcrCaptureLauncher>((
  ref,
) {
  return ({
    required BuildContext context,
    required String preferredDateFormat,
  }) async {
    final result = await Navigator.of(context).push<ExpiryDateOcrScanResult>(
      MaterialPageRoute(
        builder: (_) =>
            ExpiryOcrCaptureScreen(preferredDateFormat: preferredDateFormat),
        fullscreenDialog: true,
      ),
    );

    return result ??
        const ExpiryDateOcrScanResult.failure(ExpiryDateOcrFailure.cancelled);
  };
});
