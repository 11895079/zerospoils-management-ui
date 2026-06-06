library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../domain/models/item_model.dart' hide ShoppingListItem;
import '../../domain/models/receipt_batch.dart';
import '../../domain/models/receipt_line_item.dart';
import '../../domain/models/shopping_list_item.dart';
import '../di/repository_providers.dart';
import '../di/service_locator.dart' show telemetryClientProvider;
import '../widgets/local_image_preview.dart';
import 'receipt_batches_screen.dart';

class ParsedReceiptItem {
  final String name;
  final double price;
  final String sourceLabel;
  final String? matchExplanation;
  final int? receiptPhotoIndex;
  final ReceiptOcrBox? receiptBox;

  ParsedReceiptItem({
    required this.name,
    required this.price,
    this.sourceLabel = 'Receipt OCR',
    this.matchExplanation,
    this.receiptPhotoIndex,
    this.receiptBox,
  });
}

class ReceiptBatchReviewScreen extends ConsumerStatefulWidget {
  final ReceiptBatchSource source;
  final List<String> photoPaths;
  final List<String> goodsPhotoPaths;
  final List<ParsedReceiptItem> parsedItems;
  final List<ReceiptClassifiedRow> excludedRows;
  final String batchId;
  final String? existingBatchId;
  final String? storeName;
  final DateTime? purchasedAt;
  final double? totalAmount;
  final double? parsedTotalAmount;
  final double? parsedTaxAmount;
  final double? parsedSavingsAmount;
  final PaymentMethod? paymentMethod;

  const ReceiptBatchReviewScreen({
    super.key,
    required this.source,
    required this.photoPaths,
    this.goodsPhotoPaths = const [],
    required this.parsedItems,
    this.excludedRows = const [],
    required this.batchId,
    this.existingBatchId,
    this.storeName,
    this.purchasedAt,
    this.totalAmount,
    this.parsedTotalAmount,
    this.parsedTaxAmount,
    this.parsedSavingsAmount,
    this.paymentMethod,
  });

  @override
  ConsumerState<ReceiptBatchReviewScreen> createState() =>
      _ReceiptBatchReviewScreenState();
}

