library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/barcode/local_barcode_catalog.dart';
import '../../core/ocr/expiry_date_ocr_service.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/models/item_model.dart';
import '../../domain/utils/expiry_date_parser.dart';
import '../../domain/utils/fresh_produce_ocr_parser.dart';
import '../di/repository_providers.dart';

/// Result returned when the fast-add flow completes or is cancelled.
class PackagedItemFastAddResult {
  const PackagedItemFastAddResult._({
    this.name,
    this.category,
    this.expiryDate,
    this.rawBarcode,
    this.purchasePrice,
    this.packageWeightValue,
    this.packageWeightUnit,
    this.failure,
  });

  const PackagedItemFastAddResult.success({
    required String name,
    required ItemCategory category,
    DateTime? expiryDate,
    String? rawBarcode,
    double? purchasePrice,
    double? packageWeightValue,
    Unit? packageWeightUnit,
  }) : this._(
         name: name,
         category: category,
         expiryDate: expiryDate,
         rawBarcode: rawBarcode,
         purchasePrice: purchasePrice,
         packageWeightValue: packageWeightValue,
         packageWeightUnit: packageWeightUnit,
       );

  const PackagedItemFastAddResult.cancelled()
    : this._(failure: PackagedItemFastAddFailure.cancelled);

  final String? name;
  final ItemCategory? category;
  final DateTime? expiryDate;
  final String? rawBarcode;
  final double? purchasePrice;
  final double? packageWeightValue;
  final Unit? packageWeightUnit;
  final PackagedItemFastAddFailure? failure;

  bool get isSuccess => name != null;
}

enum PackagedItemFastAddFailure { cancelled }

/// Internal stage of the fast-add camera panel.
enum _FastAddStage {
  /// Scanning for a barcode.
  barcodeScanning,

  /// Barcode detected; showing inline product result before expiry step.
  barcodeResult,

  /// No barcode found; compact manual entry.
  barcodeMiss,

  /// Scanning package label for random-weight meat/seafood items.
  packageLabelScan,

  /// Capturing expiry date from the package.
  expiryCapture,

  /// Expiry locked; ready for the compact confirmation step.
  expiryLocked,

  /// Showing compact confirmation sheet before final save.
  editConfirm,
}

bool get _isMobile =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

class PackagedItemFastAddScreen extends ConsumerStatefulWidget {
  const PackagedItemFastAddScreen({super.key});

  @override
  ConsumerState<PackagedItemFastAddScreen> createState() =>
      _PackagedItemFastAddScreenState();
}

