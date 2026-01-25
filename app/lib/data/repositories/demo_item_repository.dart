library;

import '../../domain/models/item_model.dart';
import 'item_repository_base.dart';

/// In-memory demo repository to avoid manual item creation during testing/demo
class DemoItemRepository implements ItemRepositoryBase {
  final Map<String, Item> _items = {};

  DemoItemRepository() {
    _seed();
  }

  void _seed() {
    final now = DateTime.now();
    _items.clear();
    _items['1'] = Item(
      id: '1',
      name: 'Fresh Apples',
      category: ItemCategory.produce,
      type: ItemType.raw,
      location: StorageLocation.fridge,
      quantity: 6,
      unit: Unit.count,
      expiryDate: now.add(const Duration(days: 5)),
      status: ItemStatus.available,
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now,
    );
    _items['2'] = Item(
      id: '2',
      name: 'Leftover Pasta',
      category: ItemCategory.pantry,
      type: ItemType.prepared,
      location: StorageLocation.fridge,
      quantity: 2,
      unit: Unit.count,
      expiryDate: now.add(const Duration(days: 1)),
      status: ItemStatus.available,
      createdAt: now.subtract(const Duration(days: 2)),
      updatedAt: now,
    );
    _items['3'] = Item(
      id: '3',
      name: 'Chicken Breast',
      category: ItemCategory.meat,
      type: ItemType.raw,
      location: StorageLocation.freezer,
      quantity: 4,
      unit: Unit.count,
      expiryDate: now.add(const Duration(days: 20)),
      status: ItemStatus.available,
      createdAt: now.subtract(const Duration(days: 5)),
      updatedAt: now,
    );
    _items['4'] = Item(
      id: '4',
      name: 'Yogurt Cups',
      category: ItemCategory.dairy,
      location: StorageLocation.fridge,
      quantity: 3,
      unit: Unit.count,
      expiryDate: now.add(const Duration(days: 7)),
      status: ItemStatus.available,
      createdAt: now.subtract(const Duration(days: 3)),
      updatedAt: now,
    );
    _items['5'] = Item(
      id: '5',
      name: 'Cilantro Bunch',
      category: ItemCategory.produce,
      location: StorageLocation.fridge,
      quantity: 1,
      unit: Unit.count,
      expiryDate: now.add(const Duration(days: 2)),
      status: ItemStatus.available,
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now,
    );
    // Consumed/Wasted examples for UI states
    _items['6'] = Item(
      id: '6',
      name: 'Sandwich',
      category: ItemCategory.pantry,
      location: StorageLocation.pantry,
      quantity: 1,
      unit: Unit.count,
      expiryDate: now.subtract(const Duration(days: 1)),
      status: ItemStatus.consumed,
      createdAt: now.subtract(const Duration(days: 4)),
      updatedAt: now,
    );
    _items['7'] = Item(
      id: '7',
      name: 'Spinach Bag',
      category: ItemCategory.produce,
      location: StorageLocation.fridge,
      quantity: 1,
      unit: Unit.count,
      expiryDate: now.subtract(const Duration(days: 2)),
      status: ItemStatus.wasted,
      wasteReason: WasteReason.spoiled,
      createdAt: now.subtract(const Duration(days: 5)),
      updatedAt: now,
    );
  }

  @override
  Future<void> init() async {
    // no-op for in-memory store
  }

  @override
  Future<List<Item>> getAllItems() async {
    return _items.values.toList();
  }

  @override
  Future<Item?> getItem(String id) async => _items[id];

  @override
  Future<void> saveItem(Item item) async {
    _items[item.id] = item;
  }

  @override
  Future<void> deleteItem(String id) async {
    _items.remove(id);
  }

  @override
  Future<void> clear() async => _items.clear();

  @override
  Future<void> close() async {
    // no-op
  }
}
