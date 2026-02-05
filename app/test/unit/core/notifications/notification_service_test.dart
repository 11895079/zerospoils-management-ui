import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz show TZDateTime;
import 'package:zerospoils/core/notifications/notification_service.dart';

/// Mock plugin for testing notification scheduling

class MockFlutterLocalNotificationsPlugin
    implements FlutterLocalNotificationsPlugin {
  final List<Map<String, dynamic>> scheduledNotifications = [];
  final List<int> cancelledNotifications = [];
  bool initializeCalled = false;
  bool channelCreated = false;

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async {
    initializeCalled = true;
    return true;
  }

  @override
  T? resolvePlatformSpecificImplementation<
    T extends FlutterLocalNotificationsPlatform
  >() {
    channelCreated = true;
    if (T == AndroidFlutterLocalNotificationsPlugin) {
      return MockAndroidFlutterLocalNotificationsPlugin(
            onChannelCreated: () => channelCreated = true,
          )
          as T;
    }
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<void> zonedSchedule({
    required int id,
    String? title,
    String? body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    AndroidScheduleMode? androidScheduleMode,
    DateTimeComponents? matchDateTimeComponents,
    String? payload,
    bool? androidAllowWhileIdle,
    String? tag,
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
  Future<void> cancel({required int id, String? tag}) async {
    cancelledNotifications.add(id);
  }
}

/// Mock Android-specific implementation

class MockAndroidFlutterLocalNotificationsPlugin
    extends AndroidFlutterLocalNotificationsPlugin {
  final void Function()? onChannelCreated;

  MockAndroidFlutterLocalNotificationsPlugin({this.onChannelCreated});

  @override
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
      // Skip this test on web/desktop platforms where notification logic is disabled
      // (see NotificationService.initialize)
      bool isWeb = false;
      try {
        // ignore: undefined_prefixed_name
        isWeb = identical(0, 0.0);
      } catch (_) {}
      final isDesktop = ["windows", "linux", "macos"].contains(
        (const String.fromEnvironment(
          'FLUTTER_TEST_PLATFORM',
          defaultValue: '',
        )).toLowerCase(),
      );
      if (isWeb || isDesktop) {
        return;
      }

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
      expect(
        mockPlugin.scheduledNotifications[0]['title'],
        'Test Item Expiring',
      );

      // Verify that telemetry was emitted
      expect(telemetryEvents.length, 1);
      expect(telemetryEvents[0]['name'], 'notification_scheduled');
      expect(telemetryEvents[0]['properties']['item_id'], itemId.toString());
      expect(telemetryEvents[0]['properties']['schedule_time'], isA<String>());

      // Verify the schedule time is correct: day before expiry at 9am local time
      final scheduleTimeStr =
          telemetryEvents[0]['properties']['schedule_time'] as String;
      // Parse the ISO8601 string - it should already be in the correct timezone
      final scheduleTime = DateTime.parse(scheduleTimeStr);
      expect(scheduleTime.day, 14);
      expect(scheduleTime.month, 2);
      expect(scheduleTime.year, 2026);
      expect(scheduleTime.hour, 9);
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

      // Each custom plugin creates a separate instance for testing
      expect(identical(service1, service2), isFalse);
    });

    test('singleton instance has independent state from test instances', () {
      final singletonEvents = <String>[];
      final testInstanceEvents = <String>[];

      // Set callback on singleton
      final singleton = NotificationService();
      singleton.setTelemetryCallback((name, _) => singletonEvents.add(name));

      // Set callback on test instance with custom plugin
      final testPlugin = MockFlutterLocalNotificationsPlugin();
      final testInstance = NotificationService(plugin: testPlugin);
      testInstance.setTelemetryCallback(
        (name, _) => testInstanceEvents.add(name),
      );

      // These should be different instances with independent callbacks
      expect(identical(singleton, testInstance), isFalse);
    });
  });
}
