import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerospoils/core/notifications/notification_preferences.dart';

void main() {
  group('NotificationPreferencesStore', () {
    test('loads defaults when no preferences are set', () async {
      SharedPreferences.setMockInitialValues({});

      final store = NotificationPreferencesStore();
      final prefs = await store.load();

      expect(prefs.notificationsEnabled, true);
      expect(prefs.leadTimeDays, 3);
      expect(prefs.soundEnabled, true);
      expect(prefs.vibrationEnabled, true);
    });

    test('persists and reloads notification preferences', () async {
      SharedPreferences.setMockInitialValues({});

      final store = NotificationPreferencesStore();
      await store.setNotificationsEnabled(false);
      await store.setLeadTimeDays(7);
      await store.setSoundEnabled(false);
      await store.setVibrationEnabled(false);

      final prefs = await store.load();

      expect(prefs.notificationsEnabled, false);
      expect(prefs.leadTimeDays, 7);
      expect(prefs.soundEnabled, false);
      expect(prefs.vibrationEnabled, false);
    });
  });
}
