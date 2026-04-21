library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/models/item_model.dart';
import '../widgets/local_image_preview.dart';
import '../../domain/models/receipt_batch.dart';
import '../../domain/repositories/receipt_batch_stats_service.dart';
import '../di/repository_providers.dart';
import '../di/service_locator.dart' show telemetryClientProvider;
import '../widgets/app_drawer.dart';
import 'item_form_screen.dart';
import 'receipt_batch_capture_screen.dart';

class ReceiptBatchDetailScreen extends ConsumerStatefulWidget {
  final String batchId;
  const ReceiptBatchDetailScreen({super.key, required this.batchId});

  @override
  ConsumerState<ReceiptBatchDetailScreen> createState() =>
      _ReceiptBatchDetailScreenState();
}

class _ReceiptBatchDetailScreenState
    extends ConsumerState<ReceiptBatchDetailScreen> {
  late Future<_BatchDetailData> _batchFuture;

  @override
  void initState() {
    super.initState();
    _batchFuture = _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      key: const Key('screen_receipt_batch_detail'),
      drawer: const AppDrawer(),
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Batch Detail'), elevation: 1),
      floatingActionButton: FloatingActionButton(
        key: const Key('receipt_batch_detail_actions_fab'),
        onPressed: _showBatchActions,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<_BatchDetailData>(
        future: _batchFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load batch',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            );
          }

          final data = snapshot.data!;
          final batch = data.batch;
          final stats = data.stats;
          final total = _currency(stats.totalSpend);
          final consumed = _currency(stats.consumedValue);
          final wasted = _currency(stats.wastedValue);
          final remaining = _currency(stats.remainingValue);
          final date = DateFormat(
            'MMM d, yyyy',
          ).format(batch.purchasedAt ?? batch.createdAt);
          final attachmentSummary = batch.goodsImagePaths.isEmpty
              ? '${batch.receiptImagePaths.length} receipts'
              : '${batch.receiptImagePaths.length} receipts · ${batch.goodsImagePaths.length} goods photos';

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              Container(
                key: const Key('receipt_batch_summary'),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      batch.storeName == null || batch.storeName!.isEmpty
                          ? '$date · $attachmentSummary'
                          : '${batch.storeName} · $date · $attachmentSummary',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text('${batch.items.length} items · $total total'),
                    const SizedBox(height: AppSpacing.sm),
                    _buildStatRow('Consumed', consumed),
                    _buildStatRow('Wasted', wasted),
                    _buildStatRow('Remaining', remaining),
                    if (batch.paymentMethod != null)
                      _buildStatRow('Payment', batch.paymentMethod!.label),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Items',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...batch.items.map((item) {
                final inventoryItem = data.inventoryItems[item.inventoryItemId];
                final status = _statusLabel(item, inventoryItem);
                return InkWell(
                  key: Key('receipt_batch_item_${item.id}'),
                  onTap: () => _showItemActions(item),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: AppTextStyles.body),
                              const SizedBox(height: 4),
                              Text(
                                status,
                                style: AppTextStyles.caption.copyWith(
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(_currency(item.price * item.quantity)),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ],
                    ),
                  ),
                );
              }),
              if (batch.receiptImagePaths.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Receipt Photos',
                  key: const Key('receipt_batch_photos_header'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: batch.receiptImagePaths.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, i) => ClipRRect(
                      key: Key('receipt_photo_$i'),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      child: SizedBox(
                        width: 120,
                        child: buildLocalImagePreview(
                          batch.receiptImagePaths[i],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              _buildCategorySpend(batch, data.inventoryItems),
            ],
          );
        },
      ),
    );
  }

  Future<_BatchDetailData> _loadData() async {
    final batchRepo = ref.read(receiptBatchRepositoryProvider);
    final itemRepo = ref.read(itemRepositoryProvider);
    await batchRepo.init();
    await itemRepo.init();
    final batch = await batchRepo.getBatch(widget.batchId);
    if (batch == null) throw Exception('Batch not found');
    final items = await itemRepo.getAllItems();
    final itemMap = {for (final item in items) item.id: item};
    final statsService = ReceiptBatchStatsService();
    final stats = statsService.build(batch: batch, inventoryItems: items);

    ref.read(telemetryClientProvider).enqueue({
      'name': 'receipt_batch_viewed',
      'properties': {'batch_id': batch.id},
    });

    return _BatchDetailData(
      batch: batch,
      stats: stats,
      inventoryItems: itemMap,
    );
  }

  Future<void> _reload() async {
    if (!mounted) return;
    setState(() {
      _batchFuture = _loadData();
    });
  }

  Future<ReceiptBatch?> _readCurrentBatch() async {
    final batchRepo = ref.read(receiptBatchRepositoryProvider);
    await batchRepo.init();
    return batchRepo.getBatch(widget.batchId);
  }

  Future<void> _showBatchActions() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                key: const Key('batch_action_add_item'),
                leading: const Icon(Icons.add_box_outlined),
                title: const Text('Add new item'),
                subtitle: const Text('Create and link a new inventory item'),
                onTap: () {
                  Navigator.of(context).pop();
                  _addNewItem();
                },
              ),
              ListTile(
                key: const Key('batch_action_scan_receipt'),
                leading: const Icon(Icons.document_scanner_outlined),
                title: const Text('Scan another receipt'),
                subtitle: const Text('Capture missed lines and merge into this batch'),
                onTap: () {
                  Navigator.of(context).pop();
                  _scanAnotherReceipt();
                },
              ),
              ListTile(
                key: const Key('batch_action_link_existing'),
                leading: const Icon(Icons.link_outlined),
                title: const Text('Link existing item'),
                subtitle: const Text('Attach an existing inventory item to this batch'),
                onTap: () {
                  Navigator.of(context).pop();
                  _linkExistingItem();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addNewItem({ReceiptBatchItem? linkToLine}) async {
    final item = await Navigator.of(context).push<Item>(
      MaterialPageRoute(
        builder: (_) => ItemFormScreen(
          initialName: linkToLine?.name,
          initialPrice: linkToLine?.price,
          initialReceiptBatchId: widget.batchId,
        ),
      ),
    );
    if (item == null) return;

    if (linkToLine != null) {
      await _updateLineLink(linkToLine.id, item);
    } else {
      final lineId =
          'manual_${DateTime.now().microsecondsSinceEpoch}_${item.id.hashCode}';
      await _appendLine(
        ReceiptBatchItem(
          id: lineId,
          name: item.name,
          price: item.purchasePrice ?? 0,
          quantity: item.quantity,
          destination: ReceiptBatchDestination.inventory,
          inventoryItemId: item.id,
        ),
      );
      await _attachItemToLine(item: item, lineId: lineId);
    }
    await _reload();
  }

  Future<void> _scanAnotherReceipt() async {
    final batch = await _readCurrentBatch();
    if (batch == null || !mounted) return;

    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ReceiptBatchCaptureScreen(
          source: batch.source,
          existingBatchId: batch.id,
        ),
      ),
    );
    if (updated == true) {
      await _reload();
    }
  }

  Future<void> _linkExistingItem({ReceiptBatchItem? line}) async {
    final batch = await _readCurrentBatch();
    if (batch == null || !mounted) return;

    final itemRepo = ref.read(itemRepositoryProvider);
    await itemRepo.init();
    final allItems = await itemRepo.getAllItems();
    final linkedIds = batch.items
        .map((it) => it.inventoryItemId)
        .whereType<String>()
        .toSet();
    final candidates = allItems
        .where((item) => line != null || !linkedIds.contains(item.id))
        .toList();

    final selected = await _pickInventoryItem(candidates);
    if (selected == null) return;

    if (line != null) {
      await _updateLineLink(line.id, selected);
      await _reload();
      return;
    }

    final draft = await _promptLineDraft(
      defaultName: selected.name,
      defaultPrice: selected.purchasePrice,
      defaultQuantity: selected.quantity,
    );
    if (draft == null) return;

    final lineId =
        'manual_${DateTime.now().microsecondsSinceEpoch}_${selected.id.hashCode}';
    await _appendLine(
      ReceiptBatchItem(
        id: lineId,
        name: draft.name,
        price: draft.price,
        quantity: draft.quantity,
        destination: ReceiptBatchDestination.inventory,
        inventoryItemId: selected.id,
      ),
    );
    await _attachItemToLine(item: selected, lineId: lineId);
    await _reload();
  }

  Future<void> _showItemActions(ReceiptBatchItem lineItem) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        final linked =
            lineItem.destination == ReceiptBatchDestination.inventory &&
            lineItem.inventoryItemId != null;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (linked) ...[
                ListTile(
                  key: Key('line_action_edit_${lineItem.id}'),
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Edit linked item'),
                  subtitle: const Text('Update details for this receipt line item'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _openItemEditor(lineItem.inventoryItemId!);
                  },
                ),
                ListTile(
                  key: Key('line_action_scan_${lineItem.id}'),
                  leading: const Icon(Icons.qr_code_scanner_outlined),
                  title: const Text('Scan barcode or product'),
                  subtitle: const Text('Use barcode/CV to enrich product details'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _openItemEditor(lineItem.inventoryItemId!);
                  },
                ),
              ] else ...[
                ListTile(
                  key: Key('line_action_create_link_${lineItem.id}'),
                  leading: const Icon(Icons.add_circle_outline),
                  title: const Text('Create and link item'),
                  subtitle: const Text('Add this line as a fresh inventory item'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _addNewItem(linkToLine: lineItem);
                  },
                ),
              ],
              ListTile(
                key: Key('line_action_link_${lineItem.id}'),
                leading: const Icon(Icons.link_outlined),
                title: const Text('Link existing inventory item'),
                onTap: () {
                  Navigator.of(context).pop();
                  _linkExistingItem(line: lineItem);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openItemEditor(String itemId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ItemFormScreen(itemId: itemId)),
    );
    await _reload();
  }

  Future<void> _appendLine(ReceiptBatchItem newLine) async {
    final batchRepo = ref.read(receiptBatchRepositoryProvider);
    await batchRepo.init();
    final batch = await batchRepo.getBatch(widget.batchId);
    if (batch == null) return;
    await batchRepo.saveBatch(batch.copyWith(items: [...batch.items, newLine]));
  }

  Future<void> _updateLineLink(String lineId, Item item) async {
    final batchRepo = ref.read(receiptBatchRepositoryProvider);
    await batchRepo.init();
    final batch = await batchRepo.getBatch(widget.batchId);
    if (batch == null) return;

    final updatedItems = batch.items
        .map(
          (line) => line.id == lineId
              ? line.copyWith(
                  destination: ReceiptBatchDestination.inventory,
                  inventoryItemId: item.id,
                  shoppingListItemId: null,
                )
              : line,
        )
        .toList();
    await batchRepo.saveBatch(batch.copyWith(items: updatedItems));
    await _attachItemToLine(item: item, lineId: lineId);
  }

  Future<void> _attachItemToLine({required Item item, required String lineId}) async {
    final itemRepo = ref.read(itemRepositoryProvider);
    await itemRepo.init();
    final refreshed = await itemRepo.getItem(item.id);
    if (refreshed == null) return;
    await itemRepo.saveItem(
      refreshed.copyWith(
        receiptBatchId: widget.batchId,
        receiptBatchItemId: lineId,
      ),
    );
  }

  Future<Item?> _pickInventoryItem(List<Item> items) async {
    if (items.isEmpty || !mounted) {
      _showSnack('No inventory items available to link');
      return null;
    }

    return showModalBottomSheet<Item>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        var query = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = items
                .where(
                  (item) => item.name.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  top: AppSpacing.md,
                  bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
                ),
                child: SizedBox(
                  height: 460,
                  child: Column(
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search inventory items',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          setSheetState(() {
                            query = value;
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Expanded(
                        child: ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return ListTile(
                              key: Key('batch_link_candidate_${item.id}'),
                              title: Text(item.name),
                              subtitle: Text(
                                '${item.category.displayName} · qty ${item.quantity}',
                              ),
                              onTap: () => Navigator.of(context).pop(item),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<_BatchLineDraft?> _promptLineDraft({
    required String defaultName,
    required double? defaultPrice,
    required int defaultQuantity,
  }) async {
    final nameController = TextEditingController(text: defaultName);
    final priceController = TextEditingController(
      text: (defaultPrice ?? 0).toStringAsFixed(2),
    );
    final quantityController = TextEditingController(
      text: (defaultQuantity <= 0 ? 1 : defaultQuantity).toString(),
    );

    return showDialog<_BatchLineDraft>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add line item details'),
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
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final price = double.tryParse(priceController.text.trim());
              final quantity = int.tryParse(quantityController.text.trim());
              if (name.isEmpty || price == null || quantity == null || quantity <= 0) {
                return;
              }
              Navigator.of(
                context,
              ).pop(_BatchLineDraft(name: name, price: price, quantity: quantity));
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _statusLabel(ReceiptBatchItem item, Item? inventoryItem) {
    if (item.destination == ReceiptBatchDestination.shoppingList) {
      return 'In Shopping List';
    }
    if (inventoryItem == null) return 'Pending';
    switch (inventoryItem.status) {
      case ItemStatus.available:
        return 'Available';
      case ItemStatus.consumed:
        return 'Consumed';
      case ItemStatus.wasted:
        return 'Wasted';
    }
  }

  Widget _buildStatRow(String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  String _currency(double value) {
    return NumberFormat.simpleCurrency().format(value);
  }

  Widget _buildCategorySpend(
    ReceiptBatch batch,
    Map<String, Item> inventoryItems,
  ) {
    final spendByCategory = <ItemCategory, double>{};
    for (final batchItem in batch.items) {
      final inventoryItem = inventoryItems[batchItem.inventoryItemId];
      final category = inventoryItem?.category ?? ItemCategory.other;
      spendByCategory[category] =
          (spendByCategory[category] ?? 0) +
          batchItem.price * batchItem.quantity;
    }

    if (spendByCategory.isEmpty) return const SizedBox.shrink();

    final sorted = spendByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final theme = Theme.of(context);
    return Column(
      key: const Key('receipt_batch_category_spend'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Spend by Category',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: sorted.map((entry) {
            return Chip(
              key: Key('category_spend_chip_${entry.key.name}'),
              label: Text(
                '${entry.key.emoji} ${entry.key.displayName}  ${_currency(entry.value)}',
                style: AppTextStyles.bodySmall,
              ),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              side: BorderSide(color: theme.dividerColor),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _BatchDetailData {
  final ReceiptBatch batch;
  final ReceiptBatchStats stats;
  final Map<String, Item> inventoryItems;

  _BatchDetailData({
    required this.batch,
    required this.stats,
    required this.inventoryItems,
  });
}

class _BatchLineDraft {
  final String name;
  final double price;
  final int quantity;

  _BatchLineDraft({
    required this.name,
    required this.price,
    required this.quantity,
  });
}
