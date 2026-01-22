library;

/// Providers for repository access throughout the app
/// Riverpod-based dependency injection for data layer

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/hive_item_repository.dart';
import '../../domain/models/item_model.dart';

/// Singleton instance of HiveItemRepository
final hiveItemRepositoryProvider = Provider((ref) {
  return HiveItemRepository();
});

/// Future provider to fetch all items from persistence
final itemsFutureProvider = FutureProvider<List<Item>>((ref) async {
  final repository = ref.read(hiveItemRepositoryProvider);
  await repository.init();
  return repository.getAllItems();
});
