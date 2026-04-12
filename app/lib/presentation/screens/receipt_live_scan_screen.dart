library;

import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/models/receipt_line_item.dart';
import '../../domain/utils/receipt_parser.dart';

class ReceiptLiveScanScreen extends StatefulWidget {
  const ReceiptLiveScanScreen({
    super.key,
    this.skipCameraInitialization = false,
    this.debugOverlayItems = const [],
    this.debugImageSize,
  });

  final bool skipCameraInitialization;
  final List<ReceiptLineItem> debugOverlayItems;
  final Size? debugImageSize;

  @override
  State<ReceiptLiveScanScreen> createState() => _ReceiptLiveScanScreenState();
}

class _ReceiptLiveScanScreenState extends State<ReceiptLiveScanScreen> {
  static const Map<DeviceOrientation, int> _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  final ReceiptParser _parser = ReceiptParser();

  CameraController? _cameraController;
  TextRecognizer? _textRecognizer;
  bool _initializing = true;
  bool _capturing = false;
  bool _processingFrame = false;
  bool _streaming = false;
  bool _torchEnabled = false;
  String? _errorMessage;
  String? _liveText;
  List<ReceiptLineItem> _liveItems = const [];
  Size? _imageSize;
  int _frameCounter = 0;

  bool get _usesIosCameraFormat =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    if (widget.skipCameraInitialization) {
      _liveItems = widget.debugOverlayItems;
      _imageSize = widget.debugImageSize;
      _initializing = false;
      return;
    }
    unawaited(_initializeCamera());
  }

  @override
  void dispose() {
    unawaited(_stopImageStream());
    _cameraController?.dispose();
    _textRecognizer?.close();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('camera_unavailable', 'No camera available');
      }

      final selectedCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: _usesIosCameraFormat
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.nv21,
      );

      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);

      _cameraController = controller;
      _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

      if (!mounted) {
        return;
      }

      setState(() {
        _initializing = false;
        _torchEnabled = false;
      });

      await _startImageStream();
    } on CameraException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _initializing = false;
        _errorMessage = _mapCameraException(error);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _initializing = false;
        _errorMessage = 'Unable to start the live receipt scanner';
      });
    }
  }

  Future<void> _startImageStream() async {
    final controller = _cameraController;
    if (controller == null || _streaming || !controller.value.isInitialized) {
      return;
    }

    await controller.startImageStream(_processCameraImage);
    _streaming = true;
  }

  Future<void> _stopImageStream() async {
    final controller = _cameraController;
    if (controller == null || !_streaming) {
      return;
    }

    await controller.stopImageStream();
    _streaming = false;
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (!mounted || _capturing || _processingFrame) {
      return;
    }

    _frameCounter = (_frameCounter + 1) % 6;
    if (_frameCounter != 0) {
      return;
    }

    final inputImage = _buildInputImage(image);
    final textRecognizer = _textRecognizer;
    if (inputImage == null || textRecognizer == null) {
      return;
    }

    _processingFrame = true;
    try {
      final recognized = await textRecognizer.processImage(inputImage);
      final ocrLines = recognized.blocks
          .expand((block) => block.lines)
          .map(
            (line) => ReceiptOcrLine(
              text: line.text,
              box: ReceiptOcrBox(
                left: line.boundingBox.left,
                top: line.boundingBox.top,
                right: line.boundingBox.right,
                bottom: line.boundingBox.bottom,
              ),
            ),
          )
          .toList();

      final items = ocrLines.isEmpty
          ? _parser.parse(recognized.text)
          : _parser.parseOcrLines(ocrLines);

      if (!mounted) {
        return;
      }

      setState(() {
        _imageSize = Size(image.width.toDouble(), image.height.toDouble());
        _liveText = recognized.text.trim().isEmpty
            ? null
            : recognized.text.trim();
        _liveItems = items;
      });
    } catch (_) {
      // Keep the live preview active through transient OCR failures.
    } finally {
      _processingFrame = false;
    }
  }

  InputImage? _buildInputImage(CameraImage image) {
    final controller = _cameraController;
    if (controller == null || image.planes.isEmpty) {
      return null;
    }

    final rotation = _inputImageRotation(controller);
    if (rotation == null) {
      return null;
    }

    final format = _usesIosCameraFormat
        ? InputImageFormat.bgra8888
        : InputImageFormat.nv21;

    final bytes = _usesIosCameraFormat
        ? image.planes.first.bytes
        : _combinePlanes(image);

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  Uint8List _combinePlanes(CameraImage image) {
    final buffer = BytesBuilder(copy: false);
    for (final plane in image.planes) {
      buffer.add(plane.bytes);
    }
    return buffer.toBytes();
  }

  InputImageRotation? _inputImageRotation(CameraController controller) {
    if (_usesIosCameraFormat) {
      return InputImageRotationValue.fromRawValue(
        controller.description.sensorOrientation,
      );
    }

    final deviceRotation =
        _orientations[controller.value.deviceOrientation] ?? 0;
    final sensorRotation = controller.description.sensorOrientation;
    final rotationCompensation =
        controller.description.lensDirection == CameraLensDirection.front
        ? (sensorRotation + deviceRotation) % 360
        : (sensorRotation - deviceRotation + 360) % 360;

    return InputImageRotationValue.fromRawValue(rotationCompensation);
  }

  Future<void> _capturePhoto() async {
    final controller = _cameraController;
    if (controller == null || _capturing) {
      return;
    }

    setState(() => _capturing = true);
    try {
      await _stopImageStream();
      final photo = await controller.takePicture();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(photo);
    } on CameraException catch (error) {
      _showSnack(_mapCameraException(error));
      await _startImageStream();
    } catch (_) {
      _showSnack('Unable to capture receipt photo');
      await _startImageStream();
    } finally {
      if (mounted) {
        setState(() => _capturing = false);
      }
    }
  }

  Future<void> _toggleTorch() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    final nextTorchEnabled = !_torchEnabled;
    try {
      await controller.setFlashMode(
        nextTorchEnabled ? FlashMode.torch : FlashMode.off,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _torchEnabled = nextTorchEnabled;
      });
    } on CameraException {
      _showSnack('Torch is not available on this device');
    }
  }

  String _mapCameraException(CameraException error) {
    final code = error.code.toLowerCase();
    if (code.contains('denied') || code.contains('permission')) {
      return 'Camera permission denied. Enable it in Settings to live scan receipts.';
    }
    return 'Unable to start the live receipt scanner';
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Live Receipt Scan')),
      body: _initializing
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorState()
          : Padding(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildScanStatusCard(theme),
                  const SizedBox(height: AppSpacing.sm),
                  _buildPreview(theme),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _liveItems.isEmpty
                              ? 'No sale items locked yet'
                              : '${_liveItems.length} sale items highlighted live',
                          key: const Key('receipt_live_scan_summary'),
                          style: AppTextStyles.h4,
                        ),
                      ),
                      IconButton(
                        key: const Key('receipt_live_scan_torch_button'),
                        tooltip: _torchEnabled
                            ? 'Turn torch off'
                            : 'Turn torch on',
                        onPressed: widget.skipCameraInitialization
                            ? null
                            : _toggleTorch,
                        icon: Icon(
                          _torchEnabled
                              ? Icons.flashlight_off_outlined
                              : Icons.flashlight_on_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Green boxes mark sale lines the parser currently trusts. Savings, HST, totals, and rewards lines are excluded live.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Hold the full width of the receipt steady in frame. Multi-line items stay grouped when the description and price line remain visible together.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton.icon(
                          key: const Key('receipt_live_scan_capture_button'),
                          onPressed:
                              widget.skipCameraInitialization || _capturing
                              ? null
                              : _capturePhoto,
                          icon: _capturing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.camera_alt_outlined),
                          label: const Text('Capture Receipt'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPreview(ThemeData theme) {
    final controller = _cameraController;
    final previewChild = widget.skipCameraInitialization
        ? DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            child: Center(
              child: Text(
                'Live receipt preview',
                style: theme.textTheme.titleMedium,
              ),
            ),
          )
        : (controller == null || !controller.value.isInitialized)
        ? _buildErrorState()
        : CameraPreview(controller);

    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Stack(
          fit: StackFit.expand,
          children: [
            previewChild,
            ReceiptLiveOcrOverlay(
              key: const Key('receipt_live_scan_overlay'),
              items: _liveItems,
              imageSize: _imageSize,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanStatusCard(ThemeData theme) {
    return Container(
      key: const Key('receipt_live_scan_status_card'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _liveItems.isEmpty
                ? Icons.receipt_long_outlined
                : Icons.check_circle_outline,
            size: 18,
            color: _liveItems.isEmpty
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _liveItems.isEmpty
                      ? 'Point the camera at receipt line items'
                      : 'Live AR active — ${_liveItems.length} item${_liveItems.length == 1 ? '' : 's'} detected',
                  style: AppTextStyles.body,
                ),
                if (_liveText != null && _liveText!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _liveText!,
                    key: const Key('receipt_live_scan_ocr_text'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(_errorMessage ?? 'Unable to start the live receipt scanner'),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}

class ReceiptLiveOcrOverlay extends StatelessWidget {
  const ReceiptLiveOcrOverlay({
    super.key,
    required this.items,
    required this.imageSize,
  });

  final List<ReceiptLineItem> items;
  final Size? imageSize;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty || imageSize == null) {
      return const SizedBox.shrink();
    }

    final sourceWidth = imageSize!.width <= 0 ? 1.0 : imageSize!.width;
    final sourceHeight = imageSize!.height <= 0 ? 1.0 : imageSize!.height;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final box = item.ocrBox;
            if (box == null) {
              return const SizedBox.shrink();
            }

            return Positioned(
              key: Key('receipt_live_overlay_box_$index'),
              left: box.left / sourceWidth * constraints.maxWidth,
              top: box.top / sourceHeight * constraints.maxHeight,
              width: box.width / sourceWidth * constraints.maxWidth,
              height: box.height / sourceHeight * constraints.maxHeight,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.lightGreenAccent, width: 2),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.lightGreenAccent.withValues(alpha: 0.16),
                ),
                alignment: Alignment.topLeft,
                padding: const EdgeInsets.all(4),
                child: Text(
                  item.name,
                  key: Key('receipt_live_overlay_label_$index'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.black,
                    backgroundColor: Colors.lightGreenAccent,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
