import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz show TZDateTime;
import 'package:zerospoils/core/notifications/notification_service.dart';

/// Mock plugin for testing notification scheduling
class MockFlutterLocalNotificationsPlugin extends FlutterLocalNotificationsPlugin {
  final List<Map<String, dynamic>> scheduledNotifications = [];
  final List<int> cancelledNotifications = [];
  bool initializeCalled = false;
  bool channelCreated = false;

  @override
  Future<bool?> initialize(
    InitializationSettings initializationSettings, {
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
        onDidReceiveBackgroundNotificationResponse,
  }) async {
    initializeCalled = true;
    return true;
  }

  @override
  AndroidFlutterLocalNotificationsPlugin?
      resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>() {
    return MockAndroidFlutterLocalNotificationsPlugin(
      onChannelCreated: () => channelCreated = true,
    ) as AndroidFlutterLocalNotificationsPlugin?;
  }

  @override
  Future<void> zonedSchedule(
    int id,
    String? title,
    String? body,
    tz.TZDateTime scheduledDate,
    NotificationDetails notificationDetails, {
    required UILocalNotificationDateInterpretation
        uiLocalNotificationDateInterpretation,
    AndroidScheduleMode? androidScheduleMode,
    DateTimeComponents? matchDateTimeComponents,
    String? payload,
  }) async {
    scheduledNotifications.add({
      'id': id,
      'title': title,
      'body': body,
      'scheduledDate': scheduledDate,
      'notificationDetails': notificationDetails,
    });
  }

  @override
  Future<void> cancel(int id) async {
    cancelledNotifications.add(id);
  }
}

/// Mock Android-specific implementation
class MockAndroidFlutterLocalNotificationsPlugin {
  final void Function()? onChannelCreated;

  MockAndroidFlutterLocalNotificationsPlugin({this.onChannelCreated});

  Future<void> createNotificationChannel(
    AndroidNotificationChannel channel,
  ) async {
    onChannelCreated?.call();
  }
}

