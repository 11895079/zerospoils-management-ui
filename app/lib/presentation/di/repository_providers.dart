library;

/// Providers for repository access throughout the app
/// Riverpod-based dependency injection for data layer

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/barcode/learned_barcode_mapping_store.dart';
import '../../core/barcode/local_barcode_catalog.dart';
import '../../core/barcode/open_food_facts_client.dart';
import '../../data/repositories/hive_item_repository.dart';
import '../../data/repositories/hive_shopping_list_repository.dart';
import '../../data/repositories/receipt_batch_repository.dart';
import '../../data/repositories/demo_item_repository.dart';
import '../../data/repositories/item_repository_base.dart';
import '../../data/repositories/user_category_repository.dart';
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

/// User-defined category repository provider
final userCategoryRepositoryProvider = Provider<UserCategoryRepository>((ref) {
  return UserCategoryRepository();
});

/// Learned barcode mapping store provider
final learnedBarcodeMappingStoreProvider = Provider<LearnedBarcodeMappingStore>(
  (ref) {
    return LearnedBarcodeMappingStore();
  },
);

/// Seed barcode catalog loaded from the bundled JSON asset.
/// Falls back to the compiled-in map for any barcode not in the JSON.
final localBarcodeCatalogProvider = FutureProvider<LocalBarcodeCatalog>((ref) {
  return LocalBarcodeCatalog.fromAsset();
});

/// OpenFoodFacts client for real-time barcode resolution when local lookup misses.
final openFoodFactsClientProvider = Provider<OpenFoodFactsClient>((ref) {
  return OpenFoodFactsClient();
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

/// Date format preference provider (reads from SharedPreferences)
/// Returns format string: 'MM/DD/YYYY', 'DD/MM/YYYY', or 'YYYY-MM-DD'
final dateFormatPreferenceProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('date_format') ?? 'MM/DD/YYYY';
});
