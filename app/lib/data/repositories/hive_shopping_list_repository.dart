import 'package:hive/hive.dart';
import '../../domain/models/shopping_list_item.dart';

class HiveShoppingListRepository {
  static const String _boxName = 'shopping_list';
  Box<ShoppingListItem>? _box;

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(20)) {
      Hive.registerAdapter(ShoppingListItemAdapter());
    }
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<ShoppingListItem>(_boxName);
    } else {
      _box = Hive.box<ShoppingListItem>(_boxName);
    }
  }

  Future<void> clear() async {
    await _box?.clear();
  }

  Future<void> saveShoppingListItem(ShoppingListItem item) async {
    await _box?.put(item.id, item);
  }

  Future<List<ShoppingListItem>> getAllItems() async {
    return _box?.values.toList() ?? [];
  }

  Future<void> deleteItem(String id) async {
    await _box?.delete(id);
  }

  Future<List<ShoppingListItem>> getPurchased() async {
    return _box?.values.where((item) => item.isPurchased).toList() ?? [];
  }

  Future<List<ShoppingListItem>> getUnpurchased() async {
    return _box?.values.where((item) => !item.isPurchased).toList() ?? [];
  }

  Future<void> markAsPurchased(String id) async {
    final item = _box?.get(id);
    if (item != null) {
      final updated = item.copyWith(
        isPurchased: true,
        purchasedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _box?.put(id, updated);
    }
  }

  Future<void> markAsUnpurchased(String id) async {
    final item = _box?.get(id);
    if (item != null) {
      // Workaround: copyWith does not set purchasedAt to null if null is passed explicitly, so create a new object
      final updated = ShoppingListItem(
        id: item.id,
        name: item.name,
        category: item.category,
        quantity: item.quantity,
        unit: item.unit,
        estimatedCost: item.estimatedCost,
        isPurchased: false,
        purchasedAt: null,
        notes: item.notes,
        createdAt: item.createdAt,
        updatedAt: DateTime.now(),
      );
      await _box?.put(id, updated);
    }
  }
}
