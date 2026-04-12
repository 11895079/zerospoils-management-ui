import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/vision/fresh_item_cv_service.dart';

enum FreshItemCaptureFailure { cancelled, noItemDetected, unavailable, unknown }

class FreshItemCaptureResult {
  const FreshItemCaptureResult.success({
    required this.primarySuggestion,
    required this.suggestions,
    required this.labels,
  }) : failure = null;

  const FreshItemCaptureResult.failure(this.failure)
    : primarySuggestion = null,
      suggestions = const [],
      labels = const [];

  final FreshItemCvSuggestion? primarySuggestion;
  final List<FreshItemCvSuggestion> suggestions;
  final List<FreshItemCvLabel> labels;
  final FreshItemCaptureFailure? failure;

  bool get isSuccess => primarySuggestion != null;
}

typedef FreshItemCaptureLauncher =
    Future<FreshItemCaptureResult> Function({required BuildContext context});

final freshItemCaptureLauncherProvider = Provider<FreshItemCaptureLauncher>((
  ref,
) {
  final service = ref.read(freshItemCvServiceProvider);
  final picker = ImagePicker();

  return ({required BuildContext context}) async {
    try {
      final image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (image == null) {
        return const FreshItemCaptureResult.failure(
          FreshItemCaptureFailure.cancelled,
        );
      }

      final analysis = await service.analyzeImage(image.path);
      if (analysis.suggestions.isEmpty) {
        return const FreshItemCaptureResult.failure(
          FreshItemCaptureFailure.noItemDetected,
        );
      }

      return FreshItemCaptureResult.success(
        primarySuggestion: analysis.suggestions.first,
        suggestions: analysis.suggestions,
        labels: analysis.labels,
      );
    } on UnsupportedError {
      return const FreshItemCaptureResult.failure(
        FreshItemCaptureFailure.unavailable,
      );
    } catch (_) {
      return const FreshItemCaptureResult.failure(
        FreshItemCaptureFailure.unknown,
      );
    }
  };
});
