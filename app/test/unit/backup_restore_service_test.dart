library;

/// Unit tests for BackupRestoreService
/// Covers: export, import, preview, versioning, migration, rollback

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerospoils/data/services/backup_restore_service.dart';
import 'package:zerospoils/domain/models/item_model.dart';
import 'package:zerospoils/data/adapters/item_adapter.dart';
import 'package:zerospoils/domain/models/user_category.dart';

void main() {
  late Directory tempDir;
  late HiveInterface hive;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('zerospoils_test_');
    hive = Hive;
    Hive.init(tempDir.path);

    SharedPreferences.setMockInitialValues({});

    // Register Hive adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ItemAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ItemCategoryAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(StorageLocationAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ItemStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(WasteReasonAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(ItemTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(UnitAdapter());
    }
    if (!Hive.isAdapterRegistered(22)) {
      Hive.registerAdapter(UserCategoryAdapter());
    }
  });

  tearDown(() async {
    await hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('BackupRestoreService - Export', () {
    test('export produces valid JSON with metadata header', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', false);
      await prefs.setInt('expiry_lead_time_days', 7);
      await prefs.setString('date_format', 'YYYY-MM-DD');

      final itemsBox = await hive.openBox<Item>('items');
      final categoriesBox = await hive.openBox<UserCategory>('user_categories');

      // Add test items
      final item1 = Item(
        id: 'item-1',
        name: 'Milk',
        category: ItemCategory.other,
        customCategoryId: 'cat-1',
        customCategoryName: 'School Snacks',
        location: StorageLocation.fridge,
        quantity: 1,
        unit: Unit.liter,
        status: ItemStatus.available,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await itemsBox.put(item1.id, item1);

      await categoriesBox.put(
        'cat-1',
        UserCategory(
          id: 'cat-1',
          name: 'School Snacks',
          createdAt: DateTime.now(),
        ),
      );

      final service = BackupRestoreService(hive: hive);
      final exportPath = '${tempDir.path}/backup.json';

      final result = await service.exportToJson(exportPath);

      // Verify file exists and size > 0
      final file = File(exportPath);
      expect(file.existsSync(), true);
      expect(result.sizeBytes > 0, true);

      // Verify JSON structure
      final jsonString = await file.readAsString();
      final backup = jsonDecode(jsonString) as Map<String, dynamic>;

      expect(backup.containsKey('metadata'), true);
      expect(backup.containsKey('data'), true);

      final metadata = backup['metadata'] as Map<String, dynamic>;
      expect(metadata['backup_version'], '1.0');
      expect(metadata['schema_version'], '1.0.0');
      expect(metadata['item_count'], 1);
      expect(metadata['category_count'], 1);

      final data = backup['data'] as Map<String, dynamic>;
      final items = data['items'] as List;
      expect(items.length, 1);
      expect(items[0]['id'], 'item-1');
      expect(items[0]['name'], 'Milk');
      expect(items[0]['custom_category_id'], 'cat-1');
      expect(items[0]['custom_category_name'], 'School Snacks');
      expect(data['categories'], isA<List>());
      expect((data['categories'] as List).length, 1);
      expect((data['categories'] as List).first['name'], 'School Snacks');
      expect(data['settings'], isA<Map<String, dynamic>>());
      expect(data['settings']['notifications_enabled'], false);
      expect(data['settings']['expiry_lead_time_days'], 7);
      expect(data['settings']['date_format'], 'YYYY-MM-DD');
    });

    test('export handles empty database', () async {
      await hive.openBox<Item>('items');
      await hive.openBox<UserCategory>('user_categories');

      final service = BackupRestoreService(hive: hive);
      final exportPath = '${tempDir.path}/empty_backup.json';

      await service.exportToJson(exportPath);

      final file = File(exportPath);
      final jsonString = await file.readAsString();
      final backup = jsonDecode(jsonString) as Map<String, dynamic>;

      final metadata = backup['metadata'] as Map<String, dynamic>;
      expect(metadata['item_count'], 0);
    });
  });

  group('BackupRestoreService - Preview', () {
    test('preview shows correct item counts', () async {
      await hive.openBox<Item>('items');
      await hive.openBox<UserCategory>('user_categories');

      // Create backup file
      final backupData = {
        'metadata': {
          'backup_version': '1.0',
          'schema_version': '1.0.0',
          'app_version': '1.0.0',
          'exported_at': DateTime.now().toIso8601String(),
          'item_count': 2,
          'category_count': 1,
          'batch_count': 0,
        },
        'data': {
          'items': [
            {
              'id': 'item-1',
              'name': 'Milk',
              'category': 'dairy',
              'location': 'fridge',
              'quantity': 1,
              'unit': 'liter',
              'status': 'available',
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            },
            {
              'id': 'item-2',
              'name': 'Bread',
              'category': 'grains',
              'location': 'pantry',
              'quantity': 1,
              'unit': 'count',
              'status': 'available',
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            },
          ],
          'categories': [
            {
              'id': 'cat-1',
              'name': 'School Snacks',
              'created_at': DateTime.now().toIso8601String(),
            },
          ],
        },
      };

      final backupPath = '${tempDir.path}/preview_backup.json';
      await File(backupPath).writeAsString(jsonEncode(backupData));

      final service = BackupRestoreService(hive: hive);
      final preview = await service.previewRestore(backupPath);

      expect(preview.itemCount, 2);
      expect(preview.categoryCount, 1);
      expect(preview.schemaVersionFrom, '1.0.0');
      expect(preview.requiresMigration, false);
    });

    test(
      'preview detects version mismatch for backward incompatibility',
      () async {
        await hive.openBox<Item>('items');
        await hive.openBox<UserCategory>('user_categories');

        // Backup from future version (1.1.0)
        final backupData = {
          'metadata': {
            'backup_version': '1.0',
            'schema_version': '1.1.0',
            'app_version': '1.1.0',
            'exported_at': DateTime.now().toIso8601String(),
            'item_count': 1,
            'category_count': 0,
            'batch_count': 0,
          },
          'data': {'items': []},
        };

        final backupPath = '${tempDir.path}/future_backup.json';
        await File(backupPath).writeAsString(jsonEncode(backupData));

        final service = BackupRestoreService(hive: hive);

        expect(
          () => service.previewRestore(backupPath),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Please update the app'),
            ),
          ),
        );
      },
    );
  });

  group('BackupRestoreService - Import', () {
    test('import restores data correctly', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', true);

      final itemsBox = await hive.openBox<Item>('items');
      final categoriesBox = await hive.openBox<UserCategory>('user_categories');

      // Create backup file
      final backupData = {
        'metadata': {
          'backup_version': '1.0',
          'schema_version': '1.0.0',
          'app_version': '1.0.0',
          'exported_at': DateTime.now().toIso8601String(),
          'item_count': 1,
          'category_count': 1,
          'batch_count': 0,
        },
        'data': {
          'items': [
            {
              'id': 'item-1',
              'name': 'Milk',
              'category': 'other',
              'custom_category_id': 'cat-1',
              'custom_category_name': 'School Snacks',
              'location': 'fridge',
              'quantity': 1,
              'unit': 'liter',
              'status': 'available',
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            },
          ],
          'categories': [
            {
              'id': 'cat-1',
              'name': 'School Snacks',
              'created_at': DateTime.now().toIso8601String(),
            },
          ],
          'settings': {
            'notifications_enabled': false,
            'expiry_lead_time_days': 5,
          },
        },
      };

      final backupPath = '${tempDir.path}/restore_backup.json';
      await File(backupPath).writeAsString(jsonEncode(backupData));

      final service = BackupRestoreService(hive: hive);
      final result = await service.importFromJson(backupPath);

      expect(result.success, true);
      expect(result.itemsImported, 1);
      expect(result.error, isNull);

      // Verify data restored
      final items = itemsBox.values.toList();
      expect(items.length, 1);
      expect(items[0].id, 'item-1');
      expect(items[0].name, 'Milk');
      expect(items[0].customCategoryId, 'cat-1');
      expect(items[0].customCategoryName, 'School Snacks');

      final categories = categoriesBox.values.toList();
      expect(categories.length, 1);
      expect(categories.first.name, 'School Snacks');

      final updatedPrefs = await SharedPreferences.getInstance();
      expect(updatedPrefs.getBool('notifications_enabled'), false);
      expect(updatedPrefs.getInt('expiry_lead_time_days'), 5);
    });

    test('import rejects backward incompatible backup', () async {
      await hive.openBox<Item>('items');
      await hive.openBox<UserCategory>('user_categories');

      // Backup from future version
      final backupData = {
        'metadata': {
          'backup_version': '1.0',
          'schema_version': '2.0.0',
          'app_version': '2.0.0',
          'exported_at': DateTime.now().toIso8601String(),
          'item_count': 0,
          'category_count': 0,
          'batch_count': 0,
        },
        'data': {'items': []},
      };

      final backupPath = '${tempDir.path}/incompatible_backup.json';
      await File(backupPath).writeAsString(jsonEncode(backupData));

      final service = BackupRestoreService(hive: hive);
      final result = await service.importFromJson(backupPath);

      expect(result.success, false);
      expect(result.error, contains('not compatible'));
    });

    test('import rolls back on error', () async {
      final itemsBox = await hive.openBox<Item>('items');
      await hive.openBox<UserCategory>('user_categories');

      // Add existing item
      final existingItem = Item(
        id: 'existing-1',
        name: 'Existing Item',
        category: ItemCategory.pantry,
        location: StorageLocation.pantry,
        quantity: 1,
        unit: Unit.count,
        status: ItemStatus.available,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await itemsBox.put(existingItem.id, existingItem);

      // Create invalid backup (missing required fields)
      final backupData = {
        'metadata': {
          'backup_version': '1.0',
          'schema_version': '1.0.0',
          'app_version': '1.0.0',
          'exported_at': DateTime.now().toIso8601String(),
          'item_count': 1,
          'category_count': 0,
          'batch_count': 0,
        },
        'data': {
          'items': [
            {
              'id': 'item-1',
              // Missing required fields - will cause error
            },
          ],
        },
      };

      final backupPath = '${tempDir.path}/invalid_backup.json';
      await File(backupPath).writeAsString(jsonEncode(backupData));

      final service = BackupRestoreService(hive: hive);
      final result = await service.importFromJson(backupPath);

      expect(result.success, false);

      // Verify rollback: existing item still present
      final items = itemsBox.values.toList();
      expect(items.length, 1);
      expect(items[0].id, 'existing-1');
    });
  });

  group('BackupRestoreService - Round Trip', () {
    test('export then import preserves all data', () async {
      final itemsBox = await hive.openBox<Item>('items');
      final categoriesBox = await hive.openBox<UserCategory>('user_categories');

      await categoriesBox.put(
        'cat-1',
        UserCategory(
          id: 'cat-1',
          name: 'School Snacks',
          createdAt: DateTime.now(),
        ),
      );

      // Add multiple items with various fields
      final items = [
        Item(
          id: 'item-1',
          name: 'Milk',
          category: ItemCategory.other,
          customCategoryId: 'cat-1',
          customCategoryName: 'School Snacks',
          location: StorageLocation.fridge,
          quantity: 2,
          unit: Unit.liter,
          purchasePrice: 4.99,
          expiryDate: DateTime.now().add(const Duration(days: 7)),
          status: ItemStatus.available,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Item(
          id: 'item-2',
          name: 'Bread',
          category: ItemCategory.grains,
          location: StorageLocation.pantry,
          quantity: 1,
          unit: Unit.count,
          status: ItemStatus.available,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      for (final item in items) {
        await itemsBox.put(item.id, item);
      }

      // Export
      final service = BackupRestoreService(hive: hive);
      final exportPath = '${tempDir.path}/roundtrip.json';
      await service.exportToJson(exportPath);

      // Clear database
      await itemsBox.clear();
      expect(itemsBox.values.toList().length, 0);

      // Import
      final result = await service.importFromJson(exportPath);

      expect(result.success, true);
      expect(result.itemsImported, 2);

      // Verify all data restored
      final restoredItems = itemsBox.values.toList();
      expect(restoredItems.length, 2);

      final restoredMilk = restoredItems.firstWhere((i) => i.id == 'item-1');
      expect(restoredMilk.name, 'Milk');
      expect(restoredMilk.quantity, 2);
      expect(restoredMilk.purchasePrice, 4.99);
      expect(restoredMilk.expiryDate, isNotNull);
      expect(restoredMilk.customCategoryId, 'cat-1');
      expect(restoredMilk.customCategoryName, 'School Snacks');
    });
  });

  group('BackupRestoreService - CSV Export', () {
    test('export to CSV generates human-readable format', () async {
      final itemsBox = await hive.openBox<Item>('items');

      // Add test item
      final item = Item(
        id: 'item-1',
        name: 'Milk',
        category: ItemCategory.dairy,
        location: StorageLocation.fridge,
        quantity: 2,
        unit: Unit.liter,
        purchasePrice: 4.99,
        expiryDate: DateTime(2026, 3, 15),
        status: ItemStatus.available,
        createdAt: DateTime(2026, 2, 15, 10, 0),
        updatedAt: DateTime(2026, 2, 15, 10, 0),
      );
      await itemsBox.put(item.id, item);

      final service = BackupRestoreService(hive: hive);
      final exportPath = '${tempDir.path}/export.csv';

      final result = await service.exportToCsv(exportPath);

      expect(result.success, true);
      expect(result.filePath, exportPath);
      expect(result.sizeBytes, greaterThan(0));
      expect(result.metadata?.itemCount, 1);

      // Verify CSV content
      final csv = await File(exportPath).readAsString();
      expect(csv.contains('ID,Name,Category'), true);
      expect(csv.contains('item-1'), true);
      expect(csv.contains('Milk'), true);
      expect(csv.contains('Dairy'), true);
      expect(csv.contains('2026-03-15'), true);
      expect(csv.contains('fridge'), true);
    });

    test('CSV export handles empty database', () async {
      final service = BackupRestoreService(hive: hive);
      final exportPath = '${tempDir.path}/empty.csv';

      final result = await service.exportToCsv(exportPath);

      expect(result.success, true);
      expect(result.metadata?.itemCount, 0);

      final csv = await File(exportPath).readAsString();
      expect(csv.contains('ID,Name,Category'), true);
      // Should only have header, no data rows
      expect(csv.split('\n').length, 2); // Header + empty line
    });

    test('CSV export escapes special characters', () async {
      final itemsBox = await hive.openBox<Item>('items');

      final item = Item(
        id: 'item-1',
        name: 'Milk "Premium"',
        category: ItemCategory.dairy,
        customCategoryName: 'Store, Fridge',
        location: StorageLocation.fridge,
        status: ItemStatus.available,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await itemsBox.put(item.id, item);

      final service = BackupRestoreService(hive: hive);
      final exportPath = '${tempDir.path}/special.csv';

      final result = await service.exportToCsv(exportPath);
      expect(result.success, true);

      final csv = await File(exportPath).readAsString();
      // Name with quotes should be escaped
      expect(csv.contains('"Milk ""Premium"""'), true);
      // Category with comma should be quoted
      expect(csv.contains('"Store, Fridge"'), true);
    });
  });

  group('BackupRestoreService - Clear Data', () {
    test('clearAllData wipes all database and settings', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', true);
      await prefs.setInt('expiry_lead_time_days', 3);

      final itemsBox = await hive.openBox<Item>('items');
      final categoriesBox = await hive.openBox<UserCategory>('user_categories');

      final item = Item(
        id: 'item-1',
        name: 'Test Item',
        category: ItemCategory.other,
        location: StorageLocation.other,
        status: ItemStatus.available,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await itemsBox.put(item.id, item);

      final category = UserCategory(
        id: 'cat-1',
        name: 'Test',
        createdAt: DateTime.now(),
      );
      await categoriesBox.put(category.id, category);

      // Verify data exists
      expect(itemsBox.length, 1);
      expect(categoriesBox.length, 1);
      expect(prefs.getBool('notifications_enabled'), true);

      final service = BackupRestoreService(hive: hive);
      await service.clearAllData(userTier: 'free', itemCount: 1);

      // Verify all data cleared
      expect(itemsBox.length, 0);
      expect(categoriesBox.length, 0);
      expect(prefs.getBool('notifications_enabled'), null);
      expect(prefs.getInt('expiry_lead_time_days'), null);
    });
  });
}