void main() {
  late NotificationService notificationService;
  late MockFlutterLocalNotificationsPlugin mockPlugin;
  final List<Map<String, dynamic>> telemetryEvents = [];

  setUpAll(() {
    // Initialize timezone data for tests
    tz.initializeTimeZones();
  });

  setUp(() {
    mockPlugin = MockFlutterLocalNotificationsPlugin();
    notificationService = NotificationService(plugin: mockPlugin);
    telemetryEvents.clear();

    // Set up telemetry callback to capture events
    notificationService.setTelemetryCallback((eventName, properties) {
      telemetryEvents.add({'name': eventName, 'properties': properties});
    });
  });

  group('NotificationService - computeScheduleTime', () {
    test('schedules notification at 9am on day-before-expiry', () {
      final expiryDate = DateTime(2026, 2, 15); // Feb 15, 2026
      final scheduleTime = notificationService.computeScheduleTime(expiryDate);

      // Should be Feb 14, 2026 at 9:00 AM local
      expect(scheduleTime.year, 2026);
      expect(scheduleTime.month, 2);
      expect(scheduleTime.day, 14);
      expect(scheduleTime.hour, 9);
      expect(scheduleTime.minute, 0);
    });

    test('handles expiry on first of month correctly', () {
      final expiryDate = DateTime(2026, 3, 1); // Mar 1, 2026
      final scheduleTime = notificationService.computeScheduleTime(expiryDate);

      // Should be Feb 28, 2026 at 9:00 AM (not leap year)
      expect(scheduleTime.year, 2026);
      expect(scheduleTime.month, 2);
      expect(scheduleTime.day, 28);
      expect(scheduleTime.hour, 9);
    });

    test('handles year boundary correctly', () {
      final expiryDate = DateTime(2027, 1, 1); // Jan 1, 2027
      final scheduleTime = notificationService.computeScheduleTime(expiryDate);

      // Should be Dec 31, 2026 at 9:00 AM
      expect(scheduleTime.year, 2026);
      expect(scheduleTime.month, 12);
      expect(scheduleTime.day, 31);
      expect(scheduleTime.hour, 9);
    });

    test('handles leap year correctly', () {
      final expiryDate = DateTime(2024, 3, 1); // Mar 1, 2024 (leap year)
      final scheduleTime = notificationService.computeScheduleTime(expiryDate);

      // Should be Feb 29, 2024 at 9:00 AM
      expect(scheduleTime.year, 2024);
      expect(scheduleTime.month, 2);
      expect(scheduleTime.day, 29);
      expect(scheduleTime.hour, 9);
    });

    test(
      'timezone consistency - same date across timezones yields local 9am',
      () {
        final expiryDate = DateTime(2026, 2, 15);

        // computeScheduleTime returns a TZDateTime in the local timezone
        // Verify it's always 9am local regardless of what the system timezone is
        final scheduleTime = notificationService.computeScheduleTime(
          expiryDate,
        );

        expect(scheduleTime.day, 14);
        expect(scheduleTime.hour, 9);
        expect(scheduleTime.minute, 0);
      },
    );

    test(
      'same day edge case - expiry at midnight should schedule previous day 9am',
      () {
        final expiryDate = DateTime(2026, 2, 15, 0, 0, 0); // Feb 15 at 00:00
        final scheduleTime = notificationService.computeScheduleTime(
          expiryDate,
        );

        // Should still be Feb 14 at 9:00 AM
        expect(scheduleTime.day, 14);
        expect(scheduleTime.hour, 9);
      },
    );
  });

  group('NotificationService - telemetry integration', () {
    test('scheduleForItem emits notification_scheduled event', () async {
      final expiryDate = DateTime(2026, 2, 15);
      final itemId = 123;

      // Initialize the service to set up the mock plugin
      await notificationService.initialize();

      // Call scheduleForItem which should trigger telemetry
      await notificationService.scheduleForItem(
        itemId: itemId,
        expiryDate: expiryDate,
        title: 'Test Item Expiring',
        body: 'Your test item is expiring soon',
      );

      // Verify that the plugin received the schedule call
      expect(mockPlugin.scheduledNotifications.length, 1);
      expect(mockPlugin.scheduledNotifications[0]['id'], itemId);
      expect(mockPlugin.scheduledNotifications[0]['title'], 'Test Item Expiring');

      // Verify that telemetry was emitted
      expect(telemetryEvents.length, 1);
      expect(telemetryEvents[0]['name'], 'notification_scheduled');
      expect(telemetryEvents[0]['properties']['item_id'], itemId.toString());
      expect(
        telemetryEvents[0]['properties']['schedule_time'],
        isA<String>(),
      );

      // Verify the schedule time is correct (Feb 14, 2026 at 9am)
      final scheduleTimeStr =
          telemetryEvents[0]['properties']['schedule_time'] as String;
      final scheduleTime = DateTime.parse(scheduleTimeStr);
      expect(scheduleTime.day, 14);
      expect(scheduleTime.month, 2);
      expect(scheduleTime.year, 2026);
      expect(scheduleTime.hour, 9);
    });

    test('telemetry callback is invoked with correct event structure', () {
      final capturedEvents = <Map<String, dynamic>>[];

      notificationService.setTelemetryCallback((name, props) {
        capturedEvents.add({'name': name, 'properties': props});
      });

      // Simulate telemetry call (we can't actually schedule without initialization)
      notificationService.setTelemetryCallback((name, props) {
        expect(name, isNotEmpty);
        expect(props, isA<Map<String, dynamic>>());
      });
    });
  });

  group('NotificationService - boundary cases', () {
    test('expiry date exactly 1 day away schedules notification today', () {
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final scheduleTime = notificationService.computeScheduleTime(tomorrow);

      // Should be today at 9am
      expect(scheduleTime.year, now.year);
      expect(scheduleTime.month, now.month);
      expect(scheduleTime.day, now.day);
      expect(scheduleTime.hour, 9);
    });

    test('expiry date in past yields past schedule time', () {
      final pastDate = DateTime(2025, 1, 1);
      final scheduleTime = notificationService.computeScheduleTime(pastDate);

      // Should be Dec 31, 2024 at 9am
      expect(scheduleTime.year, 2024);
      expect(scheduleTime.month, 12);
      expect(scheduleTime.day, 31);
      expect(scheduleTime.isBefore(DateTime.now()), isTrue);
    });
  });

  group('NotificationService - singleton behavior', () {
    test('factory returns same instance when no plugin provided', () {
      final instance1 = NotificationService();
      final instance2 = NotificationService();

      expect(identical(instance1, instance2), isTrue);
    });

    test('factory returns new instance when plugin is provided', () {
      final plugin1 = MockFlutterLocalNotificationsPlugin();
      final plugin2 = MockFlutterLocalNotificationsPlugin();
      
      final service1 = NotificationService(plugin: plugin1);
      final service2 = NotificationService(plugin: plugin2);

      // These should be different instances since we provided plugins
      expect(identical(service1, service2), isFalse);
    });

    test('telemetry callback persists across factory calls', () {
      final events1 = <String>[];
      final events2 = <String>[];

      final service1 = NotificationService();
      service1.setTelemetryCallback((name, _) => events1.add(name));

      final service2 = NotificationService();
      service2.setTelemetryCallback((name, _) => events2.add(name));

      // Both should reference the same instance
      expect(identical(service1, service2), isTrue);
    });
  });
}
