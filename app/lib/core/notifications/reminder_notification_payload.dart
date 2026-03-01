import 'dart:convert';

/// Represents the payload attached to a reminder notification.
class ReminderNotificationPayload {
  final String itemId;
  final int leadTimeDays;

  ReminderNotificationPayload({
    required this.itemId,
    required this.leadTimeDays,
  });

  /// Try to parse a JSON string into a ReminderNotificationPayload.
  /// Returns null if the JSON is invalid or missing required fields.
  static ReminderNotificationPayload? tryParse(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate required fields and types
      if (json['item_id'] is! String) {
        return null;
      }
      if (json['lead_time_days'] is! int) {
        return null;
      }

      return ReminderNotificationPayload(
        itemId: json['item_id'] as String,
        leadTimeDays: json['lead_time_days'] as int,
      );
    } catch (e) {
      return null;
    }
  }

  /// Convert this payload to a JSON string for notification payload.
  String toJsonString() {
    return jsonEncode({'item_id': itemId, 'lead_time_days': leadTimeDays});
  }
}
