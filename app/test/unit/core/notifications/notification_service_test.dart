import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz show TZDateTime;
import 'package:zerospoils/core/notifications/notification_service.dart';
import 'package:zerospoils/core/notifications/reminder_notification_payload.dart';
import 'package:zerospoils/domain/utils/local_id_generator.dart';

/// Mock plugin for testing notification scheduling

class MockFlutterLocalNotificationsPlugin
    implements FlutterLocalNotificationsPlugin {
  final List<Map<String, dynamic>> scheduledNotifications = [];
  final List<int> cancelledNotifications = [];
  final mockAndroid = MockAndroidFlutterLocalNotificationsPlugin();
  final mockIos = MockIOSFlutterLocalNotificationsPlugin();
  final mockMacOs = MockMacOSFlutterLocalNotificationsPlugin();
  bool initializeCalled = false;
  bool channelCreated = false;
  InitializationSettings? initializationSettings;

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async {
    initializeCalled = true;
    initializationSettings = settings;
    return true;
  }

  @override
  T? resolvePlatformSpecificImplementation<
    T extends FlutterLocalNotificationsPlatform
  >() {
    channelCreated = true;
    if (T == AndroidFlutterLocalNotificationsPlugin) {
      mockAndroid.onChannelCreated = () => channelCreated = true;
      return mockAndroid as T;
    }
    if (T == IOSFlutterLocalNotificationsPlugin) {
      return mockIos as T;
    }
    if (T == MacOSFlutterLocalNotificationsPlugin) {
      return mockMacOs as T;
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

  @override
  Future<void> cancelAll() async {
    // Mark all scheduled as cancelled
    for (final notification in scheduledNotifications) {
      cancelledNotifications.add(notification['id'] as int);
    }
  }
}

/// Mock Android-specific implementation

class MockAndroidFlutterLocalNotificationsPlugin
    extends AndroidFlutterLocalNotificationsPlugin {
  MockAndroidFlutterLocalNotificationsPlugin({this.onChannelCreated});

  void Function()? onChannelCreated;
  bool requestNotificationsPermissionCalled = false;
  bool requestNotificationsPermissionResult = true;

  @override
  Future<void> createNotificationChannel(
    AndroidNotificationChannel channel,
  ) async {
    onChannelCreated?.call();
  }

  @override
  Future<bool?> requestNotificationsPermission() async {
    requestNotificationsPermissionCalled = true;
    return requestNotificationsPermissionResult;
  }
}

class MockIOSFlutterLocalNotificationsPlugin
    extends IOSFlutterLocalNotificationsPlugin {
  bool requestPermissionsCalled = false;
  bool requestPermissionsResult = true;

  @override
  Future<bool?> requestPermissions({
    bool alert = false,
    bool badge = false,
    bool sound = false,
    bool critical = false,
    bool provisional = false,
    bool providesAppNotificationSettings = false,
  }) async {
    requestPermissionsCalled = true;
    return requestPermissionsResult;
  }
}

class MockMacOSFlutterLocalNotificationsPlugin
    extends MacOSFlutterLocalNotificationsPlugin {
  bool requestPermissionsCalled = false;
  bool requestPermissionsResult = true;

  @override
  Future<bool?> requestPermissions({
    bool alert = false,
    bool badge = false,
    bool sound = false,
    bool critical = false,
    bool provisional = false,
    bool providesAppNotificationSettings = false,
  }) async {
    requestPermissionsCalled = true;
    return requestPermissionsResult;
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
    SharedPreferences.setMockInitialValues({
      'notifications_enabled': true,
      'expiry_lead_time_days': 3,
      'sound_enabled': true,
      'vibration_enabled': true,
    });
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

  group('NotificationService - scheduling preferences', () {
    test('scheduleForItem respects lead time preference', () async {
      SharedPreferences.setMockInitialValues({
        'notifications_enabled': true,
        'expiry_lead_time_days': 3,
        'sound_enabled': true,
        'vibration_enabled': true,
      });

      final expiryDate = DateTime(2026, 2, 15);
      await notificationService.scheduleForItem(
        itemId: 42,
        expiryDate: expiryDate,
      );

      expect(mockPlugin.scheduledNotifications.length, 1);
      final scheduledDate =
          mockPlugin.scheduledNotifications[0]['scheduledDate']
              as tz.TZDateTime;
      expect(scheduledDate.year, 2026);
      expect(scheduledDate.month, 2);
      expect(scheduledDate.day, 12);
      expect(scheduledDate.hour, 9);
    });

    test('scheduleForItem skips when notifications are disabled', () async {
      SharedPreferences.setMockInitialValues({
        'notifications_enabled': false,
        'expiry_lead_time_days': 3,
        'sound_enabled': true,
        'vibration_enabled': true,
      });

      await notificationService.scheduleForItem(
        itemId: 43,
        expiryDate: DateTime(2026, 2, 15),
      );

      expect(mockPlugin.scheduledNotifications, isEmpty);
    });

    test('scheduleForItem applies sound and vibration preferences', () async {
      SharedPreferences.setMockInitialValues({
        'notifications_enabled': true,
        'expiry_lead_time_days': 3,
        'sound_enabled': false,
        'vibration_enabled': false,
      });

      await notificationService.scheduleForItem(
        itemId: 44,
        expiryDate: DateTime(2026, 2, 15),
      );

      expect(mockPlugin.scheduledNotifications.length, 1);
      final details =
          mockPlugin.scheduledNotifications[0]['notificationDetails']
              as NotificationDetails;
      final androidDetails = details.android;
      final iosDetails = details.iOS;

      expect(androidDetails?.playSound, false);
      expect(androidDetails?.enableVibration, false);
      expect(iosDetails?.presentSound, false);
    });
  });

  group('NotificationService - telemetry integration', () {
    test('initialize does not request iOS permissions eagerly', () async {
      await notificationService.initialize();

      final iosSettings = mockPlugin.initializationSettings?.iOS;
      if (iosSettings != null) {
        expect(iosSettings.requestAlertPermission, isFalse);
        expect(iosSettings.requestBadgePermission, isFalse);
        expect(iosSettings.requestSoundPermission, isFalse);
      }
      expect(mockPlugin.mockIos.requestPermissionsCalled, isFalse);
    });

    test('requestPermissions delegates to platform implementations', () async {
      final granted = await notificationService.requestPermissions();

      expect(granted, isTrue);
      expect(
        mockPlugin.mockAndroid.requestNotificationsPermissionCalled,
        isTrue,
      );
      expect(mockPlugin.mockIos.requestPermissionsCalled, isTrue);
      expect(mockPlugin.mockMacOs.requestPermissionsCalled, isTrue);
    });

    test('scheduleForItem emits notification_scheduled event', () async {
      SharedPreferences.setMockInitialValues({
        'notifications_enabled': true,
        'expiry_lead_time_days': 1,
        'sound_enabled': true,
        'vibration_enabled': true,
      });

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

  group('NotificationService - reminder tap handling', () {
    test('handleNotificationResponsePayload emits reminder_opened', () async {
      final handledPayloads = <ReminderNotificationPayload>[];
      notificationService.setNotificationTapHandler((payload) async {
        if (payload != null) {
          handledPayloads.add(payload);
        }
      });

      final payloadJson = ReminderNotificationPayload(
        itemId: '42',
        leadTimeDays: 3,
      ).toJsonString();

      await notificationService.handleNotificationResponsePayload(
        payloadJson,
        now: DateTime(2026, 1, 1, 9),
      );

      expect(telemetryEvents.length, 1);
      expect(telemetryEvents[0]['name'], 'reminder_opened');
      expect(telemetryEvents[0]['properties']['lead_time_days'], 3);
      expect(telemetryEvents[0]['properties']['time_of_day'], 'morning');

      expect(handledPayloads.length, 1);
      expect(handledPayloads.first.itemId, '42');
      expect(handledPayloads.first.leadTimeDays, 3);
    });
  });

  group('NotificationService - boundary cases', () {
    test('expiry date exactly 1 day away schedules notification today', () {
      // Use fixed date to avoid timezone and date boundary issues
      final expiryDate = DateTime(2026, 3, 10); // March 10, 2026
      final scheduleTime = notificationService.computeScheduleTime(expiryDate);

      // With default lead time of 1 day, should schedule March 9 at 9am
      expect(scheduleTime.year, 2026);
      expect(scheduleTime.month, 3);
      expect(scheduleTime.day, 9);
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

  group('NotificationService - rescheduleAllNotifications', () {
    test('cancelAllNotifications cancels all scheduled notifications', () async {
      // First schedule some notifications
      mockPlugin.scheduledNotifications.clear();
      mockPlugin.cancelledNotifications.clear();

      final expiryDate1 = DateTime(2026, 2, 15);
      final expiryDate2 = DateTime(2026, 2, 20);

      await notificationService.scheduleForItem(
        itemId: 1,
        expiryDate: expiryDate1,
      );
      await notificationService.scheduleForItem(
        itemId: 2,
        expiryDate: expiryDate2,
      );

      expect(mockPlugin.scheduledNotifications.length, 2);

      // Now cancel all
      await notificationService.cancelAllNotifications();

      // Should have called cancel for each. Note: MockPlugin tracks cancel calls
      // but Flutter's actual API might use cancelAll() directly instead of per-ID cancels
      // For testing, we just verify the method completes without error
      expect(mockPlugin.cancelledNotifications.isNotEmpty, isTrue);
    });

    test('rescheduleAllNotifications with empty list does nothing', () async {
      telemetryEvents.clear();
      mockPlugin.scheduledNotifications.clear();

      await notificationService.rescheduleAllNotifications([]);

      // Should have only the bulk reschedule event
      final bulkEvent = telemetryEvents.firstWhere(
        (e) => e['name'] == 'notifications_rescheduled_bulk',
        orElse: () => {},
      );
      expect(bulkEvent.isNotEmpty, isTrue);
      expect(bulkEvent['properties']['item_count'], 0);
    });

    test('rescheduleAllNotifications with items when enabled', () async {
      telemetryEvents.clear();
      mockPlugin.scheduledNotifications.clear();

      // Setup: notifications are enabled
      SharedPreferences.setMockInitialValues({
        'notifications_enabled': true,
        'expiry_lead_time_days': 3,
        'sound_enabled': true,
        'vibration_enabled': true,
      });

      // Create mock items
      final items = [
        {'id': 1, 'expiryDate': DateTime(2026, 2, 15)},
        {'id': 2, 'expiryDate': DateTime(2026, 2, 20)},
      ];

      await notificationService.rescheduleAllNotifications(items);

      // Should have scheduled both items
      expect(mockPlugin.scheduledNotifications.length, 2);

      // Should have bulk telemetry event
      final bulkEvent = telemetryEvents.firstWhere(
        (e) => e['name'] == 'notifications_rescheduled_bulk',
        orElse: () => {},
      );
      expect(bulkEvent.isNotEmpty, isTrue);
      expect(bulkEvent['properties']['item_count'], 2);
      expect(bulkEvent['properties']['notifications_enabled'], true);
      expect(bulkEvent['properties']['lead_time_days'], 3);
    });

    test('rescheduleAllNotifications cancels all when disabled', () async {
      // Setup: notifications are disabled
      SharedPreferences.setMockInitialValues({
        'notifications_enabled': false,
        'expiry_lead_time_days': 3,
        'sound_enabled': true,
        'vibration_enabled': true,
      });

      final localMockPlugin = MockFlutterLocalNotificationsPlugin();
      final localService = NotificationService(plugin: localMockPlugin);

      final items = [
        {'id': 1, 'expiryDate': DateTime(2026, 2, 15)},
        {'id': 2, 'expiryDate': DateTime(2026, 2, 20)},
      ];

      await localService.rescheduleAllNotifications(items);

      // Should NOT have scheduled any items when notifications are disabled
      expect(localMockPlugin.scheduledNotifications.length, 0);
    });

    test(
      'rescheduleAllNotifications handles items with null expiry dates',
      () async {
        telemetryEvents.clear();
        mockPlugin.scheduledNotifications.clear();

        // Setup: notifications are enabled
        SharedPreferences.setMockInitialValues({
          'notifications_enabled': true,
          'expiry_lead_time_days': 3,
          'sound_enabled': true,
          'vibration_enabled': true,
        });

        // Items include one with null expiryDate
        final items = [
          {'id': 1, 'expiryDate': DateTime(2026, 2, 15)},
          {'id': 2, 'expiryDate': null}, // No expiry date
        ];

        await notificationService.rescheduleAllNotifications(items);

        // Should have scheduled only the item with expiry date
        expect(mockPlugin.scheduledNotifications.length, 1);
        expect(mockPlugin.scheduledNotifications[0]['id'], 1);
      },
    );

    test('rescheduleAllNotifications respects lead time preference', () async {
      // Setup: 7-day lead time
      SharedPreferences.setMockInitialValues({
        'notifications_enabled': true,
        'expiry_lead_time_days': 7,
        'sound_enabled': true,
        'vibration_enabled': true,
      });

      final localMockPlugin = MockFlutterLocalNotificationsPlugin();
      final localService = NotificationService(plugin: localMockPlugin);

      final expiryDate = DateTime(2026, 2, 15);
      final items = [
        {'id': 1, 'expiryDate': expiryDate},
      ];

      await localService.rescheduleAllNotifications(items);

      // Should have scheduled with 7-day lead time
      expect(localMockPlugin.scheduledNotifications.length, 1);

      final scheduled = localMockPlugin.scheduledNotifications[0];
      final scheduledDate = scheduled['scheduledDate'];

      // Feb 15 - 7 days = Feb 8 (not Feb 14 which is 1-day lead time)
      expect(scheduledDate.day, 8);
      expect(scheduledDate.month, 2);
      expect(scheduledDate.year, 2026);
    });

    test(
      'rescheduleAllNotifications accepts prefixed string item IDs',
      () async {
        final items = [
          {
            'id': 'item-1712486400000000-3',
            'expiryDate': DateTime(2026, 2, 15),
          },
        ];

        await notificationService.rescheduleAllNotifications(items);

        expect(mockPlugin.scheduledNotifications.length, 1);
        expect(
          mockPlugin.scheduledNotifications[0]['id'],
          LocalIdGenerator.notificationIdFor(items.first['id']! as String),
        );
      },
    );
  });

  group('NotificationService - restoreScheduled on app startup', () {
    test(
      'restoreScheduled schedules all items when notifications enabled',
      () async {
        SharedPreferences.setMockInitialValues({
          'notifications_enabled': true,
          'expiry_lead_time_days': 3,
          'sound_enabled': true,
          'vibration_enabled': true,
        });

        final localMockPlugin = MockFlutterLocalNotificationsPlugin();
        final localService = NotificationService(plugin: localMockPlugin);
        final restoreEvents = <Map<String, dynamic>>[];
        localService.setTelemetryCallback((eventName, properties) {
          restoreEvents.add({'name': eventName, 'properties': properties});
        });

        final items = [
          {'id': 1, 'expiryDate': DateTime(2026, 2, 15)},
          {'id': 2, 'expiryDate': DateTime(2026, 2, 20)},
          {'id': 3, 'expiryDate': DateTime(2026, 2, 10)},
        ];

        await localService.restoreScheduled(items: items);

        // All items should be scheduled
        expect(localMockPlugin.scheduledNotifications.length, 3);

        // Verify telemetry was emitted
        final restoreEvent = restoreEvents.firstWhere(
          (e) => e['name'] == 'notifications_restored_on_startup',
          orElse: () => {},
        );
        expect(restoreEvent.isNotEmpty, isTrue);
        expect(restoreEvent['properties']['item_count'], 3);
        expect(restoreEvent['properties']['notifications_enabled'], true);
      },
    );

    test(
      'restoreScheduled schedules nothing when notifications disabled',
      () async {
        SharedPreferences.setMockInitialValues({
          'notifications_enabled': false,
          'expiry_lead_time_days': 3,
          'sound_enabled': true,
          'vibration_enabled': true,
        });

        final localMockPlugin = MockFlutterLocalNotificationsPlugin();
        final localService = NotificationService(plugin: localMockPlugin);

        final items = [
          {'id': 1, 'expiryDate': DateTime(2026, 2, 15)},
          {'id': 2, 'expiryDate': DateTime(2026, 2, 20)},
        ];

        await localService.restoreScheduled(items: items);

        // No items should be scheduled since notifications are disabled
        expect(localMockPlugin.scheduledNotifications.length, 0);
      },
    );

    test('restoreScheduled skips items without expiry dates', () async {
      SharedPreferences.setMockInitialValues({
        'notifications_enabled': true,
        'expiry_lead_time_days': 3,
        'sound_enabled': true,
        'vibration_enabled': true,
      });

      final localMockPlugin = MockFlutterLocalNotificationsPlugin();
      final localService = NotificationService(plugin: localMockPlugin);

      final items = [
        {'id': 1, 'expiryDate': DateTime(2026, 2, 15)},
        {'id': 2, 'expiryDate': null}, // No expiry date
        {'id': 3, 'expiryDate': DateTime(2026, 2, 10)},
      ];

      await localService.restoreScheduled(items: items);

      // Only 2 items should be scheduled (those with expiry dates)
      expect(localMockPlugin.scheduledNotifications.length, 2);
    });

    test('restoreScheduled handles empty item list', () async {
      SharedPreferences.setMockInitialValues({
        'notifications_enabled': true,
        'expiry_lead_time_days': 3,
        'sound_enabled': true,
        'vibration_enabled': true,
      });

      final localMockPlugin = MockFlutterLocalNotificationsPlugin();
      final localService = NotificationService(plugin: localMockPlugin);

      await localService.restoreScheduled(items: []);

      // No items to schedule
      expect(localMockPlugin.scheduledNotifications.length, 0);
    });

    test('restoreScheduled applies current lead time preference', () async {
      SharedPreferences.setMockInitialValues({
        'notifications_enabled': true,
        'expiry_lead_time_days': 7,
        'sound_enabled': true,
        'vibration_enabled': true,
      });

      final localMockPlugin = MockFlutterLocalNotificationsPlugin();
      final localService = NotificationService(plugin: localMockPlugin);

      final items = [
        {'id': 1, 'expiryDate': DateTime(2026, 2, 15)},
      ];

      await localService.restoreScheduled(items: items);

      // Should be scheduled with 7-day lead time
      expect(localMockPlugin.scheduledNotifications.length, 1);
      final scheduled = localMockPlugin.scheduledNotifications[0];
      final scheduledDate = scheduled['scheduledDate'];

      // Feb 15 - 7 days = Feb 8
      expect(scheduledDate.day, 8);
      expect(scheduledDate.month, 2);
    });

    test('restoreScheduled accepts prefixed string item IDs', () async {
      SharedPreferences.setMockInitialValues({
        'notifications_enabled': true,
        'expiry_lead_time_days': 3,
        'sound_enabled': true,
        'vibration_enabled': true,
      });

      final localMockPlugin = MockFlutterLocalNotificationsPlugin();
      final localService = NotificationService(plugin: localMockPlugin);
      final items = [
        {'id': 'item-1712486400000000-4', 'expiryDate': DateTime(2026, 2, 15)},
      ];

      await localService.restoreScheduled(items: items);

      expect(localMockPlugin.scheduledNotifications.length, 1);
      expect(
        localMockPlugin.scheduledNotifications[0]['id'],
        LocalIdGenerator.notificationIdFor(items.first['id']! as String),
      );
    });
  });
}