class _PackagedItemFastAddScreenState
    extends ConsumerState<PackagedItemFastAddScreen> {
  static const FreshProduceOcrParser _freshProduceParser =
      FreshProduceOcrParser();

  _FastAddStage _stage = _FastAddStage.barcodeScanning;

  // Barcode state
  String? _rawBarcode;
  BarcodeProductSuggestion? _suggestion;
  bool _barcodeIsCompleting = false;

  // Expiry state
  ExpiryDateParseResult? _lockedExpiry;

  // Confirmation form state
  late TextEditingController _nameController;
  late TextEditingController _packageLabelTextController;
  ItemCategory _selectedCategory = ItemCategory.other;
  double? _detectedPurchasePrice;
  double? _detectedWeightValue;
  Unit? _detectedWeightUnit;

  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _packageLabelTextController = TextEditingController();
    if (_isMobile) {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        formats: const [
          BarcodeFormat.ean13,
          BarcodeFormat.ean8,
          BarcodeFormat.upcA,
          BarcodeFormat.upcE,
          BarcodeFormat.code128,
          BarcodeFormat.code39,
        ],
      );
    }
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    _nameController.dispose();
    _packageLabelTextController.dispose();
    super.dispose();
  }

  // ─────────────────────────────── Barcode Stage ────────────────────────────

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_barcodeIsCompleting || _stage != _FastAddStage.barcodeScanning) {
      return;
    }

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue?.trim() ?? barcode.displayValue?.trim();
      if (rawValue == null || rawValue.isEmpty) {
        continue;
      }

      _barcodeIsCompleting = true;
      await _scannerController?.stop();
      if (!mounted) {
        return;
      }
      await _resolveBarcodeAndAdvance(rawValue);
      return;
    }
  }

  Future<void> _resolveBarcodeAndAdvance(String rawValue) async {
    final normalized = normalizeBarcodeValue(rawValue);
    if (normalized == null) {
      _showSnack(
        'Barcode format not supported. Please enter item details manually.',
      );
      setState(() => _stage = _FastAddStage.barcodeMiss);
      return;
    }

    final learnedStore = ref.read(learnedBarcodeMappingStoreProvider);
    final learnedSuggestion = await learnedStore.getSuggestion(normalized);
    final suggestion = learnedSuggestion ?? lookupBarcodeSuggestion(normalized);

    if (!mounted) {
      return;
    }

    setState(() {
      _rawBarcode = normalized;
      _suggestion = suggestion;
      if (suggestion != null) {
        _nameController.text = suggestion.name;
        _selectedCategory = suggestion.category;
        _stage = _FastAddStage.barcodeResult;
      } else {
        _stage = _FastAddStage.barcodeMiss;
      }
    });
  }

  void _skipToExpiry() {
    setState(() {
      _stage = _lockedExpiry == null
          ? _FastAddStage.expiryCapture
          : _FastAddStage.expiryLocked;
    });
  }

  void _usePackageLabelScan() {
    setState(() => _stage = _FastAddStage.packageLabelScan);
  }

  void _extractPackageLabelHints() {
    final rawText = _packageLabelTextController.text.trim();
    if (rawText.isEmpty) {
      _showSnack('Add package label text first, then extract hints.');
      return;
    }

    final parsed = _freshProduceParser.parseLabel(
      rawText,
      hasBarcodeDetected: _rawBarcode != null,
    );

    if (parsed.productDescription != null) {
      _nameController.text = parsed.productDescription!;
    }

    setState(() {
      _detectedPurchasePrice = parsed.totalPrice;
      _detectedWeightValue = parsed.netWeightValue;
      _detectedWeightUnit = parsed.netWeightUnit;

      if (parsed.classification != FreshProduceClassification.other) {
        _selectedCategory = parsed.suggestedCategory;
      }

      if (parsed.bestBeforeDate != null) {
        _lockedExpiry = ExpiryDateParseResult(
          date: parsed.bestBeforeDate!,
          format: 'PACKAGE_LABEL',
        );
      }
    });

    if (parsed.shouldFallbackToGenericOcr) {
      _showSnack(
        'Could only extract partial label hints. Review before saving.',
      );
    } else {
      _showSnack('Package label hints applied. Review and continue.');
    }
  }

  void _retryBarcodeScanning() {
    _barcodeIsCompleting = false;
    _scannerController?.start();
    setState(() {
      _rawBarcode = null;
      _suggestion = null;
      _stage = _FastAddStage.barcodeScanning;
    });
  }

  // ─────────────────────────────── Expiry Stage ─────────────────────────────

  Future<void> _captureExpiryManually() async {
    final ocrService = MlKitExpiryDateOcrService();
    final result = await ocrService.scanExpiryDate();
    if (!mounted) {
      return;
    }

    if (result.isSuccess) {
      setState(() {
        _lockedExpiry = result.parsed;
        _stage = _FastAddStage.expiryLocked;
      });
    } else {
      _advanceToConfirm();
    }
  }

  void _advanceToConfirm() {
    setState(() => _stage = _FastAddStage.editConfirm);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ─────────────────────────────── Confirm Stage ────────────────────────────

  Future<void> _saveItem() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }

    // Persist learned barcode mapping if we have a new/updated entry.
    final barcode = _rawBarcode;
    if (barcode != null) {
      final learnedStore = ref.read(learnedBarcodeMappingStoreProvider);
      await learnedStore.saveMapping(
        rawValue: barcode,
        name: name,
        category: _selectedCategory,
      );
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(
      PackagedItemFastAddResult.success(
        name: name,
        category: _selectedCategory,
        expiryDate: _lockedExpiry?.date,
        rawBarcode: barcode,
        purchasePrice: _detectedPurchasePrice,
        packageWeightValue: _detectedWeightValue,
        packageWeightUnit: _detectedWeightUnit,
      ),
    );
  }

  // ──────────────────────────────────── UI ──────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Packaged Item'),
        actions: [
          if (_stage == _FastAddStage.barcodeScanning)
            TextButton(
              key: const Key('fast_add_skip_barcode'),
              onPressed: _skipToExpiry,
              child: const Text('Skip Barcode'),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStageIndicator(theme),
            const SizedBox(height: AppSpacing.sm),
            _buildStageContent(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStageIndicator(ThemeData theme) {
    final stageLabel = switch (_stage) {
      _FastAddStage.barcodeScanning => 'Step 1 of 3 — Scan barcode',
      _FastAddStage.barcodeResult => 'Step 1 of 3 — Product found',
      _FastAddStage.barcodeMiss => 'Step 1 of 3 — Barcode not found',
      _FastAddStage.packageLabelScan => 'Step 1 of 3 — Scanning package label',
      _FastAddStage.expiryCapture => 'Step 2 of 3 — Scan expiry date',
      _FastAddStage.expiryLocked => 'Step 2 of 3 — Expiry locked',
      _FastAddStage.editConfirm => 'Step 3 of 3 — Confirm item',
    };

    return Text(
      stageLabel,
      key: const Key('fast_add_stage_label'),
      style: AppTextStyles.bodySmall.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildStageContent(ThemeData theme) {
    return switch (_stage) {
      _FastAddStage.barcodeScanning => _buildBarcodeScanStage(theme),
      _FastAddStage.barcodeResult => _buildBarcodeResultStage(theme),
      _FastAddStage.barcodeMiss => _buildBarcodeMissStage(theme),
      _FastAddStage.packageLabelScan => _buildPackageLabelStage(theme),
      _FastAddStage.expiryCapture => _buildExpiryCaptureStage(theme),
      _FastAddStage.expiryLocked => _buildExpiryLockedStage(theme),
      _FastAddStage.editConfirm => _buildConfirmStage(theme),
    };
  }

  // ── Barcode scanning stage ──────────────────────────────────────────────

  Widget _buildBarcodeScanStage(ThemeData theme) {
    final scanner = _scannerController;
    return Expanded(
      child: Column(
        children: [
          Container(
            key: const Key('fast_add_status_card'),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                const Icon(Icons.qr_code_scanner_outlined, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Point the camera at the product barcode (UPC / EAN).',
                    style: AppTextStyles.body,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (!_isMobile)
            Expanded(
              child: Center(
                child: Text(
                  'Barcode scanning is only available on a real device.',
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else if (scanner != null)
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                child: MobileScanner(
                  controller: scanner,
                  onDetect: _onBarcodeDetected,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('fast_add_package_label_button'),
                  onPressed: _usePackageLabelScan,
                  child: const Text('Scan Package Label'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton(
                  key: const Key('fast_add_no_barcode_button'),
                  onPressed: _skipToExpiry,
                  child: const Text('No Barcode'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              key: const Key('fast_add_initial_cancel_button'),
              onPressed: () => Navigator.of(
                context,
              ).pop(const PackagedItemFastAddResult.cancelled()),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Barcode result stage ────────────────────────────────────────────────

  Widget _buildBarcodeResultStage(ThemeData theme) {
    final suggestion = _suggestion;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            key: const Key('fast_add_barcode_result_card'),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion != null
                            ? suggestion.name
                            : 'Unknown product',
                        key: const Key('fast_add_product_name'),
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (suggestion != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${suggestion.category.displayName} · via ${suggestion.source}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Product details found for barcode ${_rawBarcode ?? ''}.',
            style: AppTextStyles.bodySmall.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('fast_add_continue_to_expiry'),
              onPressed: _skipToExpiry,
              icon: const Icon(Icons.event_outlined),
              label: const Text('Continue to Expiry Scan'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: const Key('fast_add_skip_expiry_to_confirm'),
              onPressed: _advanceToConfirm,
              child: const Text('Skip Expiry — Confirm Item'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _retryBarcodeScanning,
              child: const Text('Scan a Different Barcode'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Barcode miss stage ───────────────────────────────────────────────────

  Widget _buildBarcodeMissStage(ThemeData theme) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            key: const Key('fast_add_barcode_miss_card'),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_off_outlined, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Product not found for this barcode.\nEnter the item name below.',
                    style: AppTextStyles.body,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            key: const Key('fast_add_name_field'),
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Item name',
              hintText: 'e.g. Almond Milk',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            onSubmitted: (_) => _skipToExpiry(),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildCategoryDropdown(theme),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('fast_add_miss_continue_expiry'),
              onPressed: () {
                FocusScope.of(context).unfocus();
                _skipToExpiry();
              },
              icon: const Icon(Icons.event_outlined),
              label: const Text('Continue to Expiry Scan'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: const Key('fast_add_miss_skip_expiry'),
              onPressed: () {
                FocusScope.of(context).unfocus();
                _advanceToConfirm();
              },
              child: const Text('Skip Expiry — Confirm Item'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _retryBarcodeScanning,
              child: const Text('Try Barcode Again'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Package label stage (meat / seafood random-weight labels) ────────────

  Widget _buildPackageLabelStage(ThemeData theme) {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              key: const Key('fast_add_package_label_card'),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  const Icon(Icons.document_scanner_outlined, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Point the camera at the service-counter label to extract name, weight, and price hints.',
                      style: AppTextStyles.body,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Tap the fields below to correct any OCR hints before continuing.',
              style: AppTextStyles.bodySmall.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('fast_add_package_name_field'),
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Product name',
                hintText: 'e.g. Salmon Fillet',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('fast_add_package_label_text_field'),
              controller: _packageLabelTextController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Package label text (OCR)',
                hintText: 'Paste or type captured label text here',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('fast_add_package_extract_button'),
                onPressed: _extractPackageLabelHints,
                icon: const Icon(Icons.auto_fix_high_outlined),
                label: const Text('Extract Label Hints'),
              ),
            ),
            if (_detectedWeightValue != null || _detectedPurchasePrice != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  [
                    if (_detectedWeightValue != null &&
                        _detectedWeightUnit != null)
                      'Weight: ${_detectedWeightValue!.toStringAsFixed(3)} ${_detectedWeightUnit!.displayName}',
                    if (_detectedPurchasePrice != null)
                      'Price: ${_detectedPurchasePrice!.toStringAsFixed(2)}',
                  ].join(' • '),
                  key: const Key('fast_add_package_extracted_summary'),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            _buildCategoryDropdown(theme),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                key: const Key('fast_add_package_label_continue'),
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  _skipToExpiry();
                },
                icon: const Icon(Icons.event_outlined),
                label: const Text('Continue to Expiry Scan'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _retryBarcodeScanning,
                child: const Text('Back to Barcode Scan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Expiry capture stage ─────────────────────────────────────────────────

  Widget _buildExpiryCaptureStage(ThemeData theme) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            key: const Key('fast_add_expiry_status_card'),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Point the camera at the expiry date on the packaging.',
                    style: AppTextStyles.body,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'For embossed or stamped dates, tilt the package and use side lighting or the torch so the numbers cast a shadow.',
            style: AppTextStyles.bodySmall.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('fast_add_capture_expiry_button'),
              onPressed: _captureExpiryManually,
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Capture Expiry Date'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: const Key('fast_add_skip_expiry_button'),
              onPressed: _advanceToConfirm,
              child: const Text('Skip Expiry'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Expiry locked stage ──────────────────────────────────────────────────

  Widget _buildExpiryLockedStage(ThemeData theme) {
    final expiry = _lockedExpiry;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            key: const Key('fast_add_expiry_locked_card'),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event_available_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    expiry == null
                        ? 'No expiry date detected.'
                        : 'Expiry locked: ${expiry.date.toLocal().toString().split(' ')[0]}',
                    key: const Key('fast_add_locked_expiry_label'),
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const Key('fast_add_expiry_locked_continue'),
              onPressed: _advanceToConfirm,
              child: const Text('Continue — Confirm Item'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: const Key('fast_add_retry_expiry_button'),
              onPressed: () => setState(() {
                _lockedExpiry = null;
                _stage = _FastAddStage.expiryCapture;
              }),
              child: const Text('Re-scan Expiry'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Confirm stage ────────────────────────────────────────────────────────

  Widget _buildConfirmStage(ThemeData theme) {
    final expiry = _lockedExpiry;
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Confirm item details', style: AppTextStyles.h4),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('fast_add_confirm_name_field'),
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Item name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildCategoryDropdown(theme),
            const SizedBox(height: AppSpacing.md),
            if (expiry != null)
              Container(
                key: const Key('fast_add_confirm_expiry_row'),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_outlined, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Expires: ${expiry.date.toLocal().toString().split(' ')[0]}',
                      style: AppTextStyles.body,
                    ),
                    const Spacer(),
                    TextButton(
                      key: const Key('fast_add_clear_expiry'),
                      onPressed: () => setState(() => _lockedExpiry = null),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              )
            else
              OutlinedButton.icon(
                key: const Key('fast_add_add_expiry_button'),
                onPressed: () =>
                    setState(() => _stage = _FastAddStage.expiryCapture),
                icon: const Icon(Icons.add_outlined),
                label: const Text('Add Expiry Date'),
              ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('fast_add_save_button'),
                onPressed: _nameController.text.trim().isEmpty
                    ? null
                    : _saveItem,
                child: const Text('Save Item'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                key: const Key('fast_add_cancel_button'),
                onPressed: () => Navigator.of(
                  context,
                ).pop(const PackagedItemFastAddResult.cancelled()),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared widgets ───────────────────────────────────────────────────────

  Widget _buildCategoryDropdown(ThemeData theme) {
    return DropdownButtonFormField<ItemCategory>(
      key: const Key('fast_add_category_dropdown'),
      initialValue: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(),
      ),
      items: ItemCategory.values
          .map(
            (cat) => DropdownMenuItem(
              value: cat,
              child: Text('${cat.emoji} ${cat.displayName}'),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedCategory = value);
        }
      },
    );
  }
}
