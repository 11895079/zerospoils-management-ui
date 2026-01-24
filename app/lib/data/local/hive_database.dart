library;

/// Local storage database service with migration support
/// Handles Hive initialization and schema version management

import 'package:hive/hive.dart';
import 'package:zerospoils/domain/models/item_model.dart';

/// Migration result
class MigrationResult {
  final int fromVersion;
  final int toVersion;
  final bool success;
  final String? error;

  MigrationResult({
    required this.fromVersion,
    required this.toVersion,
    required this.success,
    this.error,
  });
}

/// Database service managing Hive boxes and migrations
class HiveDatabase {
  static const String _schemaVersionKey = '__schema_version__';
  static const String _itemsBoxName = 'items';
  static const int _currentSchemaVersion = 1;

  final HiveInterface _hive;
  Box<Item>? _itemsBox;

  HiveDatabase({HiveInterface? hive}) : _hive = hive ?? Hive;

  /// Check if database is initialized
  bool get isInitialized => _itemsBox != null && _itemsBox!.isOpen;

  /// Initialize database (register adapters already done in main.dart)
  Future<void> init() async {
    if (isInitialized) return;

    // Open items box
    _itemsBox = await _hive.openBox<Item>(_itemsBoxName);

    // Perform migrations if needed
    await _performMigrations();
  }

  /// Perform schema migrations
  Future<void> _performMigrations() async {
    if (_itemsBox == null) throw Exception('Items box not opened');

    final currentVersion = _getSchemaVersion();
    if (currentVersion >= _currentSchemaVersion) {
      return; // No migration needed
    }

    // Migrate from v0 to v1 (initial schema)
    if (currentVersion == 0) {
      await _migrateToV1();
    }

    // Update schema version
    await _setSchemaVersion(_currentSchemaVersion);
  }

  /// Migration to v1: Initial schema with Item entity
  /// No data transformation needed for initial schema
  Future<void> _migrateToV1() async {
    // Initial schema - no transformation needed
    // Just mark migration as complete
  }

  /// Get current schema version
  int _getSchemaVersion() {
    final versionBox = _hive.box<dynamic>('_metadata');
    return versionBox.get(_schemaVersionKey, defaultValue: 0) as int;
  }

  /// Set schema version
  Future<void> _setSchemaVersion(int version) async {
    final versionBox = await _hive.openBox<dynamic>('_metadata');
    await versionBox.put(_schemaVersionKey, version);
  }

  /// Get items box
  Box<Item> get itemsBox {
    if (_itemsBox == null || !_itemsBox!.isOpen) {
      throw Exception('Database not initialized');
    }
    return _itemsBox!;
  }

  /// Close all boxes
  Future<void> close() async {
    await _itemsBox?.close();
  }

  /// Clear all data (for testing)
  Future<void> clear() async {
    if (_itemsBox == null) throw Exception('Database not initialized');
    await _itemsBox!.clear();
  }

  /// Get database statistics
  Map<String, dynamic> getStats() {
    return {
      'itemsCount': _itemsBox?.length ?? 0,
      'schemaVersion': _getSchemaVersion(),
      'isInitialized': isInitialized,
    };
  }
}
