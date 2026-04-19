import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Widget to request notification permissions on first run or via settings
class NotificationPermissionPrompt extends StatelessWidget {
  const NotificationPermissionPrompt({super.key});

  Future<bool> _requestPermissions() async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      final androidResult = await plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      final iosResult = await plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      final macResult = await plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      return androidResult == true || iosResult == true || macResult == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('notification_prompt'),
      title: const Text('Enable Notifications'),
      content: const Text(
        'To get reminders for expiring items, please enable notifications.',
      ),
      actions: [
        TextButton(
          key: const Key('notification_prompt_cancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Not now'),
        ),
        ElevatedButton(
          key: const Key('notification_prompt_confirm'),
          onPressed: () async {
            final granted = await _requestPermissions();
            if (!context.mounted) return;
            Navigator.of(context).pop(granted);
          },
          child: const Text('Enable'),
        ),
      ],
    );
  }
}
