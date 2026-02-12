library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/models/item_model.dart' hide ShoppingListItem;
import '../../domain/models/receipt_batch.dart';
import '../../domain/models/shopping_list_item.dart';
import '../di/repository_providers.dart';
import '../di/service_locator.dart' show telemetryClientProvider;
import 'receipt_batches_screen.dart';

class ParsedReceiptItem {
  final String name;
  final double price;

  ParsedReceiptItem({required this.name, required this.price});
}

class ReceiptBatchReviewScreen extends ConsumerStatefulWidget {
  final ReceiptBatchSource source;
  final List<String> photoPaths;
  final List<ParsedReceiptItem> parsedItems;
  final String batchId;

  const ReceiptBatchReviewScreen({
    super.key,
    required this.source,
    required this.photoPaths,
    required this.parsedItems,
    required this.batchId,
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
    final batchItems = <ReceiptBatchItem>[];

    if (destination == ReceiptBatchDestination.shoppingList) {
      final shoppingRepo = ref.read(shoppingListRepositoryProvider);
      await shoppingRepo.init();
      for (final item in selected) {
        final id = '${now.microsecondsSinceEpoch}_${item.name.hashCode}';
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
        final id = '${now.microsecondsSinceEpoch}_${item.name.hashCode}';
        final inventoryItem = Item(
          id: id,
          name: item.name,
          category: ItemCategory.other,
          location: StorageLocation.pantry,
          quantity: item.quantity,
          unit: Unit.count,
          purchasePrice: item.price,
          status: ItemStatus.available,
          createdAt: now,
          updatedAt: now,
        );
        await itemRepo.saveItem(inventoryItem);
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

    final batch = ReceiptBatch(
      id: widget.batchId,
      createdAt: now,
      source: widget.source,
      items: batchItems,
      receiptImagePaths: widget.photoPaths,
    );

    final batchRepo = ref.read(receiptBatchRepositoryProvider);
    await batchRepo.init();
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Review Items', style: AppTextStyles.h3),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          ..._items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Card(
              child: ListTile(
                key: ValueKey('receipt_review_item_$index'),
                title: Text(item.name),
                subtitle: Text('Quantity ${item.quantity} · \$${item.price}'),
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
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editItem(index),
                ),
              ),
            );
          }),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: () => _saveBatch(ReceiptBatchDestination.shoppingList),
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
}

class _EditableReceiptItem {
  final String name;
  final double price;
  final int quantity;
  final bool selected;

  _EditableReceiptItem({
    required this.name,
    required this.price,
    required this.quantity,
    required this.selected,
  });

  _EditableReceiptItem copyWith({
    String? name,
    double? price,
    int? quantity,
    bool? selected,
  }) {
    return _EditableReceiptItem(
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      selected: selected ?? this.selected,
    );
  }
}
