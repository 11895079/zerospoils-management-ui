library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
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

class ReceiptBatchesScreen extends ConsumerWidget {
  const ReceiptBatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchesAsync = ref.watch(receiptBatchesProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(telemetryClientProvider).enqueue({
        'name': 'receipt_batch_list_viewed',
        'properties': {'source_screen': 'receipt_batches'},
      });
    });

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Receipt Batches', style: AppTextStyles.h3),
        elevation: 1,
        actions: [
          TextButton(
            onPressed: () => context.pushNamed('receipt-batch-capture'),
            child: const Text('New Batch'),
          ),
        ],
      ),
      body: batchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Unable to load batches',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ),
        data: (batches) {
          if (batches.isEmpty) {
            return Center(
              child: Text(
                'No receipt batches yet',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: AppColors.border),
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
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
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
