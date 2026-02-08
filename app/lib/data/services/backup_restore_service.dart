library;

/// Backup and restore service for local data export/import
/// Handles JSON serialization with schema versioning and migration support
///
/// See: planning/milestones/M2/165-backup-restore-local-json-in-settings.md

import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerospoils/domain/models/item_model.dart';

/// Backup metadata
class BackupMetadata {
  final String backupVersion;
  final String schemaVersion;
  final String appVersion;
  final DateTime exportedAt;
  final int itemCount;
  final int categoryCount;
  final int batchCount;

  BackupMetadata({
    required this.backupVersion,
    required this.schemaVersion,
    required this.appVersion,
    required this.exportedAt,
    required this.itemCount,
    this.categoryCount = 0,
    this.batchCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'backup_version': backupVersion,
    'schema_version': schemaVersion,
    'app_version': appVersion,
    'exported_at': exportedAt.toIso8601String(),
    'item_count': itemCount,
    'category_count': categoryCount,
    'batch_count': batchCount,
  };

  factory BackupMetadata.fromJson(Map<String, dynamic> json) {
    return BackupMetadata(
      backupVersion: json['backup_version'] as String,
      schemaVersion: json['schema_version'] as String,
      appVersion: json['app_version'] as String,
      exportedAt: DateTime.parse(json['exported_at'] as String),
      itemCount: json['item_count'] as int,
      categoryCount: json['category_count'] as int? ?? 0,
      batchCount: json['batch_count'] as int? ?? 0,
    );
  }
}

/// Restore preview summary
class RestorePreview {
  final int itemCount;
  final int categoryCount;
  final int batchCount;
  final String schemaVersionFrom;
  final String appVersionFrom;
  final bool requiresMigration;

  RestorePreview({
    required this.itemCount,
    required this.categoryCount,
    required this.batchCount,
    required this.schemaVersionFrom,
    required this.appVersionFrom,
    required this.requiresMigration,
  });
}

/// Backup restore result
class RestoreResult {
  final bool success;
  final String? error;
  final int itemsImported;
  final int migrationsApplied;

  RestoreResult({
    required this.success,
    this.error,
    this.itemsImported = 0,
    this.migrationsApplied = 0,
  });
}

/// Backup result
class BackupResult {
  final bool success;
  final String filePath;
  final int sizeBytes;
  final BackupMetadata? metadata;
  final String? error;

  BackupResult({
    required this.success,
    required this.filePath,
    required this.sizeBytes,
    this.metadata,
    this.error,
  });
}

/// Backup and restore service
class BackupRestoreService {
  static const String _currentSchemaVersion = '1.0.0';
  static const String _backupVersion = '1.0';

  final HiveInterface _hive;
  final dynamic telemetry; // Dynamic to avoid import cycle

  BackupRestoreService({HiveInterface? hive, this.telemetry})
    : _hive = hive ?? Hive;

  /// Get current app version from package info (fallback: '1.0.0')
  Future<String> _getAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (_) {
      return '1.0.0'; // Fallback for tests or error cases
    }
  }

