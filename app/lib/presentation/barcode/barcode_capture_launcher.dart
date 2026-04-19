import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/barcode/local_barcode_catalog.dart';
import '../../domain/models/item_model.dart';
import '../di/repository_providers.dart';
import '../screens/barcode_capture_screen.dart';

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
    final rawValue = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const BarcodeCaptureScreen(),
        fullscreenDialog: true,
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
    final catalog = await ref.read(localBarcodeCatalogProvider.future);
    var suggestion = learnedSuggestion ?? catalog.lookup(normalized);

    // Real-time fallback: resolve against OpenFoodFacts when local lookup misses.
    if (suggestion == null) {
      final offClient = ref.read(openFoodFactsClientProvider);
      final remote = await offClient.lookup(normalized);
      if (remote != null) {
        // Cache the result locally so future scans of the same barcode are instant.
        await learnedMappingStore.saveMapping(
          rawValue: normalized,
          name: remote.name,
          category: remote.category,
        );
        suggestion = remote;
      }
    }

    return BarcodeCaptureResult.success(
      rawValue: normalized,
      suggestedName: suggestion?.name,
      suggestedCategory: suggestion?.category,
      source: suggestion?.source ?? 'camera_scan',
    );
  };
});
