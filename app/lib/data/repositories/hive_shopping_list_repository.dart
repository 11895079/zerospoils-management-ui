import 'package:hive/hive.dart';
import '../../domain/models/shopping_list_item.dart';
import '../../presentation/di/service_locator.dart';

class HiveShoppingListRepository {
  /// Allow test to inject a telemetry callback
  void setTelemetryCallback(
    void Function(String, Map<String, dynamic>) callback,
  ) {
    _telemetryClient.setEmitCallback(callback);
  }

  static const String _boxName = 'shopping_list';
  Box<ShoppingListItem>? _box;
  final TelemetryClient _telemetryClient = TelemetryClient();

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
    final existing = _box?.get(item.id);
    await _box?.put(item.id, item);

    if (existing == null) {
      _telemetryClient.enqueue({
        'name': 'shopping_list_item_added',
        'properties': {
          'item_id': item.id,
          'category': item.category,
          'quantity': item.quantity,
          'unit': item.unit,
          'source': 'manual',
        },
      });
    }
  }

  Future<List<ShoppingListItem>> getAllItems() async {
    final items = _box?.values.toList() ?? [];
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<ShoppingListItem?> getItem(String id) async {
    return _box?.get(id);
  }

  Future<void> deleteItem(String id) async {
    await _box?.delete(id);

    _telemetryClient.enqueue({
      'name': 'shopping_list_item_deleted',
      'properties': {'item_id': id},
    });
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
      final purchasedAt = DateTime.now();
      final daysToPurchase = purchasedAt.difference(item.createdAt).inDays;
      final updated = item.copyWith(
        isPurchased: true,
        purchasedAt: purchasedAt,
        updatedAt: purchasedAt,
      );
      await _box?.put(id, updated);

      _telemetryClient.enqueue({
        'name': 'shopping_list_item_purchased',
        'properties': {'item_id': item.id, 'days_to_purchase': daysToPurchase},
      });
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
