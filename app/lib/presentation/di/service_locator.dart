// Service locator and dependency injection setup using Riverpod
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/item_model.dart';
import '../../domain/repositories/badge_service.dart';
import '../../domain/repositories/progress_stats_service.dart';
import '../../data/repositories/hive_item_repository.dart';
import '../../core/notifications/notification_service.dart';

/// Connectivity service provider
final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map((result) {
    return result.contains(ConnectivityResult.none) == false;
  });
});

/// Analytics consent provider - tracks whether user has opted into telemetry
final analyticsConsentProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  // Default: opt-in to local telemetry (privacy-first, no cloud export)
  return prefs.getBool('analytics_consent') ?? true;
});

/// Telemetry client provider
final telemetryClientProvider = Provider((ref) {
  final consentAsync = ref.watch(analyticsConsentProvider);
  final consent = consentAsync.maybeWhen(
    data: (value) => value,
    orElse: () => false, // Default to no consent during loading
  );
  return TelemetryClient(consentEnabled: consent);
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

/// Progress stats service provider
final progressStatsServiceProvider = Provider((ref) {
  final badgeService = ref.watch(badgeServiceProvider);
  return ProgressStatsService(badgeService: badgeService);
});

// Service implementations

/// Basic telemetry client for local event queuing
class TelemetryClient {
  /// In-memory event sink to aid testing before Hive queue lands
  final List<Map<String, dynamic>> events = [];
  void Function(String, Map<String, dynamic>)? _emitCallback;
  final bool consentEnabled;
  final dynamic eventStore; // TelemetryEventStore (optional for persistence)

  TelemetryClient({this.consentEnabled = true, this.eventStore});

  /// Enqueue an event locally (no upload yet)
  void enqueue(Map<String, dynamic> event) {
    // Respect consent: skip if user opted out
    if (!consentEnabled) {
      return;
    }

    // Validate event structure in debug builds
    assert(event['name'] is String, 'Event must have a "name" field (String)');
    assert(
      event['properties'] is Map<String, dynamic>,
      'Event must have a "properties" field (Map)',
    );

    // Schema validation in debug mode only (not profile builds)
    if (kDebugMode) {
      _validateEvent(event);
    }

    events.add(event);
    if (_emitCallback != null &&
        event['name'] is String &&
        event['properties'] is Map<String, dynamic>) {
      _emitCallback!(event['name'], event['properties']);
    }

    // Persist to store if available
    if (eventStore != null) {
      eventStore.addEvent(event);
    }

    // TODO: M1/090 - Implement local queue with Hive
    // - Apply redaction rules from telemetry/policies/redaction.yaml
    // - Apply sampling from telemetry/policies/sampling.yaml
    // - Store in Hive queue for later batch upload
    if (kDebugMode) {
      debugPrint('Telemetry event enqueued: ${event['name']}');
    }
  }

  /// Validate event schema (debug builds only)
  void _validateEvent(Map<String, dynamic> event) {
    final name = event['name'] as String?;
    final properties = event['properties'] as Map<String, dynamic>?;

    if (name == null || properties == null) {
      throw ArgumentError('Event must have "name" and "properties" fields');
    }

    // Reject PII keys (disallowed per privacy policy)
    const piiKeys = ['email', 'phone', 'device_id', 'ip_address', 'full_name'];
    for (final key in piiKeys) {
      if (properties.containsKey(key)) {
        throw ArgumentError('Event "$name" contains disallowed PII key: $key');
      }
    }

    // Validate required standard properties for core funnel events
    const coreFunnelEvents = [
      'app_installed',
      'onboarding_completed',
      'item_added',
      'item_edited',
      'item_consumed',
      'item_wasted',
      'inventory_viewed',
      'expiring_viewed',
      'reminder_opened',
    ];

    if (coreFunnelEvents.contains(name)) {
      // Core events should have platform, app_version (when available)
      // For now, just warn if missing - we'll add these systematically
      if (!properties.containsKey('platform')) {
        debugPrint('Warning: Core event "$name" missing "platform" property');
      }
    }
  }

  /// Allow test to inject a callback for event emission
  void setEmitCallback(void Function(String, Map<String, dynamic>) callback) {
    _emitCallback = callback;
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
