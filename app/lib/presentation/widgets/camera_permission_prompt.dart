import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Widget to request camera permissions for expiry date OCR scanning
class CameraPermissionPrompt extends StatefulWidget {
  const CameraPermissionPrompt({super.key});

  @override
  State<CameraPermissionPrompt> createState() => _CameraPermissionPromptState();
}

class _CameraPermissionPromptState extends State<CameraPermissionPrompt> {
  bool _requesting = false;

  Future<bool> _requestPermissionResult() async {
    try {
      final status = await Permission.camera
          .request()
          .timeout(const Duration(seconds: 2), onTimeout: () {
            return PermissionStatus.denied;
          });
      if (status.isGranted || status.isLimited) {
        return true;
      }
      if (status.isPermanentlyDenied || status.isRestricted) {
        await openAppSettings();
      }
      return false;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _requestCameraPermission() async {
    setState(() {
      _requesting = true;
    });

    try {
      final granted = await _requestPermissionResult();
      if (!context.mounted) return;
      Navigator.of(context).pop(granted);
    } finally {
      if (!context.mounted) return;
      if (mounted) {
        setState(() {
          _requesting = false;
        });
      }
    }
  }

  void _deferPermission() {
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('camera_prompt'),
      title: const Text('Enable Camera'),
      content: const Text(
        'Camera access allows you to scan expiry dates from product labels and take photos of receipts. You can grant this later in Settings.',
      ),
      actions: [
        TextButton(
          key: const Key('camera_prompt_defer'),
          onPressed: _deferPermission,
          child: const Text('Maybe Later'),
        ),
        ElevatedButton(
          key: const Key('camera_prompt_confirm'),
          onPressed: _requesting ? null : _requestCameraPermission,
          child: _requesting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enable'),
        ),
      ],
    );
  }
}