  /// Export all data to JSON file
  Future<BackupResult> exportToJson(String filePath) async {
    telemetry?.trackBackupStarted();

    final itemsBox = _hive.box<Item>('items');
    final items = itemsBox.values.toList();
    final appVersion = await _getAppVersion();

    final metadata = BackupMetadata(
      backupVersion: _backupVersion,
      schemaVersion: _currentSchemaVersion,
      appVersion: appVersion,
      exportedAt: DateTime.now(),
      itemCount: items.length,
    );

    final settings = await _readSettings();

    final backup = {
      'metadata': metadata.toJson(),
      'data': {
        'items': items.map((item) => _serializeItem(item)).toList(),
        'categories': [],
        'locations': [],
        'batches': [],
        'events': [],
        'attachments': [],
        'settings': settings,
      },
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(backup);
    final file = File(filePath);
    await file.writeAsString(jsonString);
    final sizeBytes = await file.length();

    telemetry?.trackBackupSucceeded(
      sizeBytes: sizeBytes,
      itemCount: metadata.itemCount,
      appVersion: metadata.appVersion,
    );

    return BackupResult(
      success: true,
      filePath: filePath,
      sizeBytes: sizeBytes,
      metadata: metadata,
    );
  }

  /// Parse and validate backup file (dry-run)
  Future<RestorePreview> previewRestore(String filePath) async {
    final file = File(filePath);
    final jsonString = await file.readAsString();
    final backup = jsonDecode(jsonString) as Map<String, dynamic>;

    // Validate backup structure
    if (!backup.containsKey('metadata') || !backup.containsKey('data')) {
      throw Exception('Invalid backup format: missing metadata or data');
    }

    final metadata = BackupMetadata.fromJson(
      backup['metadata'] as Map<String, dynamic>,
    );

    // Check version compatibility
    final requiresMigration = _requiresMigration(metadata.schemaVersion);
    if (_isBackwardIncompatible(metadata.schemaVersion)) {
      throw Exception(
        'This backup was created with app version ${metadata.appVersion}. '
        'Please update the app to restore.',
      );
    }

    final data = backup['data'] as Map<String, dynamic>;
    final items = (data['items'] as List?) ?? [];

    return RestorePreview(
      itemCount: items.length,
      categoryCount: metadata.categoryCount,
      batchCount: metadata.batchCount,
      schemaVersionFrom: metadata.schemaVersion,
      appVersionFrom: metadata.appVersion,
      requiresMigration: requiresMigration,
    );
  }

  /// Import data from JSON file with rollback on error
  Future<RestoreResult> importFromJson(String filePath) async {
    final file = File(filePath);
    final jsonString = await file.readAsString();
    final backup = jsonDecode(jsonString) as Map<String, dynamic>;

    // Validate structure
    if (!backup.containsKey('metadata') || !backup.containsKey('data')) {
      return RestoreResult(
        success: false,
        error: 'Invalid backup format: missing metadata or data',
      );
    }

    final metadata = BackupMetadata.fromJson(
      backup['metadata'] as Map<String, dynamic>,
    );

    // Check version compatibility
    if (_isBackwardIncompatible(metadata.schemaVersion)) {
      telemetry?.trackRestoreFailed(
        reason:
            'Backward incompatible schema version: ${metadata.schemaVersion}',
        schemaMismatch: true,
      );
      return RestoreResult(
        success: false,
        error:
            'Backup from ${metadata.appVersion} not compatible. '
            'Please update the app.',
      );
    }

    telemetry?.trackRestoreStarted(
      schemaVersion: metadata.schemaVersion,
      appVersion: metadata.appVersion,
    );

    final itemsBox = _hive.box<Item>('items');

    // Backup existing settings for rollback
    final existingSettings = await _readSettings();

    // Backup existing data for rollback
    final existingItems = itemsBox.values.toList();
    final existingKeys = itemsBox.keys.toList();

    try {
      // Clear existing data
      await itemsBox.clear();

      // Import items
      final data = backup['data'] as Map<String, dynamic>;
      final itemsData = (data['items'] as List?) ?? [];
      final settingsData = data['settings'] as Map<String, dynamic>?;

      int migrationsApplied = 0;
      if (_requiresMigration(metadata.schemaVersion)) {
        migrationsApplied = await _applyMigrations(
          itemsData,
          metadata.schemaVersion,
        );
      }

      // Deserialize and store items
      for (final itemData in itemsData) {
        final item = _deserializeItem(itemData as Map<String, dynamic>);
        await itemsBox.put(item.id, item);
      }

      if (settingsData != null) {
        await _writeSettings(settingsData);
      }

      telemetry?.trackRestoreSucceeded(
        itemCountImported: itemsData.length,
        migrationsApplied: migrationsApplied,
        schemaVersionFrom: metadata.schemaVersion,
        appVersionFrom: metadata.appVersion,
      );

      return RestoreResult(
        success: true,
        itemsImported: itemsData.length,
        migrationsApplied: migrationsApplied,
      );
    } catch (e) {
      telemetry?.trackRestoreFailed(
        reason: e.toString(),
        schemaMismatch: false,
      );

      // Rollback on error: restore original data
      await itemsBox.clear();
      for (var i = 0; i < existingItems.length; i++) {
        await itemsBox.put(existingKeys[i], existingItems[i]);
      }
      await _writeSettings(existingSettings);

      return RestoreResult(
        success: false,
        error: 'Restore failed: ${e.toString()}',
      );
    }
  }

  /// Check if migration is required
  bool _requiresMigration(String backupSchemaVersion) {
    return backupSchemaVersion != _currentSchemaVersion;
  }

  /// Apply schema migrations to backup data if needed
  ///
  /// This method handles backward-compatible migrations when restoring backups
  /// from older app versions. Future migration strategy:
  ///
  /// Example structure for M3+:
  /// ```
  /// // Registry of versioned migrations
  /// final _migrations = {
  ///   '1.0.0-to-1.1.0': (List<dynamic> items) => {
  ///     // Transform item structure: add new fields with defaults
  ///     ...items.map((i) => {
  ///       ...i as Map<String, dynamic>,
  ///       'new_field': 'default_value',
  ///     }).toList()
  ///   },
  ///   '1.1.0-to-1.2.0': (List<dynamic> items) => {
  ///     // Complex transformation: e.g., split fields, rename keys
  ///   },
  /// };
  ///
  /// // Apply all migrations between backup version and current
  /// for (final migration in _migrations.entries) {
  ///   final [fromVersion, toVersion] = migration.key.split('-to-');
  ///   if (backupVersion >= fromVersion && backupVersion < toVersion) {
  ///     itemsData = await migration.value(itemsData);
  ///   }
  /// }
  /// ```
  ///
  /// TODO (M3+): Implement migration registry with test coverage for:
  /// - Field additions (add defaults for new required fields)
  /// - Field removals (strip obsolete data)
  /// - Type changes (int -> String conversions)
  /// - Structural transformations (denormalization for local-first)
  /// - Multi-entity migrations when categories/locations/batches/events/attachments added
  ///
  /// Currently: No-op (forward-only, no transformations)

  /// Check if backup is from newer version (backward incompatible)
  bool _isBackwardIncompatible(String backupSchemaVersion) {
    // Parse semantic versions
    final backupParts = backupSchemaVersion.split('.').map(int.parse).toList();
    final currentParts = _currentSchemaVersion
        .split('.')
        .map(int.parse)
        .toList();

    // Major version mismatch or newer minor version = incompatible
    return backupParts[0] > currentParts[0] ||
        (backupParts[0] == currentParts[0] && backupParts[1] > currentParts[1]);
  }

  /// Apply migrations to imported data
  Future<int> _applyMigrations(
    List<dynamic> itemsData,
    String fromVersion,
  ) async {
    // TODO: Implement actual migration logic
    // For now, just track that migration would occur
    return 0;
  }

  /// Serialize Item to JSON
  Map<String, dynamic> _serializeItem(Item item) {
    return {
      'id': item.id,
      'name': item.name,
      'category': item.category.name,
      'type': item.type.name,
      'prepared_date': item.preparedDate?.toIso8601String(),
      'location': item.location.name,
      'quantity': item.quantity,
      'unit': item.unit.name,
      'expiry_date': item.expiryDate?.toIso8601String(),
      'purchase_price': item.purchasePrice,
      'status': item.status.name,
      'waste_reason': item.wasteReason?.name,
      'created_at': item.createdAt.toIso8601String(),
      'updated_at': item.updatedAt.toIso8601String(),
    };
  }

  /// Deserialize JSON to Item
  Item _deserializeItem(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as String,
      name: json['name'] as String,
      category: ItemCategory.fromString(json['category'] as String),
      type: json['type'] != null
          ? ItemType.fromString(json['type'] as String)
          : ItemType.raw,
      preparedDate: json['prepared_date'] != null
          ? DateTime.parse(json['prepared_date'] as String)
          : null,
      location: StorageLocation.fromString(json['location'] as String),
      quantity: json['quantity'] as int,
      unit: Unit.fromString(json['unit'] as String),
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : null,
      purchasePrice: (json['purchase_price'] as num?)?.toDouble(),
      status: ItemStatus.fromString(json['status'] as String),
      wasteReason: json['waste_reason'] != null
          ? WasteReason.fromString(json['waste_reason'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Future<Map<String, dynamic>> _readSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'notifications_enabled': prefs.getBool('notifications_enabled') ?? true,
      'sound_enabled': prefs.getBool('sound_enabled') ?? true,
      'vibration_enabled': prefs.getBool('vibration_enabled') ?? true,
      'dark_mode_enabled': prefs.getBool('dark_mode_enabled') ?? false,
      'meal_planning_enabled': prefs.getBool('meal_planning_enabled') ?? false,
      'data_sync_enabled': prefs.getBool('data_sync_enabled') ?? false,
      'expiry_lead_time_days': prefs.getInt('expiry_lead_time_days') ?? 3,
      'date_format': prefs.getString('date_format') ?? 'MM/DD/YYYY',
      'demo_mode_enabled': prefs.getBool('demo_mode_enabled') ?? true,
    };
  }

  Future<void> _writeSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();

    if (settings.containsKey('notifications_enabled')) {
      await prefs.setBool(
        'notifications_enabled',
        settings['notifications_enabled'] as bool,
      );
    }
    if (settings.containsKey('sound_enabled')) {
      await prefs.setBool('sound_enabled', settings['sound_enabled'] as bool);
    }
    if (settings.containsKey('vibration_enabled')) {
      await prefs.setBool(
        'vibration_enabled',
        settings['vibration_enabled'] as bool,
      );
    }
    if (settings.containsKey('dark_mode_enabled')) {
      await prefs.setBool(
        'dark_mode_enabled',
        settings['dark_mode_enabled'] as bool,
      );
    }
    if (settings.containsKey('meal_planning_enabled')) {
      await prefs.setBool(
        'meal_planning_enabled',
        settings['meal_planning_enabled'] as bool,
      );
    }
    if (settings.containsKey('data_sync_enabled')) {
      await prefs.setBool(
        'data_sync_enabled',
        settings['data_sync_enabled'] as bool,
      );
    }
    if (settings.containsKey('expiry_lead_time_days')) {
      await prefs.setInt(
        'expiry_lead_time_days',
        settings['expiry_lead_time_days'] as int,
      );
    }
    if (settings.containsKey('date_format')) {
      await prefs.setString('date_format', settings['date_format'] as String);
    }
    if (settings.containsKey('demo_mode_enabled')) {
      await prefs.setBool(
        'demo_mode_enabled',
        settings['demo_mode_enabled'] as bool,
      );
    }
  }
}
