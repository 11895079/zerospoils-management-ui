library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/models/receipt_batch.dart';
import '../di/repository_providers.dart';
import '../di/service_locator.dart' show telemetryClientProvider;
import '../widgets/app_drawer.dart';
import 'package:go_router/go_router.dart';

final receiptBatchesProvider = FutureProvider<List<ReceiptBatch>>((ref) async {
  final repo = ref.watch(receiptBatchRepositoryProvider);
  await repo.init();
  return repo.getAllBatches();
});

class ReceiptBatchesScreen extends ConsumerStatefulWidget {
  const ReceiptBatchesScreen({super.key});

  @override
  ConsumerState<ReceiptBatchesScreen> createState() =>
      _ReceiptBatchesScreenState();
}

class _ReceiptBatchesScreenState extends ConsumerState<ReceiptBatchesScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(telemetryClientProvider).enqueue({
      'name': 'receipt_batch_list_viewed',
      'properties': {'source_screen': 'receipt_batches'},
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final batchesAsync = ref.watch(receiptBatchesProvider);

    return Scaffold(
      key: const Key('screen_receipt_batches'),
      drawer: const AppDrawer(),
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Receipt Batches'),
        elevation: 1,
        actions: [
          TextButton(
            key: const Key('receipt_batches_new_batch'),
            onPressed: () => context.pushNamed('receipt-batch-capture'),
            child: const Text('New Batch'),
          ),
        ],
      ),
      body: batchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            key: const Key('receipt_batches_error'),
            'Unable to load batches',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ),
        data: (batches) {
          if (batches.isEmpty) {
            return Center(
              child: Text(
                key: const Key('receipt_batches_empty_state'),
                'No receipt batches yet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            itemCount: batches.length,
            itemBuilder: (context, index) {
              final batch = batches[index];
              final total = _currency(batch.totalSpend);
              final date = DateFormat('MMM d').format(batch.createdAt);
              return InkWell(
                key: ValueKey('receipt_batch_card_${batch.id}'),
                onTap: () {
                  ref.read(telemetryClientProvider).enqueue({
                    'name': 'receipt_batch_viewed',
                    'properties': {'batch_id': batch.id},
                  });
                  context.pushNamed(
                    'receipt-batch-detail',
                    pathParameters: {'id': batch.id},
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
                      Text(
                        '${batch.items.length} items · $total total',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _currency(double value) {
    return NumberFormat.simpleCurrency().format(value);
  }
}
