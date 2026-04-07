import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:zerospoils/core/notifications/notification_preferences.dart';
import 'package:zerospoils/core/notifications/reminder_notification_payload.dart';
import 'package:zerospoils/core/notifications/reminder_time_of_day.dart';
import 'package:zerospoils/domain/utils/local_id_generator.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Callback function type for telemetry events
typedef TelemetryCallback =
    void Function(String eventName, Map<String, dynamic> properties);

/// Callback function type for notification tap handling
typedef NotificationTapHandler =
    Future<void> Function(ReminderNotificationPayload? payload);

/// Basic notifications scaffolding for M2/120: schedule/reschedule/cancel.
class NotificationService {
  NotificationService._internal({
    FlutterLocalNotificationsPlugin? plugin,
    NotificationPreferencesStore? preferencesStore,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _preferencesStore = preferencesStore ?? NotificationPreferencesStore();

  static final NotificationService _instance = NotificationService._internal();

  /// Create a NotificationService instance.
  ///
  /// By default, returns the singleton instance. If [plugin] is provided,
  /// creates a new instance for testing purposes with the custom plugin.
  ///
  /// Note: Providing a plugin creates a new instance that bypasses the singleton.
  /// This is primarily intended for unit tests where you need to mock the
  /// notification plugin behavior.
  factory NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    NotificationPreferencesStore? preferencesStore,
  }) {
    // If a plugin or preferences store is provided, create a new instance
    if (plugin != null || preferencesStore != null) {
      return NotificationService._internal(
        plugin: plugin,
        preferencesStore: preferencesStore,
      );
    }
    return _instance;
  }
  NotificationTapHandler? _notificationTapHandler;

  final FlutterLocalNotificationsPlugin _plugin;
  final NotificationPreferencesStore _preferencesStore;
  bool _initialized = false;
  TelemetryCallback? _telemetryCallback;

  /// Set notification tap handler for navigation and attribution
  void setNotificationTapHandler(NotificationTapHandler handler) {
    _notificationTapHandler = handler;
  }

  /// Set telemetry callback for event tracking
  void setTelemetryCallback(TelemetryCallback callback) {
    _telemetryCallback = callback;
  }

  Future<void> initialize() async {
    if (_initialized) return;

    // Skip all notification logic on web
    if (kIsWeb) {
      _initialized = true;
      return;
    }

    // Skip notification initialization on Windows (not supported yet)
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      _initialized = true;
      return;
    }

