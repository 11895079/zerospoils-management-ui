library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/models/item_model.dart';
import '../../domain/models/receipt_batch.dart';
import '../../domain/repositories/receipt_batch_stats_service.dart';
import '../di/repository_providers.dart';
import '../di/service_locator.dart' show telemetryClientProvider;
import '../widgets/app_drawer.dart';

class ReceiptBatchDetailScreen extends ConsumerStatefulWidget {
  final String batchId;
  const ReceiptBatchDetailScreen({super.key, required this.batchId});

  @override
  ConsumerState<ReceiptBatchDetailScreen> createState() =>
      _ReceiptBatchDetailScreenState();
}

class _ReceiptBatchDetailScreenState
    extends ConsumerState<ReceiptBatchDetailScreen> {
  late final Future<_BatchDetailData> _batchFuture;

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
          final date = DateFormat('MMM d, yyyy').format(batch.createdAt);

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
                      '$date · ${batch.receiptImagePaths.length} receipts',
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
                return Container(
                  key: Key('receipt_batch_item_${item.id}'),
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
                    ],
                  ),
                );
              }),
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
