import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Callback function type for telemetry events
typedef TelemetryCallback =
    void Function(String eventName, Map<String, dynamic> properties);

/// Basic notifications scaffolding for M2/120: schedule/reschedule/cancel.
class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  TelemetryCallback? _telemetryCallback;

  /// Set telemetry callback for event tracking
  void setTelemetryCallback(TelemetryCallback callback) {
    _telemetryCallback = callback;
  }

  Future<void> initialize() async {
    if (_initialized) return;

    // Timezone initialization
    tz.initializeTimeZones();

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

    await _plugin.initialize(initSettings);

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

  /// Derive a schedule time based on expiry date (default: 9am local on day-before-expiry).
  tz.TZDateTime computeScheduleTime(DateTime expiryDate) {
    final local = tz.local;
    final preExpiry = DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day,
    ).subtract(const Duration(days: 1));
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
    final when = computeScheduleTime(expiryDate);
    await _plugin.zonedSchedule(
      itemId, // use itemId as notificationId
      title ?? 'Upcoming expiry',
      body ?? 'An item is nearing expiry',
      when,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'zerospoils_default',
          'ZeroSpoils Notifications',
          channelDescription: 'General notifications for expiring items',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
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
    await cancelForItem(itemId);
    await scheduleForItem(
      itemId: itemId,
      expiryDate: newExpiryDate,
      title: title,
      body: body,
    );

    final when = computeScheduleTime(newExpiryDate);
    _telemetryCallback?.call('notification_rescheduled', {
      'item_id': itemId.toString(),
      'new_schedule_time': when.toIso8601String(),
    });
  }

  Future<void> cancelForItem(
    int itemId, {
    String reason = 'item_deleted',
  }) async {
    await _plugin.cancel(itemId);

    _telemetryCallback?.call('notification_cancelled', {
      'item_id': itemId.toString(),
      'reason': reason,
    });
  }

  /// Placeholder: on app startup, rehydrate scheduled notifications if needed.
  Future<void> restoreScheduled() async {
    // In M2 we rely on system persistence of scheduled alarms.
    // A future enhancement can re-scan items and re-schedule here if required.
  }
}
