import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Widget to request notification permissions on first run or via settings
class NotificationPermissionPrompt extends ConsumerWidget {
  final VoidCallback? onGranted;
  final VoidCallback? onDenied;

  const NotificationPermissionPrompt({
    super.key,
    this.onGranted,
    this.onDenied,
  });

  Future<void> _requestPermissions(BuildContext context) async {
    final plugin = FlutterLocalNotificationsPlugin();
    // Android: No explicit permission request via plugin; handled by OS or use permission_handler if needed
    // iOS
    final iosResult = await plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    // macOS
    final macResult = await plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    // If any platform grants permission, treat as granted
    if (iosResult == true || macResult == true) {
      if (onGranted != null) onGranted!();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Notifications enabled!')));
      }
    } else {
      if (onDenied != null) onDenied!();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notifications permission denied.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Text('Enable Notifications'),
      content: const Text(
        'To get reminders for expiring items, please enable notifications.',
      ),
      actions: [
        TextButton(
          onPressed: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) Navigator.of(context).pop();
            });
          },
          child: const Text('Not now'),
        ),
        ElevatedButton(
          onPressed: () async {
            await _requestPermissions(context);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) Navigator.of(context).pop();
            });
          },
          child: const Text('Enable'),
        ),
      ],
    );
  }
}
