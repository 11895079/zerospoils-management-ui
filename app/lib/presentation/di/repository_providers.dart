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
import '../../domain/models/zesto_model.dart';
import '../../domain/repositories/progress_stats_service.dart';
import '../../domain/repositories/zesto_service.dart';
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
  final client = OpenFoodFactsClient();
  ref.onDispose(client.close);
  return client;
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

/// Bundled storage tips used by Zesto Phase 1 wasted-item messages.
final zestoStorageTipsProvider = Provider<Map<String, List<String>>>((ref) {
  return const {
    'dairy': [
      'Tip: Store milk on the back shelf where temperatures stay coldest.',
      'Tip: Wrap cheese in wax paper, then a loose bag so it can breathe.',
      'Tip: Keep eggs in their carton to reduce odor transfer.',
    ],
    'produce': [
      'Tip: Keep berries dry and wash only right before eating.',
      'Tip: Store leafy greens with a paper towel to absorb moisture.',
      'Tip: Keep bananas away from other fruit to slow ripening.',
    ],
    'meat': [
      'Tip: Freeze meat within two days if you will not cook it soon.',
      'Tip: Defrost meat in the fridge, never on the counter.',
      'Tip: Store raw meat on the lowest shelf to prevent drips.',
    ],
    'bread': [
      'Tip: Slice and freeze bread so you can toast portions as needed.',
      'Tip: Keep bread in a cool, dry cupboard away from heat.',
      'Tip: Avoid refrigerating most bread; it can stale faster.',
    ],
    'leftovers': [
      'Tip: Cool leftovers quickly and refrigerate within two hours.',
      'Tip: Store leftovers in shallow containers for faster cooling.',
      'Tip: Add a date label so you can eat older leftovers first.',
    ],
    'condiments': [
      'Tip: Refrigerate opened sauces unless label says shelf-stable.',
      'Tip: Use clean utensils in jars to avoid contamination.',
      'Tip: Date homemade dressings so they are used in time.',
    ],
    'general': [
      'Tip: Put soon-to-expire items at eye level in your fridge.',
      'Tip: Date labels help you use food in the right order.',
      'Tip: Freeze single portions to save food and prep time.',
    ],
  };
});

/// Zesto service provider for mascot triggers and telemetry events.
final zestoServiceProvider = Provider<ZestoService>((ref) {
  final telemetry = ref.watch(telemetryClientProvider);
  final storageTips = ref.watch(zestoStorageTipsProvider);
  const isTest = bool.fromEnvironment('FLUTTER_TEST');

  return ZestoService(
    getSettings: () => const MascotSettings(
      enabled: true,
      frequency: MascotFrequency.always,
      showCelebrations: true,
      showTips: true,
      showDailyWelcome: true,
    ),
    getStorageTips: () => storageTips,
    displayDuration: isTest ? Duration.zero : const Duration(seconds: 5),
    telemetryLogger: (eventName, properties) {
      telemetry.enqueue({'name': eventName, 'properties': properties});
    },
  );
});
