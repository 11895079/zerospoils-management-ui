library;

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class BarcodeCaptureScreen extends StatefulWidget {
  const BarcodeCaptureScreen({super.key});

  @override
  State<BarcodeCaptureScreen> createState() => _BarcodeCaptureScreenState();
}

class _BarcodeCaptureScreenState extends State<BarcodeCaptureScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
    ],
  );

  bool _isCompleting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleDetect(BarcodeCapture capture) async {
    if (_isCompleting) {
      return;
    }

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue?.trim() ?? barcode.displayValue?.trim();
      if (rawValue == null || rawValue.isEmpty) {
        continue;
      }

      _isCompleting = true;
      await _controller.stop();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(rawValue);
      return;
    }
  }

  Future<void> _enterBarcodeManually() async {
    final controller = TextEditingController();

    try {
      final value = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          key: const Key('barcode_manual_entry_dialog'),
          title: const Text('Enter barcode manually'),
          content: TextField(
            key: const Key('barcode_manual_entry_field'),
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'UPC, EAN, or GTIN',
              helperText: 'Use 8 to 14 digits.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: const Text('Use barcode'),
            ),
          ],
        ),
      );

      if (!mounted || value == null) {
        return;
      }

      Navigator.of(context).pop(value);
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan barcode'),
        actions: [
          IconButton(
            tooltip: 'Enter manually',
            onPressed: _enterBarcodeManually,
            icon: const Icon(Icons.keyboard_alt_outlined),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleDetect,
            errorBuilder: (context, error) {
              _errorMessage ??= error.errorDetails?.message;
              return ColoredBox(
                color: Colors.black,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _errorMessage ??
                              'Unable to access the camera scanner.',
                          style: AppTextStyles.body.copyWith(
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FilledButton.tonal(
                          onPressed: _enterBarcodeManually,
                          child: const Text('Enter barcode manually'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            overlayBuilder: (context, constraints) {
              return _BarcodeScannerOverlay(size: constraints.biggest);
            },
          ),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.xl,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.66),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: Colors.white24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Center the package barcode inside the frame.',
                      style: AppTextStyles.body.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'We will prefill product details first, then guide you into expiry capture.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24),
                            ),
                            onPressed: _enterBarcodeManually,
                            icon: const Icon(Icons.keyboard_alt_outlined),
                            label: const Text('Enter manually'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        IconButton(
                          tooltip: 'Toggle torch',
                          style: IconButton.styleFrom(
                            foregroundColor: theme.colorScheme.onPrimary,
                            backgroundColor: theme.colorScheme.primary,
                          ),
                          onPressed: () => _controller.toggleTorch(),
                          icon: const Icon(Icons.flashlight_on_outlined),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarcodeScannerOverlay extends StatelessWidget {
  const _BarcodeScannerOverlay({required this.size});

  final Size size;

  @override
  Widget build(BuildContext context) {
    final scanWidth = size.width * 0.78;
    final scanHeight = size.height * 0.2;

    return IgnorePointer(
      child: Center(
        child: Container(
          width: scanWidth,
          height: scanHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 18,
                spreadRadius: 6,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
