import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:zerospoils/data/repositories/hive_item_repository.dart';
import 'package:zerospoils/domain/models/item_model.dart';
import 'package:zerospoils/core/notifications/notification_service.dart';
import 'package:zerospoils/data/adapters/item_adapter.dart';

class MockNotificationService implements NotificationService {
  final List<Map<String, dynamic>> scheduledNotifications = [];
  final List<Map<String, dynamic>> rescheduledNotifications = [];
  final List<Map<String, dynamic>> cancelledNotifications = [];

  @override
  Future<void> scheduleForItem({
    required int itemId,
    required DateTime expiryDate,
    String? title,
    String? body,
  }) async {
    scheduledNotifications.add({
      'itemId': itemId,
      'expiryDate': expiryDate,
      'title': title,
      'body': body,
    });
  }

  @override
  Future<void> rescheduleForItem({
    required int itemId,
    required DateTime newExpiryDate,
    String? title,
    String? body,
  }) async {
    rescheduledNotifications.add({
      'itemId': itemId,
      'newExpiryDate': newExpiryDate,
      'title': title,
      'body': body,
    });
  }

  @override
  Future<void> cancelForItem(
    int itemId, {
    String reason = 'item_deleted',
  }) async {
    cancelledNotifications.add({'itemId': itemId, 'reason': reason});
  }

  // Stub methods not used in repository tests
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  late HiveItemRepository repository;
  late MockNotificationService mockNotificationService;
  late Directory tempDir;

