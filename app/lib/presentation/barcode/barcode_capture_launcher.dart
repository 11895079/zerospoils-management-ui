import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/barcode/local_barcode_catalog.dart';
import '../../domain/models/item_model.dart';
import '../di/repository_providers.dart';

enum BarcodeCaptureFailure { cancelled, invalidBarcode }

class BarcodeCaptureResult {
  const BarcodeCaptureResult.success({
    required this.rawValue,
    this.suggestedName,
    this.suggestedCategory,
    this.source,
  }) : failure = null;

  const BarcodeCaptureResult.failure(this.failure)
    : rawValue = null,
      suggestedName = null,
      suggestedCategory = null,
      source = null;

  final String? rawValue;
  final String? suggestedName;
  final ItemCategory? suggestedCategory;
  final String? source;
  final BarcodeCaptureFailure? failure;

  bool get isSuccess => rawValue != null;
}

typedef BarcodeCaptureLauncher =
    Future<BarcodeCaptureResult> Function({required BuildContext context});

final barcodeCaptureLauncherProvider = Provider<BarcodeCaptureLauncher>((ref) {
  final learnedMappingStore = ref.read(learnedBarcodeMappingStoreProvider);

  return ({required BuildContext context}) async {
    final controller = TextEditingController();

    try {
      final rawValue = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          key: const Key('barcode_capture_dialog'),
          title: const Text('Enter barcode'),
          content: TextField(
            key: const Key('barcode_capture_text_field'),
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'UPC, EAN, or GTIN',
              helperText: 'Use 8 to 14 digits. Camera scanning lands next.',
            ),
          ),
          actions: [
            TextButton(
              key: const Key('barcode_capture_cancel_button'),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('barcode_capture_confirm_button'),
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: const Text('Use barcode'),
            ),
          ],
        ),
      );

      if (rawValue == null) {
        return const BarcodeCaptureResult.failure(
          BarcodeCaptureFailure.cancelled,
        );
      }

      final normalized = normalizeBarcodeValue(rawValue);
      if (normalized == null) {
        return const BarcodeCaptureResult.failure(
          BarcodeCaptureFailure.invalidBarcode,
        );
      }

      final learnedSuggestion = await learnedMappingStore.getSuggestion(
        normalized,
      );
      final suggestion =
          learnedSuggestion ?? lookupBarcodeSuggestion(normalized);
      return BarcodeCaptureResult.success(
        rawValue: normalized,
        suggestedName: suggestion?.name,
        suggestedCategory: suggestion?.category,
        source: suggestion?.source ?? 'manual_entry',
      );
    } finally {
      controller.dispose();
    }
  };
});
