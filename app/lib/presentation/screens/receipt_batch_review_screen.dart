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
  final String batchId;
  final String? existingBatchId;
  final String? storeName;
  final DateTime? purchasedAt;
  final double? totalAmount;
  final PaymentMethod? paymentMethod;

  const ReceiptBatchReviewScreen({
    super.key,
    required this.source,
    required this.photoPaths,
    this.goodsPhotoPaths = const [],
    required this.parsedItems,
    required this.batchId,
    this.existingBatchId,
    this.storeName,
    this.purchasedAt,
    this.totalAmount,
    this.paymentMethod,
  });

  @override
  ConsumerState<ReceiptBatchReviewScreen> createState() =>
      _ReceiptBatchReviewScreenState();
}

class _ReceiptBatchReviewScreenState
    extends ConsumerState<ReceiptBatchReviewScreen> {
  late List<_EditableReceiptItem> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.parsedItems
        .map(
          (item) => _EditableReceiptItem(
            name: item.name,
            price: item.price,
            quantity: 1,
            selected: true,
            sourceLabel: item.sourceLabel,
            matchExplanation: item.matchExplanation,
            receiptPhotoIndex: item.receiptPhotoIndex,
            receiptBox: item.receiptBox,
          ),
        )
        .toList();
  }

  Future<void> _saveBatch(ReceiptBatchDestination destination) async {
    final selected = _items.where((item) => item.selected).toList();
    if (selected.isEmpty) {
      _showSnack('Select at least one item');
      return;
    }

    final now = DateTime.now();
    var itemCounter = 0;
    String buildItemId(String name) {
      final counter = itemCounter++;
      return '${now.microsecondsSinceEpoch}_${counter}_${name.hashCode}';
    }

    final batchItems = <ReceiptBatchItem>[];
    final batchRepo = ref.read(receiptBatchRepositoryProvider);
    await batchRepo.init();
    final existingBatch = widget.existingBatchId == null
        ? null
        : await batchRepo.getBatch(widget.existingBatchId!);
    final effectiveBatchId = existingBatch?.id ?? widget.batchId;

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

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          ..._items.asMap().entries.map((entry) {
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
                trailing: IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () => _editItem(index),
                ),
              ),
            );
          }),
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

  _EditableReceiptItem({
    required this.name,
    required this.price,
    required this.quantity,
    required this.selected,
    required this.sourceLabel,
    this.matchExplanation,
    this.receiptPhotoIndex,
    this.receiptBox,
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
              'Highlighted boxes show which OCR regions were treated as sale items.',
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
                              border: Border.all(
                                color: theme.colorScheme.primary,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.14,
                              ),
                            ),
                            alignment: Alignment.topLeft,
                            padding: const EdgeInsets.all(4),
                            child: Text(
                              item.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                backgroundColor:
                                    theme.colorScheme.primaryContainer,
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
}
