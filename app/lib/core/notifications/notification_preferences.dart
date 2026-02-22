import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferences {
  const NotificationPreferences({
    required this.notificationsEnabled,
    required this.leadTimeDays,
    required this.soundEnabled,
    required this.vibrationEnabled,
  });

  final bool notificationsEnabled;
  final int leadTimeDays;
  final bool soundEnabled;
  final bool vibrationEnabled;
}

class NotificationPreferencesStore {
  static const String notificationsEnabledKey = 'notifications_enabled';
  static const String leadTimeDaysKey = 'expiry_lead_time_days';
  static const String soundEnabledKey = 'sound_enabled';
  static const String vibrationEnabledKey = 'vibration_enabled';

  Future<NotificationPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationPreferences(
      notificationsEnabled: prefs.getBool(notificationsEnabledKey) ?? true,
      leadTimeDays: prefs.getInt(leadTimeDaysKey) ?? 3,
      soundEnabled: prefs.getBool(soundEnabledKey) ?? true,
      vibrationEnabled: prefs.getBool(vibrationEnabledKey) ?? true,
    );
  }

  Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(notificationsEnabledKey, value);
  }

  Future<void> setLeadTimeDays(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(leadTimeDaysKey, value);
  }

  Future<void> setSoundEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(soundEnabledKey, value);
  }

  Future<void> setVibrationEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(vibrationEnabledKey, value);
  }
}
