library;

import '../../domain/models/item_model.dart';

/// Contract for item persistence layers
abstract class ItemRepositoryBase {
  Future<void> init();
  Future<List<Item>> getAllItems();
  Future<Item?> getItem(String id);
  Future<void> saveItem(Item item);
  Future<void> deleteItem(String id);
  Future<void> clear();
  Future<void> close();
}