    // Timezone initialization
    tz.initializeTimeZones();
    // Set local timezone to ensure tz.local resolves to device timezone, not UTC
    final timeZoneName = await _getDeviceTimeZone();
    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      // Fallback silently if timezone setup fails
    }

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(settings: initSettings);

    // Create Android channels (basic default). Refinements later per M2/120.
    const AndroidNotificationChannel defaultChannel =
        AndroidNotificationChannel(
          'zerospoils_default',
          'ZeroSpoils Notifications',
          description: 'General notifications for expiring items',
          importance: Importance.defaultImportance,
        );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(defaultChannel);

    _initialized = true;
  }

  /// Derive a schedule time based on expiry date and lead time.
  tz.TZDateTime computeScheduleTime(
    DateTime expiryDate, {
    int leadTimeDays = 1,
  }) {
    final local = tz.local;
    final preExpiry = DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day,
    ).subtract(Duration(days: leadTimeDays));
    // Use TZDateTime constructor to create time directly in local timezone
    return tz.TZDateTime(
      local,
      preExpiry.year,
      preExpiry.month,
      preExpiry.day,
      9, // hour
      0, // minute
      0, // second
    );
  }

  Future<void> scheduleForItem({
    required int itemId,
    required DateTime expiryDate,
    String? title,
    String? body,
  }) async {
    final preferences = await _preferencesStore.load();
    if (!preferences.notificationsEnabled) {
      return;
    }

    await _scheduleForItemWithPreferences(
      itemId: itemId,
      expiryDate: expiryDate,
      title: title,
      body: body,
      preferences: preferences,
    );
  }

  Future<void> _scheduleForItemWithPreferences({
    required int itemId,
    required DateTime expiryDate,
    required NotificationPreferences preferences,
    String? title,
    String? body,
  }) async {
    final when = computeScheduleTime(
      expiryDate,
      leadTimeDays: preferences.leadTimeDays,
    );
    await _plugin.zonedSchedule(
      id: itemId,
      title: title ?? 'Upcoming expiry',
      body: body ?? 'An item is nearing expiry',
      scheduledDate: when,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'zerospoils_default',
          'ZeroSpoils Notifications',
          channelDescription: 'General notifications for expiring items',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: preferences.soundEnabled,
          enableVibration: preferences.vibrationEnabled,
        ),
        iOS: DarwinNotificationDetails(presentSound: preferences.soundEnabled),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    // Track telemetry
    _telemetryCallback?.call('notification_scheduled', {
      'item_id': itemId.toString(),
      'schedule_time': when.toIso8601String(),
    });
  }

  Future<void> rescheduleForItem({
    required int itemId,
    required DateTime newExpiryDate,
    String? title,
    String? body,
  }) async {
    // Cancel existing notification without emitting telemetry
    // (to avoid double-counting; reschedule is a single operation)
    await _plugin.cancel(id: itemId);

    final preferences = await _preferencesStore.load();
    if (!preferences.notificationsEnabled) {
      return;
    }

    await _scheduleForItemWithPreferences(
      itemId: itemId,
      expiryDate: newExpiryDate,
      title: title,
      body: body,
      preferences: preferences,
    );

    final when = computeScheduleTime(
      newExpiryDate,
      leadTimeDays: preferences.leadTimeDays,
    );
    _telemetryCallback?.call('notification_rescheduled', {
      'item_id': itemId.toString(),
      'new_schedule_time': when.toIso8601String(),
    });
  }

  Future<void> cancelForItem(
    int itemId, {
    String reason = 'item_deleted',
  }) async {
    await _plugin.cancel(id: itemId);

    _telemetryCallback?.call('notification_cancelled', {
      'item_id': itemId.toString(),
      'reason': reason,
    });
  }

  /// Cancel all scheduled notifications.
  /// Called when user disables notifications or clears all data.
  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  /// Reschedule all notifications based on current preferences and item list.
  /// Called when user changes notification preferences (master toggle, lead time).
  /// If notifications are disabled, cancels all. If enabled, reschedules all items.
  Future<void> rescheduleAllNotifications(
    List<dynamic> items, {
    String? itemIdField = 'id',
    String? expiryDateField = 'expiryDate',
  }) async {
    // Cancel all existing notifications first
    await cancelAllNotifications();

    final preferences = await _preferencesStore.load();
    if (!preferences.notificationsEnabled) {
      // Notifications disabled; all already cancelled
      return;
    }

    // Reschedule all items with valid expiry dates
    for (final item in items) {
      try {
        final rawItemId = item is Map ? item[itemIdField] : item.id;
        final itemId = _parseNotificationId(rawItemId);
        final expiryDate =
            (item is Map ? item[expiryDateField] : item.expiryDate)
                as DateTime?;

        if (itemId != null && expiryDate != null) {
          // Schedule without emitting individual telemetry
          // (preference change is the higher-level event)
          final when = computeScheduleTime(
            expiryDate,
            leadTimeDays: preferences.leadTimeDays,
          );
          await _plugin.zonedSchedule(
            id: itemId,
            title: 'Upcoming expiry',
            body: 'An item is nearing expiry',
            scheduledDate: when,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                'zerospoils_default',
                'ZeroSpoils Notifications',
                channelDescription: 'General notifications for expiring items',
                importance: Importance.defaultImportance,
                priority: Priority.defaultPriority,
                playSound: preferences.soundEnabled,
                enableVibration: preferences.vibrationEnabled,
              ),
              iOS: DarwinNotificationDetails(
                presentSound: preferences.soundEnabled,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        }
      } catch (e) {
        // Log but continue with other items
        // In production, would emit error telemetry here
      }
    }

    // Emit single telemetry event for the preference change
    _telemetryCallback?.call('notifications_rescheduled_bulk', {
      'item_count': items.length,
      'notifications_enabled': preferences.notificationsEnabled,
      'lead_time_days': preferences.leadTimeDays,
    });
  }

  /// Restore scheduled notifications from persisted items on app startup.
  /// Reschedules all items with valid expiry dates based on current preferences.
  Future<void> restoreScheduled({required List<dynamic> items}) async {
    final preferences = await _preferencesStore.load();
    if (!preferences.notificationsEnabled) {
      return;
    }

    // Schedule all items with expiry dates
    for (final item in items) {
      try {
        final rawItemId = item is Map ? item['id'] : item.id;
        final itemId = _parseNotificationId(rawItemId);
        final expiryDate =
            (item is Map ? item['expiryDate'] : item.expiryDate) as DateTime?;

        if (itemId != null && expiryDate != null) {
          final when = computeScheduleTime(
            expiryDate,
            leadTimeDays: preferences.leadTimeDays,
          );
          await _plugin.zonedSchedule(
            id: itemId,
            title: 'Upcoming expiry',
            body: 'An item is nearing expiry',
            scheduledDate: when,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                'zerospoils_default',
                'ZeroSpoils Notifications',
                channelDescription: 'General notifications for expiring items',
                importance: Importance.defaultImportance,
                priority: Priority.defaultPriority,
                playSound: preferences.soundEnabled,
                enableVibration: preferences.vibrationEnabled,
              ),
              iOS: DarwinNotificationDetails(
                presentSound: preferences.soundEnabled,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        }
      } catch (e) {
        // Log but continue with other items
        // In production, would emit error telemetry here
      }
    }

    // Emit telemetry for the restore operation
    _telemetryCallback?.call('notifications_restored_on_startup', {
      'item_count': items.length,
      'notifications_enabled': preferences.notificationsEnabled,
      'lead_time_days': preferences.leadTimeDays,
    });
  }

  int? _parseNotificationId(dynamic rawId) {
    if (rawId is int) return rawId;
    if (rawId is String) return LocalIdGenerator.notificationIdFor(rawId);
    return null;
  }

  /// Get device timezone name for configuration.
  /// Returns a timezone name from the IANA timezone database.
  /// For M2/120, attempts to detect local timezone offset and map to known zone.
  /// Fallback: 'UTC' (will be set by platform-specific code in production).
  Future<String> _getDeviceTimeZone() async {
    try {
      // Get current time to calculate offset
      final now = DateTime.now();
      final offset = now.timeZoneOffset;

      // Simple mapping of common UTC offsets to timezone names
      // Production code should use a proper timezone detection library
      final hours = offset.inHours;
      switch (hours) {
        case 0:
          return 'UTC'; // UTC, GMT, etc.
        case 1:
          return 'Europe/London'; // or 'Africa/Lagos'
        case 2:
          return 'Europe/Paris'; // or 'Africa/Cairo'
        case 3:
          return 'Europe/Moscow'; // or 'Africa/Johannesburg'
        case -5:
          return 'America/New_York';
        case -6:
          return 'America/Chicago';
        case -7:
          return 'America/Denver';
        case -8:
          return 'America/Los_Angeles';
        case 8:
          return 'Asia/Shanghai';
        case 9:
          return 'Asia/Tokyo';
        case 10:
          return 'Australia/Sydney';
        default:
          // Fallback to UTC if offset doesn't match common zones
          return 'UTC';
      }
    } catch (e) {
      // If detection fails, default to UTC
      return 'UTC';
    }
  }

  /// Handle notification tap response and emit telemetry.
  /// Parses the payload, emits reminder_opened event, and invokes tap handler.
  Future<void> handleNotificationResponsePayload(
    String payloadJson, {
    DateTime? now,
  }) async {
    final payload = ReminderNotificationPayload.tryParse(payloadJson);
    if (payload == null) {
      return;
    }

    final timestamp = now ?? DateTime.now();
    final timeOfDay = timeOfDayFor(timestamp);

    // Emit reminder_opened telemetry
    _telemetryCallback?.call('reminder_opened', {
      'lead_time_days': payload.leadTimeDays,
      'time_of_day': timeOfDay,
    });

    // Invoke tap handler for navigation and attribution
    await _notificationTapHandler?.call(payload);
  }
}