class _ReceiptBatchReviewScreenState
    extends ConsumerState<ReceiptBatchReviewScreen> {
  late List<_EditableReceiptItem> _items;
  int _userPromotedCount = 0;
  int _userDemotedCount = 0;

  @override
  void initState() {
    super.initState();
    _items = [
      ...widget.parsedItems.map(
        (item) => _EditableReceiptItem(
          name: item.name,
          price: item.price,
          quantity: 1,
          selected: true,
          sourceLabel: item.sourceLabel,
          matchExplanation: item.matchExplanation,
          receiptPhotoIndex: item.receiptPhotoIndex,
          receiptBox: item.receiptBox,
          classification: ReceiptRowClassification.saleItem,
          hidden: false,
        ),
      ),
      ...widget.excludedRows.map(
        (row) => _EditableReceiptItem(
          name: _fallbackNameForRow(row),
          price: row.extractedPrice ?? _extractPriceFromText(row.text),
          quantity: 1,
          selected: false,
          sourceLabel: 'Receipt OCR (excluded)',
          matchExplanation:
              'Excluded as ${_classificationLabel(row.classification)}',
          receiptPhotoIndex: row.photoIndex,
          receiptBox: row.box,
          classification: row.classification,
          hidden: true,
          rawText: row.text,
        ),
      ),
    ];
  }

  Future<void> _saveBatch(ReceiptBatchDestination destination) async {
    final selected = _items
        .where((item) => item.selected && !item.hidden)
        .toList(growable: false);
    if (selected.isEmpty) {
      _showSnack('Select at least one item');
      return;
    }

    final batchRepo = ref.read(receiptBatchRepositoryProvider);
    await batchRepo.init();
    final existingBatch = widget.existingBatchId == null
        ? null
        : await batchRepo.getBatch(widget.existingBatchId!);
    final effectiveBatchId = existingBatch?.id ?? widget.batchId;

    final keptCount = _items.where((item) => !item.hidden).length;
    final excludedCount = _items.length - keptCount;
    ref.read(telemetryClientProvider).enqueue({
      'name': 'receipt_scan_lines_detected',
      'properties': {
        'batch_id': effectiveBatchId,
        'total': _items.length,
        'kept': keptCount,
        'excluded': excludedCount,
        'user_promoted': _userPromotedCount,
        'user_demoted': _userDemotedCount,
      },
    });

    final now = DateTime.now();
    var itemCounter = 0;
    String buildItemId(String name) {
      final counter = itemCounter++;
      return '${now.microsecondsSinceEpoch}_${counter}_${name.hashCode}';
    }

    final batchItems = <ReceiptBatchItem>[];

    if (destination == ReceiptBatchDestination.shoppingList) {
      final shoppingRepo = ref.read(shoppingListRepositoryProvider);
      await shoppingRepo.init();
      for (final item in selected) {
        final id = buildItemId(item.name);
        final shoppingItem = ShoppingListItem(
          id: id,
          name: item.name,
          quantity: item.quantity,
          unit: Unit.count.name,
          estimatedCost: item.price,
          createdAt: now,
          updatedAt: now,
        );
        await shoppingRepo.saveShoppingListItem(shoppingItem);
        batchItems.add(
          ReceiptBatchItem(
            id: id,
            name: item.name,
            price: item.price,
            quantity: item.quantity,
            destination: destination,
            shoppingListItemId: id,
          ),
        );
      }
    } else {
      final itemRepo = ref.read(itemRepositoryProvider);
      await itemRepo.init();
      for (final item in selected) {
        final id = buildItemId(item.name);
        final inventoryItem = Item(
          id: id,
          name: item.name,
          category: ItemCategory.other,
          location: StorageLocation.pantry,
          quantity: item.quantity,
          unit: Unit.count,
          purchasePrice: item.price,
          receiptBatchId: effectiveBatchId,
          receiptBatchItemId: id,
          status: ItemStatus.available,
          createdAt: now,
          updatedAt: now,
        );
        await itemRepo.saveItem(inventoryItem);
        ref.read(telemetryClientProvider).enqueue({
          'name': 'item_added',
          'properties': {
            'item_id': inventoryItem.id,
            'source': 'receipt_batch_camera',
            'entry_method': 'receipt_batch_camera',
            'camera_used': true,
            'category': inventoryItem.categoryLabel,
            'is_custom_category': inventoryItem.customCategoryId != null,
            'location': inventoryItem.location.name,
            'quantity': inventoryItem.quantity,
            'has_expiry': inventoryItem.expiryDate != null,
            'has_expiry_date': inventoryItem.expiryDate != null,
            'camera_barcode_accepted': false,
            'camera_expiry_accepted': false,
            'camera_barcode_source': 'none',
            'camera_expiry_format': 'none',
          },
        });
        batchItems.add(
          ReceiptBatchItem(
            id: id,
            name: item.name,
            price: item.price,
            quantity: item.quantity,
            destination: destination,
            inventoryItemId: id,
          ),
        );
      }
    }

    final batch = existingBatch == null
        ? ReceiptBatch(
            id: widget.batchId,
            createdAt: now,
            purchasedAt: widget.purchasedAt,
            storeName: widget.storeName,
            totalAmount: widget.totalAmount,
            source: widget.source,
            items: batchItems,
            receiptImagePaths: widget.photoPaths,
            goodsImagePaths: widget.goodsPhotoPaths,
            paymentMethod: widget.paymentMethod,
          )
        : existingBatch.copyWith(
            purchasedAt: widget.purchasedAt ?? existingBatch.purchasedAt,
            storeName: widget.storeName ?? existingBatch.storeName,
            totalAmount: widget.totalAmount ?? existingBatch.totalAmount,
            items: [...existingBatch.items, ...batchItems],
            receiptImagePaths: [
              ...existingBatch.receiptImagePaths,
              ...widget.photoPaths,
            ],
            goodsImagePaths: [
              ...existingBatch.goodsImagePaths,
              ...widget.goodsPhotoPaths,
            ],
            paymentMethod: widget.paymentMethod ?? existingBatch.paymentMethod,
          );

    await batchRepo.saveBatch(batch);

    ref.read(telemetryClientProvider).enqueue({
      'name': 'receipt_batch_saved',
      'properties': {
        'batch_id': batch.id,
        'items_saved': batch.items.length,
        'destination': destination.name,
      },
    });

    ref.invalidate(receiptBatchesProvider);

    if (!mounted) return;
    if (existingBatch != null) {
      Navigator.of(context).pop(true);
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ReceiptBatchesScreen()),
      (route) => false,
    );
  }

  void _editItem(int index) async {
    final item = _items[index];
    final nameController = TextEditingController(text: item.name);
    final priceController = TextEditingController(text: item.price.toString());
    final quantityController = TextEditingController(
      text: item.quantity.toString(),
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != true) return;

    setState(() {
      _items[index] = item.copyWith(
        name: nameController.text.trim(),
        price: double.tryParse(priceController.text) ?? item.price,
        quantity: int.tryParse(quantityController.text) ?? item.quantity,
      );
    });
  }

  void _promoteExcluded(int index) {
    final item = _items[index];
    setState(() {
      _items[index] = item.copyWith(
        hidden: false,
        selected: true,
        sourceLabel: 'Receipt OCR (promoted)',
      );
      _userPromotedCount += 1;
    });
  }

  void _demoteIncluded(int index) {
    final item = _items[index];
    setState(() {
      _items[index] = item.copyWith(
        hidden: true,
        selected: false,
        sourceLabel: 'Receipt OCR (excluded)',
      );
      _userDemotedCount += 1;
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleEntries = _items
        .asMap()
        .entries
        .where((entry) => !entry.value.hidden)
        .toList(growable: false);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Review Items')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          ..._buildOverlayCards(theme),
          if (widget.storeName != null ||
              widget.purchasedAt != null ||
              widget.totalAmount != null)
            Card(
              child: ListTile(
                key: const Key('receipt_batch_review_metadata'),
                title: Text(widget.storeName ?? 'Shopping batch'),
                subtitle: Text(_reviewMetadataSummary()),
              ),
            ),
          _buildReviewCountsSummary(visibleEntries.length),
          ...visibleEntries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Card(
              color: theme.cardTheme.color ?? theme.cardColor,
              child: ListTile(
                key: ValueKey('receipt_review_item_$index'),
                title: Text(item.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quantity ${item.quantity} · \$${item.price.toStringAsFixed(2)} · ${item.sourceLabel}',
                    ),
                    if (item.matchExplanation != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          item.matchExplanation!,
                          key: Key('receipt_review_item_explanation_$index'),
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
                leading: Checkbox(
                  value: item.selected,
                  onChanged: (value) {
                    setState(
                      () => _items[index] = item.copyWith(
                        selected: value ?? true,
                      ),
                    );
                  },
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      key: Key('receipt_review_demote_$index'),
                      tooltip: 'Move to hidden lines',
                      icon: Icon(
                        Icons.visibility_off_outlined,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () => _demoteIncluded(index),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.edit,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () => _editItem(index),
                    ),
                  ],
                ),
              ),
            );
          }),
          _buildReceiptSummaryFooter(theme),
          _buildHiddenLinesSection(),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: () => _saveBatch(ReceiptBatchDestination.shoppingList),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: const Text('Save to Shopping List'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: () => _saveBatch(ReceiptBatchDestination.inventory),
            child: const Text('Save to Inventory'),
          ),
        ],
      ),
    );
  }

  Widget _buildHiddenLinesSection() {
    final hiddenEntries = _items
        .asMap()
        .entries
        .where((entry) => entry.value.hidden)
        .toList(growable: false);
    if (hiddenEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Semantics(
      key: const Key('receipt_hidden_lines_semantics'),
      container: true,
      label: 'Hidden receipt lines',
      value: '${hiddenEntries.length} lines hidden',
      child: Card(
        key: const Key('receipt_hidden_lines_section'),
        child: ExpansionTile(
          title: Text('Hidden receipt lines (${hiddenEntries.length})'),
          subtitle: const Text(
            'Promote excluded lines when OCR filtered a true sale item.',
          ),
          children: hiddenEntries
              .map((entry) {
                final index = entry.key;
                final item = entry.value;
                return ListTile(
                  key: Key('receipt_hidden_item_$index'),
                  title: Text(item.name),
                  subtitle: Text(
                    '${_classificationLabel(item.classification)} · ${item.rawText ?? item.name}',
                  ),
                  trailing: TextButton.icon(
                    key: Key('receipt_hidden_promote_$index'),
                    onPressed: () => _promoteExcluded(index),
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('Promote'),
                  ),
                );
              })
              .toList(growable: false),
        ),
      ),
    );
  }

  Widget _buildReviewCountsSummary(int includedCount) {
    final hiddenCount = _items.where((item) => item.hidden).length;
    return Semantics(
      key: const Key('receipt_review_counts_semantics'),
      container: true,
      liveRegion: true,
      label: 'Review counts',
      value: '$includedCount included lines, $hiddenCount hidden lines',
      child: Padding(
        key: const Key('receipt_review_counts_summary'),
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(
          'Included: $includedCount · Hidden: $hiddenCount',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

  Widget _buildReceiptSummaryFooter(ThemeData theme) {
    final parsedTotalAmount = widget.parsedTotalAmount;
    final taxAmount = widget.parsedTaxAmount;
    final savingsAmount = widget.parsedSavingsAmount;
    final subtotal = (parsedTotalAmount != null && taxAmount != null)
        ? (parsedTotalAmount - taxAmount)
        : null;

    if (parsedTotalAmount == null &&
        taxAmount == null &&
        savingsAmount == null) {
      return const SizedBox.shrink();
    }

    return Card(
      key: const Key('receipt_review_summary_footer'),
      child: ExpansionTile(
        title: const Text('Receipt summary'),
        subtitle: const Text('Extracted totals and adjustments from OCR.'),
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        children: [
          if (subtotal != null)
            _summaryRow(
              'Subtotal',
              subtotal,
              key: const Key('receipt_summary_subtotal'),
            ),
          if (taxAmount != null)
            _summaryRow(
              'Tax amount',
              taxAmount,
              key: const Key('receipt_summary_tax'),
            ),
          if (savingsAmount != null)
            _summaryRow(
              'Savings',
              savingsAmount,
              key: const Key('receipt_summary_savings'),
            ),
          if (parsedTotalAmount != null)
            _summaryRow(
              'Total amount paid',
              parsedTotalAmount,
              key: const Key('receipt_summary_total'),
            ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value, {required Key key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(r'$' + value.toStringAsFixed(2)),
        ],
      ),
    );
  }

  String _reviewMetadataSummary() {
    final segments = <String>[];
    if (widget.purchasedAt != null) {
      final date = widget.purchasedAt!;
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      segments.add('${date.year}-$month-$day');
    }
    if (widget.totalAmount != null) {
      segments.add(r'$' + widget.totalAmount!.toStringAsFixed(2));
    }
    segments.add('${widget.photoPaths.length} receipts');
    if (widget.goodsPhotoPaths.isNotEmpty) {
      segments.add('${widget.goodsPhotoPaths.length} goods photos');
    }
    return segments.join(' · ');
  }

  String _classificationLabel(ReceiptRowClassification classification) {
    switch (classification) {
      case ReceiptRowClassification.saleItem:
        return 'Sale item';
      case ReceiptRowClassification.tax:
        return 'Tax line';
      case ReceiptRowClassification.total:
        return 'Total line';
      case ReceiptRowClassification.loyalty:
        return 'Loyalty line';
      case ReceiptRowClassification.payment:
        return 'Payment line';
      case ReceiptRowClassification.savings:
        return 'Savings line';
      case ReceiptRowClassification.department:
        return 'Department header';
      case ReceiptRowClassification.storeInfo:
        return 'Store info';
      case ReceiptRowClassification.unknown:
        return 'Uncertain line';
    }
  }

  String _fallbackNameForRow(ReceiptClassifiedRow row) {
    final extracted = row.extractedName?.trim();
    if (extracted != null && extracted.isNotEmpty) {
      return extracted;
    }
    final raw = row.text.trim();
    if (raw.isEmpty) {
      return 'Unlabeled OCR line';
    }
    return raw.length > 48 ? '${raw.substring(0, 48)}...' : raw;
  }

  double _extractPriceFromText(String text) {
    final matches = RegExp(r'\d+[\.,]\d{2}')
        .allMatches(text)
        .map((match) => double.tryParse(match.group(0)!.replaceAll(',', '.')))
        .whereType<double>()
        .toList(growable: false);
    if (matches.isEmpty) {
      return 0;
    }
    return matches.last;
  }

  List<Widget> _buildOverlayCards(ThemeData theme) {
    final grouped = <int, List<_EditableReceiptItem>>{};
    for (final item in _items) {
      final photoIndex = item.receiptPhotoIndex;
      if (photoIndex == null || item.receiptBox == null) {
        continue;
      }
      grouped.putIfAbsent(photoIndex, () => []).add(item);
    }

    if (grouped.isEmpty) {
      return const [];
    }

    final widgets = <Widget>[];
    final sortedKeys = grouped.keys.toList()..sort();
    for (final photoIndex in sortedKeys) {
      if (photoIndex < 0 || photoIndex >= widget.photoPaths.length) {
        continue;
      }
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _ReceiptOcrOverlayCard(
            key: Key('receipt_review_overlay_$photoIndex'),
            theme: theme,
            photoPath: widget.photoPaths[photoIndex],
            photoIndex: photoIndex,
            items: grouped[photoIndex]!,
          ),
        ),
      );
    }

    return widgets;
  }
}

class _EditableReceiptItem {
  final String name;
  final double price;
  final int quantity;
  final bool selected;
  final String sourceLabel;
  final String? matchExplanation;
  final int? receiptPhotoIndex;
  final ReceiptOcrBox? receiptBox;
  final ReceiptRowClassification classification;
  final bool hidden;
  final String? rawText;

  _EditableReceiptItem({
    required this.name,
    required this.price,
    required this.quantity,
    required this.selected,
    required this.sourceLabel,
    this.matchExplanation,
    this.receiptPhotoIndex,
    this.receiptBox,
    required this.classification,
    required this.hidden,
    this.rawText,
  });

  _EditableReceiptItem copyWith({
    String? name,
    double? price,
    int? quantity,
    bool? selected,
    String? sourceLabel,
    String? matchExplanation,
    int? receiptPhotoIndex,
    ReceiptOcrBox? receiptBox,
    ReceiptRowClassification? classification,
    bool? hidden,
    String? rawText,
  }) {
    return _EditableReceiptItem(
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      selected: selected ?? this.selected,
      sourceLabel: sourceLabel ?? this.sourceLabel,
      matchExplanation: matchExplanation ?? this.matchExplanation,
      receiptPhotoIndex: receiptPhotoIndex ?? this.receiptPhotoIndex,
      receiptBox: receiptBox ?? this.receiptBox,
      classification: classification ?? this.classification,
      hidden: hidden ?? this.hidden,
      rawText: rawText ?? this.rawText,
    );
  }
}

class _ReceiptOcrOverlayCard extends StatelessWidget {
  final ThemeData theme;
  final String photoPath;
  final int photoIndex;
  final List<_EditableReceiptItem> items;

  const _ReceiptOcrOverlayCard({
    super.key,
    required this.theme,
    required this.photoPath,
    required this.photoIndex,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final sourceWidth = _maxExtent((box) => box.right, fallback: 320);
    final sourceHeight = _maxExtent((box) => box.bottom, fallback: 480);
    final aspectRatio = sourceWidth <= 0 || sourceHeight <= 0
        ? 0.67
        : sourceWidth / sourceHeight;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detected receipt line items',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Overlay colors: green = included sale item, amber = uncertain hidden line, grey = excluded hidden line.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            AspectRatio(
              aspectRatio: aspectRatio,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: buildLocalImagePreview(
                            photoPath,
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                      ...items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final box = item.receiptBox!;
                        final tone = _toneFor(item, theme);
                        return Positioned(
                          key: Key(
                            'receipt_review_overlay_box_${photoIndex}_$index',
                          ),
                          left: box.left / sourceWidth * constraints.maxWidth,
                          top: box.top / sourceHeight * constraints.maxHeight,
                          width: box.width / sourceWidth * constraints.maxWidth,
                          height:
                              box.height / sourceHeight * constraints.maxHeight,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: tone.border, width: 2),
                              borderRadius: BorderRadius.circular(8),
                              color: tone.fill,
                            ),
                            alignment: Alignment.topLeft,
                            padding: const EdgeInsets.all(4),
                            child: Text(
                              item.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: tone.text,
                                backgroundColor: tone.labelBackground,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _maxExtent(
    double Function(ReceiptOcrBox box) selector, {
    required double fallback,
  }) {
    var maxValue = 0.0;
    for (final item in items) {
      final box = item.receiptBox;
      if (box == null) {
        continue;
      }
      final value = selector(box);
      if (value > maxValue) {
        maxValue = value;
      }
    }
    return maxValue > 0 ? maxValue : fallback;
  }

  _ReceiptOverlayTone _toneFor(_EditableReceiptItem item, ThemeData theme) {
    if (!item.hidden && item.selected) {
      return _ReceiptOverlayTone(
        border: theme.colorScheme.primary,
        fill: theme.colorScheme.primary.withValues(alpha: 0.14),
        labelBackground: theme.colorScheme.primaryContainer,
        text: theme.colorScheme.onPrimaryContainer,
      );
    }

    if (item.classification == ReceiptRowClassification.unknown) {
      return const _ReceiptOverlayTone(
        border: Color(0xFFF9A825),
        fill: Color(0x29F9A825),
        labelBackground: Color(0xFFEEC643),
        text: Colors.black,
      );
    }

    return const _ReceiptOverlayTone(
      border: Color(0xFF90A4AE),
      fill: Color(0x3390A4AE),
      labelBackground: Color(0xFFB0BEC5),
      text: Colors.black,
    );
  }
}

class _ReceiptOverlayTone {
  const _ReceiptOverlayTone({
    required this.border,
    required this.fill,
    required this.labelBackground,
    required this.text,
  });

  final Color border;
  final Color fill;
  final Color labelBackground;
  final Color text;
}
