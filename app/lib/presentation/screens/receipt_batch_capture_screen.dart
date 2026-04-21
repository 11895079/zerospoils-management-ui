library;

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../core/feature_flags/feature_flag_key.dart';
import '../../core/feature_flags/feature_flags_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/vision/batch_goods_photo_service.dart';
import '../../domain/models/receipt_batch.dart';
import '../../domain/models/receipt_line_item.dart';
import '../../domain/utils/receipt_parser.dart';
import '../receipt_batch/receipt_review_item_merger.dart';
import '../di/service_locator.dart' show telemetryClientProvider;
import '../widgets/app_drawer.dart';
import 'receipt_live_scan_screen.dart';
import 'receipt_batch_review_screen.dart';

class ReceiptBatchCaptureScreen extends ConsumerStatefulWidget {
  final ReceiptBatchSource source;
  final bool? debugShowGoodsPhotosOverride;
  final String? existingBatchId;

  const ReceiptBatchCaptureScreen({
    super.key,
    required this.source,
    this.debugShowGoodsPhotosOverride,
    this.existingBatchId,
  });

  @override
  ConsumerState<ReceiptBatchCaptureScreen> createState() =>
      _ReceiptBatchCaptureScreenState();
}

class _ReceiptBatchCaptureScreenState
    extends ConsumerState<ReceiptBatchCaptureScreen> {
  static const ReceiptReviewItemMerger _reviewItemMerger =
      ReceiptReviewItemMerger();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _storeController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  final List<XFile> _receiptPhotos = [];
  final List<XFile> _goodsPhotos = [];
  late final String _batchId;
  DateTime _purchaseDate = DateTime.now();
  bool _processing = false;
  bool _pickingPhoto = false;
  PaymentMethod? _paymentMethod;

    bool get _usesDesktopPhotoPicker =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux);

    bool get _supportsLiveReceiptScan =>
      !kIsWeb &&
      defaultTargetPlatform != TargetPlatform.macOS &&
      defaultTargetPlatform != TargetPlatform.windows &&
      defaultTargetPlatform != TargetPlatform.linux;

  @override
  void initState() {
    super.initState();
    _batchId = widget.existingBatchId ?? _buildBatchId();
    ref.read(telemetryClientProvider).enqueue({
      'name': 'receipt_batch_started',
      'properties': {'source_screen': widget.source.name, 'batch_id': _batchId},
    });
  }

  @override
  void dispose() {
    _storeController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  Future<void> _addReceiptPhoto() async {
    if (_processing || _pickingPhoto) return;
    if (_receiptPhotos.length >= 5) {
      _showSnack('Receipt photo limit reached (5 photos max)');
      return;
    }

    setState(() => _pickingPhoto = true);
    try {
      final photo = await _picker.pickImage(
        source: _usesDesktopPhotoPicker
            ? ImageSource.gallery
            : ImageSource.camera,
        imageQuality: 85,
      );

      if (photo == null) return;

      if (!mounted) return;
      setState(() => _receiptPhotos.add(photo));
      ref.read(telemetryClientProvider).enqueue({
        'name': 'receipt_photo_added',
        'properties': {
          'batch_id': _batchId,
          'photo_index': _receiptPhotos.length,
        },
      });
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
  }

  Future<void> _launchLiveReceiptScan() async {
    if (_processing || _pickingPhoto) {
      return;
    }
    if (_receiptPhotos.length >= 5) {
      _showSnack('Receipt photo limit reached (5 photos max)');
      return;
    }
    if (!_supportsLiveReceiptScan) {
      _showSnack('Live receipt scanning is not available on web yet');
      return;
    }

    final photo = await Navigator.of(context).push<XFile>(
      MaterialPageRoute(builder: (_) => const ReceiptLiveScanScreen()),
    );

    if (photo == null || !mounted) {
      return;
    }

    setState(() => _receiptPhotos.add(photo));
    ref.read(telemetryClientProvider).enqueue({
      'name': 'receipt_live_scan_captured',
      'properties': {
        'batch_id': _batchId,
        'photo_index': _receiptPhotos.length,
      },
    });
  }

  Future<void> _addGoodsPhoto() async {
    if (_processing || _pickingPhoto) return;
    if (_goodsPhotos.length >= 3) {
      _showSnack('Goods photo limit reached (3 photos max)');
      return;
    }

    setState(() => _pickingPhoto = true);
    try {
      final photo = await _picker.pickImage(
        source: _usesDesktopPhotoPicker
            ? ImageSource.gallery
            : ImageSource.camera,
        imageQuality: 85,
      );

      if (photo == null) return;

      if (!mounted) return;
      setState(() => _goodsPhotos.add(photo));
      ref.read(telemetryClientProvider).enqueue({
        'name': 'batch_goods_photo_added',
        'properties': {
          'batch_id': _batchId,
          'photo_index': _goodsPhotos.length,
        },
      });
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
  }

  Future<void> _processReceipts() async {
    if (_receiptPhotos.isEmpty && _goodsPhotos.isEmpty) {
      _showSnack('Add at least one receipt or goods photo');
      return;
    }

    if (kIsWeb) {
      _showSnack('Receipt scanning is not available on web yet');
      return;
    }

    setState(() => _processing = true);
    final parser = ReceiptParser();
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final start = DateTime.now();

    try {
      final parsedItems = <ParsedReceiptItem>[];
      for (
        var photoIndex = 0;
        photoIndex < _receiptPhotos.length;
        photoIndex++
      ) {
        final photo = _receiptPhotos[photoIndex];
        final input = InputImage.fromFilePath(photo.path);
        final result = await textRecognizer.processImage(input);

        final ocrLines = result.blocks
            .expand((block) => block.lines)
            .map(
              (line) => ReceiptOcrLine(
                text: line.text,
                photoIndex: photoIndex,
                box: ReceiptOcrBox(
                  left: line.boundingBox.left,
                  top: line.boundingBox.top,
                  right: line.boundingBox.right,
                  bottom: line.boundingBox.bottom,
                ),
              ),
            )
            .toList();

        final items = ocrLines.isEmpty
            ? parser.parseOcrLines(
                result.text
                    .split(RegExp(r'\r?\n'))
                    .map((line) => line.trim())
                    .where((line) => line.isNotEmpty)
                    .map(
                      (line) =>
                          ReceiptOcrLine(text: line, photoIndex: photoIndex),
                    )
                    .toList(),
              )
            : parser.parseOcrLines(ocrLines);

        for (final item in items) {
          parsedItems.add(
            ParsedReceiptItem(
              name: item.name,
              price: item.price,
              sourceLabel: 'Receipt OCR',
              receiptPhotoIndex: item.photoIndex,
              receiptBox: item.ocrBox,
            ),
          );
        }
      }

      final goodsPhotoSuggestions = _goodsPhotos.isEmpty
          ? const <BatchGoodsPhotoSuggestion>[]
          : await ref
                .read(batchGoodsPhotoServiceProvider)
                .analyzePhotoPaths(
                  _goodsPhotos.map((photo) => photo.path).toList(),
                );

      final mergedItems = _mergeReviewItems(
        parsedItems: parsedItems,
        goodsSuggestions: goodsPhotoSuggestions,
      );

      if (mergedItems.isEmpty) {
        _showSnack('No items detected from the selected photos');
        return;
      }

      final duration = DateTime.now().difference(start).inMilliseconds;
      ref.read(telemetryClientProvider).enqueue({
        'name': 'receipt_batch_processed',
        'properties': {
          'batch_id': _batchId,
          'items_detected': mergedItems.length,
          'receipt_items_detected': parsedItems.length,
          'goods_items_suggested': goodsPhotoSuggestions.length,
          'duration_ms': duration,
        },
      });

      if (!mounted) return;
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => ReceiptBatchReviewScreen(
            source: widget.source,
            photoPaths: _receiptPhotos.map((e) => e.path).toList(),
            goodsPhotoPaths: _goodsPhotos.map((e) => e.path).toList(),
            parsedItems: mergedItems,
            batchId: _batchId,
            existingBatchId: widget.existingBatchId,
            storeName: _normalizedStoreName(),
            purchasedAt: _purchaseDate,
            totalAmount: _parsedBatchTotal(),
            paymentMethod: _paymentMethod,
          ),
        ),
      );
      if (!mounted) return;
      if (saved == true && widget.existingBatchId != null) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      ref.read(telemetryClientProvider).enqueue({
        'name': 'receipt_batch_failed',
        'properties': {'batch_id': _batchId, 'reason': e.toString()},
      });
      _showSnack('Unable to process receipts');
    } finally {
      await textRecognizer.close();
      if (mounted) setState(() => _processing = false);
    }
  }

  String _buildBatchId() {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final suffix = Random().nextInt(9999).toString().padLeft(4, '0');
    return 'batch_$stamp$suffix';
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final debugShowGoodsPhotos = widget.debugShowGoodsPhotosOverride;
    final receiptOcrEnabled = ref.watch(
      isFlagEnabledProvider(FeatureFlagKey.receiptOcr),
    );
    if (debugShowGoodsPhotos != null) {
      final receiptOcrEnabledValue = receiptOcrEnabled.when(
        loading: () => null,
        error: (_, _) => false,
        data: (enabled) => enabled,
      );
      return Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
        },
        child: Actions(
          actions: {
            DismissIntent: CallbackAction<DismissIntent>(
              onInvoke: (intent) {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).maybePop();
                }
                return null;
              },
            ),
          },
          child: Scaffold(
            drawer: const AppDrawer(),
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              leading: Navigator.of(context).canPop()
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).maybePop(),
                    )
                  : null,
              title: const Text('Batch Receipt Capture'),
            ),
            body: Padding(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: receiptOcrEnabledValue == null
                  ? const Center(child: CircularProgressIndicator())
                  : _buildCaptureBody(
                      theme,
                      showGoodsPhotos: debugShowGoodsPhotos,
                      receiptOcrEnabled: receiptOcrEnabledValue,
                    ),
            ),
          ),
        ),
      );
    }

    final batchPhotoCaptureEnabled = ref.watch(
      isFlagEnabledProvider(FeatureFlagKey.batchPhotoCapture),
    );
    final showGoodsPhotos = batchPhotoCaptureEnabled.when(
      loading: () => null,
      error: (_, _) => false,
      data: (enabled) => enabled,
    );
    final receiptOcrEnabledValue = receiptOcrEnabled.when(
      loading: () => null,
      error: (_, _) => false,
      data: (enabled) => enabled,
    );

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (intent) {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).maybePop();
              }
              return null;
            },
          ),
        },
        child: Scaffold(
          drawer: const AppDrawer(),
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            leading: Navigator.of(context).canPop()
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).maybePop(),
                  )
                : null,
            title: const Text('Batch Receipt Capture'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            child: showGoodsPhotos == null || receiptOcrEnabledValue == null
                ? const Center(child: CircularProgressIndicator())
                : _buildCaptureBody(
                    theme,
                    showGoodsPhotos: showGoodsPhotos,
                    receiptOcrEnabled: receiptOcrEnabledValue,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureBody(
    ThemeData theme, {
    required bool showGoodsPhotos,
    required bool receiptOcrEnabled,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView(
            children: [
              Text('Batch details', style: AppTextStyles.h3),
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const Key('receipt_batch_store_name_field'),
                controller: _storeController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Store name',
                  hintText: 'e.g., Costco',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      key: const Key('receipt_batch_purchase_date_field'),
                      onTap: _processing || _pickingPhoto
                          ? null
                          : _selectPurchaseDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Purchase date',
                        ),
                        child: Text(_purchaseDateLabel()),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextField(
                      key: const Key('receipt_batch_total_amount_field'),
                      controller: _totalController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Batch total',
                        hintText: 'Optional',
                        prefixText: r'$',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<PaymentMethod>(
                key: const Key('receipt_batch_payment_method_field'),
                value: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment method',
                  hintText: 'Optional',
                ),
                items: PaymentMethod.values
                    .map(
                      (m) => DropdownMenuItem(
                        value: m,
                        child: Text(m.label),
                      ),
                    )
                    .toList(),
                onChanged: _processing || _pickingPhoto
                    ? null
                    : (value) => setState(() => _paymentMethod = value),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Receipt Photos (${_receiptPhotos.length}/5)',
                key: const Key('receipt_batch_receipt_section'),
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: List.generate(5, (index) {
                  if (index < _receiptPhotos.length) {
                    return _buildPhotoTile('Receipt ${index + 1}');
                  }
                  return _buildAddTile(
                    key: index == _receiptPhotos.length
                        ? const Key('receipt_batch_add_receipt_photo')
                        : null,
                    onTap: _addReceiptPhoto,
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Capture clear photos of each receipt section. Max 5 photos.',
                style: AppTextStyles.body.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              if (_supportsLiveReceiptScan) ...[
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  key: const Key('receipt_batch_live_scan_button'),
                  onPressed: _processing || _pickingPhoto
                      ? null
                      : _launchLiveReceiptScan,
                  icon: const Icon(Icons.view_in_ar_outlined),
                  label: const Text('Live AR Scan Receipt'),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Use the live scanner to preview line-item boxes before you capture the receipt photo.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
              if (showGoodsPhotos) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Goods Photos (${_goodsPhotos.length}/3)',
                  key: const Key('receipt_batch_goods_section'),
                  style: AppTextStyles.h3,
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: List.generate(3, (index) {
                    if (index < _goodsPhotos.length) {
                      return _buildPhotoTile('Goods ${index + 1}');
                    }
                    return _buildAddTile(
                      key: index == _goodsPhotos.length
                          ? const Key('receipt_batch_add_goods_photo')
                          : null,
                      onTap: _addGoodsPhoto,
                    );
                  }),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Use goods photos to suggest likely items and confirm abbreviated receipt lines.',
                  style: AppTextStyles.body.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (!receiptOcrEnabled) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            key: const Key('receipt_batch_ocr_disabled_notice'),
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Text(
              'Receipt OCR is disabled. Enable the receipt_ocr feature flag to process receipt photos.',
              style: AppTextStyles.bodySmall.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            key: const Key('receipt_batch_review_button'),
            onPressed: _processing || _pickingPhoto || !receiptOcrEnabled
                ? null
                : _processReceipts,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: _processing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Review Batch'),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoTile(String label) {
    final theme = Theme.of(context);

    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Center(child: Text(label, style: AppTextStyles.caption)),
    );
  }

  Widget _buildAddTile({Key? key, required VoidCallback onTap}) {
    final theme = Theme.of(context);

    return GestureDetector(
      key: key,
      onTap: _processing || _pickingPhoto ? null : onTap,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Center(
          child: Icon(Icons.add, color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }

  Future<void> _selectPurchaseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (selected == null || !mounted) {
      return;
    }

    setState(() => _purchaseDate = selected);
  }

  String? _normalizedStoreName() {
    final value = _storeController.text.trim();
    return value.isEmpty ? null : value;
  }

  double? _parsedBatchTotal() {
    final normalized = _totalController.text.trim().replaceAll(r'$', '');
    if (normalized.isEmpty) {
      return null;
    }

    return double.tryParse(normalized);
  }

  String _purchaseDateLabel() {
    final month = _purchaseDate.month.toString().padLeft(2, '0');
    final day = _purchaseDate.day.toString().padLeft(2, '0');
    return '${_purchaseDate.year}-$month-$day';
  }

  List<ParsedReceiptItem> _mergeReviewItems({
    required List<ParsedReceiptItem> parsedItems,
    required List<BatchGoodsPhotoSuggestion> goodsSuggestions,
  }) {
    return _reviewItemMerger.merge(
      parsedItems: parsedItems,
      goodsSuggestions: goodsSuggestions,
    );
  }
}
