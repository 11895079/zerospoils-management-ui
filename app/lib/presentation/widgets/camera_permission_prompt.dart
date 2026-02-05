import 'package:flutter/material.dart';

/// Widget to request camera permissions for expiry date OCR scanning
class CameraPermissionPrompt extends StatefulWidget {
  final VoidCallback? onGranted;
  final VoidCallback? onDenied;

  const CameraPermissionPrompt({super.key, this.onGranted, this.onDenied});

  @override
  State<CameraPermissionPrompt> createState() => _CameraPermissionPromptState();
}

class _CameraPermissionPromptState extends State<CameraPermissionPrompt> {
  bool _requesting = false;

  Future<void> _requestCameraPermission() async {
    setState(() {
      _requesting = true;
    });

    try {
      // TODO: Integrate with permission_handler package for actual camera permission request
      // In production, use:
      // import 'package:permission_handler/permission_handler.dart';
      // final status = await Permission.camera.request();
      // if (status.isGranted) {
      //   widget.onGranted?.call();
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('Camera permission enabled')),
      //   );
      // } else if (status.isDenied) {
      //   widget.onDenied?.call();
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('Camera permission denied')),
      //   );
      // }

      // Placeholder: Simulate permission granted
      widget.onGranted?.call();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission enabled')),
      );
      if (!context.mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() {
          _requesting = false;
        });
      }
    }
  }

  void _deferPermission() {
    widget.onDenied?.call();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enable Camera'),
      content: const Text(
        'Camera access allows you to scan expiry dates from product labels and take photos of receipts. You can grant this later in Settings.',
      ),
      actions: [
        TextButton(
          onPressed: _deferPermission,
          child: const Text('Maybe Later'),
        ),
        ElevatedButton(
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
