import 'package:flutter_test/flutter_test.dart';
import 'package:zerospoils/core/notifications/reminder_notification_payload.dart';
import 'package:zerospoils/core/notifications/reminder_time_of_day.dart';

void main() {
  group('ReminderNotificationPayload', () {
    test('parses valid payload', () {
      const payloadJson = '{"item_id":"42","lead_time_days":3}';
      final payload = ReminderNotificationPayload.tryParse(payloadJson);

      expect(payload, isNotNull);
      expect(payload!.itemId, '42');
      expect(payload.leadTimeDays, 3);
    });

    test('returns null for invalid payload', () {
      const payloadJson = '{"item_id":42}';
      final payload = ReminderNotificationPayload.tryParse(payloadJson);

      expect(payload, isNull);
    });
  });

  group('timeOfDayFor', () {
    test('maps morning hours', () {
      final timeOfDay = timeOfDayFor(DateTime(2026, 1, 1, 9));
      expect(timeOfDay, 'morning');
    });

    test('maps afternoon hours', () {
      final timeOfDay = timeOfDayFor(DateTime(2026, 1, 1, 14));
      expect(timeOfDay, 'afternoon');
    });

    test('maps evening hours', () {
      final timeOfDay = timeOfDayFor(DateTime(2026, 1, 1, 20));
      expect(timeOfDay, 'evening');
    });

    test('maps late night to evening', () {
      final timeOfDay = timeOfDayFor(DateTime(2026, 1, 1, 2));
      expect(timeOfDay, 'evening');
    });
  });
}
