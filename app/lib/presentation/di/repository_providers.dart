library;

/// Providers for repository access throughout the app
/// Riverpod-based dependency injection for data layer

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/hive_item_repository.dart';
import '../../data/repositories/hive_shopping_list_repository.dart';
import '../../data/repositories/receipt_batch_repository.dart';
import '../../data/repositories/demo_item_repository.dart';
import '../../data/repositories/item_repository_base.dart';
import '../../domain/models/item_model.dart';
import '../../domain/repositories/progress_stats_service.dart';
import 'service_locator.dart'
    show telemetryClientProvider, progressStatsServiceProvider;

/// Demo mode flag (enabled by default for prototyping)
final demoModeProvider = StateProvider<bool>((ref) => true);

/// Home tab index for bottom navigation (Inventory, Expiring, Shopping, Progress)
final homeTabIndexProvider = StateProvider<int>((ref) => 0);

/// Track if user has manually entered items (disables demo toggle)
final hasManualItemsProvider = StateProvider<bool>((ref) => false);

/// Repository selector (demo vs Hive)
final itemRepositoryProvider = Provider<ItemRepositoryBase>((ref) {
  final isDemo = ref.watch(demoModeProvider);
  if (isDemo) return DemoItemRepository();
  return HiveItemRepository();
});

/// Future provider to fetch all items from persistence
final itemsFutureProvider = FutureProvider<List<Item>>((ref) async {
  final repository = ref.watch(itemRepositoryProvider);
  await repository.init();
  return repository.getAllItems();
});

/// Shopping list repository provider
final shoppingListRepositoryProvider = Provider<HiveShoppingListRepository>((
  ref,
) {
  return HiveShoppingListRepository();
});

/// Receipt batch repository provider
final receiptBatchRepositoryProvider = Provider<ReceiptBatchRepository>((ref) {
  return HiveReceiptBatchRepository();
});

/// Progress stats provider (aggregates items + telemetry locally)
final progressStatsProvider = FutureProvider<ProgressStats>((ref) async {
  final repository = ref.watch(itemRepositoryProvider);
  final statsService = ref.watch(progressStatsServiceProvider);
  final telemetry = ref.watch(telemetryClientProvider);

  await repository.init();
  final items = await repository.getAllItems();

  return statsService.build(items: items, telemetryEvents: telemetry.events);
});
