library;

/// Hive-based implementation of Item repository
/// Provides local persistent storage for inventory items

import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/models/item_model.dart';

class HiveItemRepository {
  static const String _boxName = 'items';
  Box<Item>? _box;

  /// Initialize Hive and open items box
  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<Item>(_boxName);
  }

  /// Get all items
  Future<List<Item>> getAllItems() async {
    if (_box == null) throw Exception('Repository not initialized');
    return _box!.values.toList();
  }

  /// Get item by ID
  Future<Item?> getItem(String id) async {
    if (_box == null) throw Exception('Repository not initialized');
    return _box!.get(id);
  }

  /// Add or update item
  Future<void> saveItem(Item item) async {
    if (_box == null) throw Exception('Repository not initialized');
    await _box!.put(item.id, item);
  }

  /// Delete item
  Future<void> deleteItem(String id) async {
    if (_box == null) throw Exception('Repository not initialized');
    await _box!.delete(id);
  }

  /// Get items by category
  Future<List<Item>> getItemsByCategory(ItemCategory category) async {
    if (_box == null) throw Exception('Repository not initialized');
    return _box!.values.where((item) => item.category == category).toList();
  }

  /// Get items expiring soon (within days)
  Future<List<Item>> getItemsExpiringSoon(int days) async {
    if (_box == null) throw Exception('Repository not initialized');
    final now = DateTime.now();
    return _box!.values.where((item) {
      if (item.expiryDate == null) return false;
      final daysUntil = item.expiryDate!.difference(now).inDays;
      return daysUntil >= 0 && daysUntil <= days;
    }).toList();
  }

  /// Clear all items (for testing)
  Future<void> clear() async {
    if (_box == null) throw Exception('Repository not initialized');
    await _box!.clear();
  }

  /// Close box
  Future<void> close() async {
    await _box?.close();
  }
}
