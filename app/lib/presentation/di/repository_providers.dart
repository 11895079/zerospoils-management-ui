library;

/// Providers for repository access throughout the app
/// Riverpod-based dependency injection for data layer

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/hive_item_repository.dart';
import '../../data/repositories/demo_item_repository.dart';
import '../../data/repositories/item_repository_base.dart';
import '../../domain/models/item_model.dart';

/// Demo mode flag (enabled by default for prototyping)
final demoModeProvider = StateProvider<bool>((ref) => true);

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
