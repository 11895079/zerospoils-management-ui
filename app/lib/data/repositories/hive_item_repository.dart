library;

/// Hive-based implementation of Item repository
/// Provides local persistent storage for inventory items

import 'package:hive/hive.dart';
import '../../domain/models/item_model.dart';
import '../../core/notifications/notification_service.dart';
import 'item_repository_base.dart';

class HiveItemRepository implements ItemRepositoryBase {
  static const String _boxName = 'items';
  final HiveInterface _hive;
  final NotificationService? _notificationService;
  Box<Item>? _box;

  HiveItemRepository({
    HiveInterface? hive,
    NotificationService? notificationService,
  }) : _hive = hive ?? Hive,
       _notificationService = notificationService;

  /// Check if repository is initialized
  bool get isInitialized => _box != null && _box!.isOpen;

  /// Initialize Hive and open items box
  @override
  Future<void> init() async {
    if (_box != null && _box!.isOpen) return;

    if (!_hive.isBoxOpen(_boxName)) {
      _box = await _hive.openBox<Item>(_boxName);
    } else {
      _box = _hive.box<Item>(_boxName);
    }
  }

  /// Get all items
  @override
  Future<List<Item>> getAllItems() async {
    if (_box == null) throw Exception('Repository not initialized');
    return _box!.values.toList();
  }

  /// Get item by ID
  @override
  Future<Item?> getItem(String id) async {
    if (_box == null) throw Exception('Repository not initialized');
    return _box!.get(id);
  }

  /// Add or update item
  @override
  Future<void> saveItem(Item item) async {
    if (_box == null) throw Exception('Repository not initialized');

    // Determine if this is a new item or an update
    final existingItem = _box!.get(item.id);
    final isNewItem = existingItem == null;

    // Persist to Hive
    await _box!.put(item.id, item);

    // Handle notification scheduling
    if (_notificationService != null) {
      final notificationId = _parseItemId(item.id);
      if (notificationId != null) {
        if (isNewItem && item.expiryDate != null) {
          // New item with expiry: schedule notification
          await _notificationService.scheduleForItem(
            itemId: notificationId,
            expiryDate: item.expiryDate!,
            title: 'Item expiring soon',
            body: '${item.name} expires tomorrow',
          );
        } else if (!isNewItem && existingItem.expiryDate != item.expiryDate) {
          // Expiry date changed: reschedule notification
          if (item.expiryDate != null) {
            await _notificationService.rescheduleForItem(
              itemId: notificationId,
              newExpiryDate: item.expiryDate!,
              title: 'Item expiring soon',
              body: '${item.name} expires tomorrow',
            );
          } else {
            // Expiry date cleared: cancel notification
            await _notificationService.cancelForItem(
              notificationId,
              reason: 'expiry_cleared',
            );
          }
        }
      }
    }
  }

  /// Delete item
  @override
  Future<void> deleteItem(String id) async {
    if (_box == null) throw Exception('Repository not initialized');

    // Cancel any scheduled notification
    if (_notificationService != null) {
      final notificationId = _parseItemId(id);
      if (notificationId != null) {
        await _notificationService.cancelForItem(
          notificationId,
          reason: 'item_deleted',
        );
      }
    }

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
  @override
  Future<void> clear() async {
    if (_box == null) throw Exception('Repository not initialized');

    // Cancel all scheduled notifications
    if (_notificationService != null) {
      for (final item in _box!.values) {
        final notificationId = _parseItemId(item.id);
        if (notificationId != null) {
          await _notificationService.cancelForItem(
            notificationId,
            reason: 'clear_all',
          );
        }
      }
    }

    await _box!.clear();
  }

  /// Close box
  @override
  Future<void> close() async {
    await _box?.close();
  }

  /// Parse item ID to notification ID safely
  /// Returns null if ID is not numeric (for non-numeric IDs, notifications are skipped)
  int? _parseItemId(String id) {
    try {
      return int.parse(id);
    } catch (e) {
      // Silently skip notifications for non-numeric IDs
      return null;
    }
  }
}
