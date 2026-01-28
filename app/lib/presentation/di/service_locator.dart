// Service locator and dependency injection setup using Riverpod
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../domain/models/item_model.dart';
import '../../domain/repositories/badge_service.dart';
import '../../data/repositories/hive_item_repository.dart';
import '../../core/notifications/notification_service.dart';

/// Connectivity service provider
final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map((result) {
    return result.contains(ConnectivityResult.none) == false;
  });
});

/// Telemetry client provider
final telemetryClientProvider = Provider((ref) {
  return TelemetryClient();
});

/// Notification service provider
final notificationServiceProvider = Provider((ref) {
  return NotificationService();
});

/// Item repository provider with notification service wired in
final itemRepositoryProvider = Provider((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return HiveItemRepository(notificationService: notificationService);
});

/// Badge service provider
final badgeServiceProvider = Provider((ref) {
  return BadgeService();
});

// Service implementations

/// Basic telemetry client for local event queuing
class TelemetryClient {
  /// In-memory event sink to aid testing before Hive queue lands
  final List<Map<String, dynamic>> events = [];

  /// Enqueue an event locally (no upload yet)
  void enqueue(Map<String, dynamic> event) {
    events.add(event);
    // TODO: M1/090 - Implement local queue with Hive
    // - Apply redaction rules from telemetry/policies/redaction.yaml
    // - Apply sampling from telemetry/policies/sampling.yaml
    // - Store in Hive queue for later batch upload
    // ignore: avoid_print
    print('Telemetry event enqueued: ${event['name']}');
  }

  /// Track app installed event (called on first launch)
  void trackAppInstalled({required bool isFirstInstall}) {
    enqueue({
      'name': 'app_installed',
      'properties': {'is_first_install': isFirstInstall},
    });
  }

  /// Track tab switched event
  void trackTabSwitched({required String tabName}) {
    enqueue({
      'name': 'tab_switched',
      'properties': {'tab_name': tabName},
    });
  }

  /// Track backup started
  void trackBackupStarted() {
    enqueue({'name': 'backup_started', 'properties': {}});
  }

  /// Track backup succeeded
  void trackBackupSucceeded({
    required int sizeBytes,
    required int itemCount,
    required String appVersion,
  }) {
    enqueue({
      'name': 'backup_succeeded',
      'properties': {
        'size_bytes': sizeBytes,
        'item_count': itemCount,
        'app_version': appVersion,
      },
    });
  }

  /// Track backup failed
  void trackBackupFailed({required String reason}) {
    enqueue({
      'name': 'backup_failed',
      'properties': {'reason': reason},
    });
  }

  /// Track restore started
  void trackRestoreStarted({
    required String schemaVersion,
    required String appVersion,
  }) {
    enqueue({
      'name': 'restore_started',
      'properties': {
        'schema_version_from': schemaVersion,
        'app_version_from': appVersion,
      },
    });
  }

  /// Track restore succeeded
  void trackRestoreSucceeded({
    required int itemCountImported,
    required int migrationsApplied,
    required String schemaVersionFrom,
    required String appVersionFrom,
  }) {
    enqueue({
      'name': 'restore_succeeded',
      'properties': {
        'item_count_imported': itemCountImported,
        'migrations_applied': migrationsApplied,
        'schema_version_from': schemaVersionFrom,
        'app_version_from': appVersionFrom,
      },
    });
  }

  /// Track restore failed
  void trackRestoreFailed({
    required String reason,
    required bool schemaMismatch,
  }) {
    enqueue({
      'name': 'restore_failed',
      'properties': {'reason': reason, 'schema_mismatch': schemaMismatch},
    });
  }

  /// Track notification scheduled
  void trackNotificationScheduled({
    required String itemId,
    required DateTime scheduleTime,
  }) {
    enqueue({
      'name': 'notification_scheduled',
      'properties': {
        'item_id': itemId,
        'schedule_time': scheduleTime.toIso8601String(),
      },
    });
  }

  /// Track notification rescheduled
  void trackNotificationRescheduled({
    required String itemId,
    required DateTime newScheduleTime,
  }) {
    enqueue({
      'name': 'notification_rescheduled',
      'properties': {
        'item_id': itemId,
        'new_schedule_time': newScheduleTime.toIso8601String(),
      },
    });
  }

  /// Track notification cancelled
  void trackNotificationCancelled({
    required String itemId,
    required String reason,
  }) {
    enqueue({
      'name': 'notification_cancelled',
      'properties': {'item_id': itemId, 'reason': reason},
    });
  }
}

/// Item repository (stub implementation)
class ItemRepository {
  /// Get all items from local Hive database
  Future<List<Item>> getAllItems() async {
    // TODO: M2/100 - Implement with Hive
    return [];
  }

  /// Add item to local database
  Future<void> addItem(Item item) async {
    // TODO: M2/100 - Implement with Hive
  }
}