  setUpAll(() async {
    // Create a temporary directory for Hive testing
    tempDir = await Directory.systemTemp.createTemp('hive_test');
    Hive.init(tempDir.path);

    // Register all Hive adapters with guards to avoid duplicate registration errors
    if (!Hive.isAdapterRegistered(ItemAdapter().typeId)) {
      Hive.registerAdapter(ItemAdapter());
    }
    if (!Hive.isAdapterRegistered(ItemCategoryAdapter().typeId)) {
      Hive.registerAdapter(ItemCategoryAdapter());
    }
    if (!Hive.isAdapterRegistered(ItemStatusAdapter().typeId)) {
      Hive.registerAdapter(ItemStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(StorageLocationAdapter().typeId)) {
      Hive.registerAdapter(StorageLocationAdapter());
    }
    if (!Hive.isAdapterRegistered(ItemTypeAdapter().typeId)) {
      Hive.registerAdapter(ItemTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(UnitAdapter().typeId)) {
      Hive.registerAdapter(UnitAdapter());
    }
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    mockNotificationService = MockNotificationService();
    repository = HiveItemRepository(
      notificationService: mockNotificationService,
    );
    await repository.init();
  });

  tearDown(() async {
    try {
      await repository.clear();
    } catch (e) {
      // Box may already be closed
    }
    mockNotificationService.scheduledNotifications.clear();
    mockNotificationService.rescheduledNotifications.clear();
    mockNotificationService.cancelledNotifications.clear();
  });

  group('HiveItemRepository - notification integration', () {
    test(
      'saveItem schedules notification for new item with expiry date',
      () async {
        final now = DateTime.now();
        final item = Item(
          id: '123',
          name: 'Milk',
          category: ItemCategory.dairy,
          expiryDate: DateTime(2026, 2, 15),
          location: StorageLocation.fridge,
          status: ItemStatus.available,
          createdAt: now,
          updatedAt: now,
        );

        await repository.saveItem(item);

        expect(mockNotificationService.scheduledNotifications.length, 1);
        expect(
          mockNotificationService.scheduledNotifications[0]['itemId'],
          123,
        );
        expect(
          mockNotificationService.scheduledNotifications[0]['expiryDate'],
          item.expiryDate,
        );
      },
    );

    test(
      'saveItem does not schedule notification for item without expiry',
      () async {
        final now = DateTime.now();
        final item = Item(
          id: '124',
          name: 'Salt',
          category: ItemCategory.pantry,
          location: StorageLocation.pantry,
          status: ItemStatus.available,
          createdAt: now,
          updatedAt: now,
        );

        await repository.saveItem(item);

        expect(mockNotificationService.scheduledNotifications.length, 0);
      },
    );

    test(
      'saveItem reschedules notification when expiry date changes',
      () async {
        final now = DateTime.now();
        final originalItem = Item(
          id: '125',
          name: 'Yogurt',
          category: ItemCategory.dairy,
          expiryDate: DateTime(2026, 2, 15),
          location: StorageLocation.fridge,
          status: ItemStatus.available,
          createdAt: now,
          updatedAt: now,
        );

        await repository.saveItem(originalItem);
        mockNotificationService.scheduledNotifications.clear();

        final updatedItem = originalItem.copyWith(
          expiryDate: DateTime(2026, 2, 20),
        );

        await repository.saveItem(updatedItem);

        expect(mockNotificationService.rescheduledNotifications.length, 1);
        expect(
          mockNotificationService.rescheduledNotifications[0]['itemId'],
          125,
        );
        expect(
          mockNotificationService.rescheduledNotifications[0]['newExpiryDate'],
          DateTime(2026, 2, 20),
        );
      },
    );

    test('saveItem cancels notification when expiry date is cleared', () async {
      final now = DateTime.now();
      final originalItem = Item(
        id: '126',
        name: 'Bread',
        category: ItemCategory.grains,
        expiryDate: DateTime(2026, 2, 10),
        location: StorageLocation.pantry,
        status: ItemStatus.available,
        createdAt: now,
        updatedAt: now,
      );

      await repository.saveItem(originalItem);
      mockNotificationService.scheduledNotifications.clear();

      // Create a new item without expiry date (can't use copyWith with null)
      final updatedItem = Item(
        id: '126',
        name: 'Bread',
        category: ItemCategory.grains,
        location: StorageLocation.pantry,
        status: ItemStatus.available,
        createdAt: now,
        updatedAt: now,
      );

      await repository.saveItem(updatedItem);

      expect(mockNotificationService.cancelledNotifications.length, 1);
      expect(mockNotificationService.cancelledNotifications[0]['itemId'], 126);
      expect(
        mockNotificationService.cancelledNotifications[0]['reason'],
        'expiry_cleared',
      );
    });

    test('deleteItem cancels scheduled notification', () async {
      final now = DateTime.now();
      final item = Item(
        id: '127',
        name: 'Eggs',
        category: ItemCategory.dairy,
        expiryDate: DateTime(2026, 2, 25),
        location: StorageLocation.fridge,
        status: ItemStatus.available,
        createdAt: now,
        updatedAt: now,
      );

      await repository.saveItem(item);
      mockNotificationService.scheduledNotifications.clear();

      await repository.deleteItem('127');

      expect(mockNotificationService.cancelledNotifications.length, 1);
      expect(mockNotificationService.cancelledNotifications[0]['itemId'], 127);
      expect(
        mockNotificationService.cancelledNotifications[0]['reason'],
        'item_deleted',
      );
    });

    test('clear cancels all scheduled notifications', () async {
      final now = DateTime.now();
      final items = [
        Item(
          id: '128',
          name: 'Item 1',
          category: ItemCategory.dairy,
          expiryDate: DateTime(2026, 2, 15),
          location: StorageLocation.fridge,
          status: ItemStatus.available,
          createdAt: now,
          updatedAt: now,
        ),
        Item(
          id: '129',
          name: 'Item 2',
          category: ItemCategory.dairy,
          expiryDate: DateTime(2026, 2, 20),
          location: StorageLocation.fridge,
          status: ItemStatus.available,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      for (final item in items) {
        await repository.saveItem(item);
      }
      mockNotificationService.scheduledNotifications.clear();

      await repository.clear();

      expect(mockNotificationService.cancelledNotifications.length, 2);
      expect(
        mockNotificationService.cancelledNotifications.any(
          (n) => n['itemId'] == 128,
        ),
        isTrue,
      );
      expect(
        mockNotificationService.cancelledNotifications.any(
          (n) => n['itemId'] == 129,
        ),
        isTrue,
      );
      expect(
        mockNotificationService.cancelledNotifications.every(
          (n) => n['reason'] == 'clear_all',
        ),
        isTrue,
      );
    });

    test('repository works without notification service (nullable)', () async {
      final repoWithoutNotifications = HiveItemRepository();
      await repoWithoutNotifications.init();

      final now = DateTime.now();
      final item = Item(
        id: '130',
        name: 'Salt',
        category: ItemCategory.pantry,
        expiryDate: DateTime(2026, 3, 1),
        location: StorageLocation.pantry,
        status: ItemStatus.available,
        createdAt: now,
        updatedAt: now,
      );

      // Should not throw even without notification service
      await repoWithoutNotifications.saveItem(item);
      await repoWithoutNotifications.deleteItem('130');

      // Don't close as it will close the shared Hive box
    });

    test('multiple edits to same item reschedule correctly', () async {
      final now = DateTime.now();
      final item = Item(
        id: '131',
        name: 'Cheese',
        category: ItemCategory.dairy,
        expiryDate: DateTime(2026, 2, 10),
        location: StorageLocation.fridge,
        status: ItemStatus.available,
        createdAt: now,
        updatedAt: now,
      );

      await repository.saveItem(item);
      mockNotificationService.scheduledNotifications.clear();

      // First edit
      await repository.saveItem(
        item.copyWith(expiryDate: DateTime(2026, 2, 15)),
      );
      // Second edit
      await repository.saveItem(
        item.copyWith(expiryDate: DateTime(2026, 2, 20)),
      );
      // Third edit
      await repository.saveItem(
        item.copyWith(expiryDate: DateTime(2026, 2, 25)),
      );

      expect(mockNotificationService.rescheduledNotifications.length, 3);
    });
  });
}
