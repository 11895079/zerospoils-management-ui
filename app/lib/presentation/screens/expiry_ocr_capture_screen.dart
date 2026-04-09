library;

import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/notifications/notification_preferences.dart';
import '../../core/ocr/expiry_date_ocr_service.dart';
import '../../core/ocr/expiry_ocr_capture_session.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/utils/expiry_date_parser.dart';
import '../../domain/utils/live_ocr_product_insight_extractor.dart';

const _expiryOcrAutoCaptureKey = 'expiry_ocr_auto_capture_enabled';

class ExpiryOcrCaptureScreen extends StatefulWidget {
  const ExpiryOcrCaptureScreen({super.key, required this.preferredDateFormat});

  final String preferredDateFormat;

  @override
  State<ExpiryOcrCaptureScreen> createState() => _ExpiryOcrCaptureScreenState();
}

class _ExpiryOcrCaptureScreenState extends State<ExpiryOcrCaptureScreen> {
  static const int _maxPhotos = 5;
  static const Map<DeviceOrientation, int> _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  final ExpiryDateParser _parser = const ExpiryDateParser();
  final LiveOcrProductInsightExtractor _insightExtractor =
      const LiveOcrProductInsightExtractor();

  CameraController? _cameraController;
  TextRecognizer? _textRecognizer;
  late ExpiryOcrCaptureSession _captureSession;

  final List<XFile> _photos = [];
  final Map<String, Uint8List> _photoThumbnailBytes = {};
  final List<ExpiryDateParseResult> _capturedDetections = [];

  bool _initializing = true;
  bool _capturing = false;
  bool _processingFrame = false;
  bool _streaming = false;
  bool _autoCaptureEnabled = true;
  bool _hapticsEnabled = true;
  bool _torchEnabled = false;
  String? _errorMessage;
  String? _liveText;
  ExpiryDateParseResult? _liveDetection;
  LiveOcrProductInsights _liveInsights = const LiveOcrProductInsights();
  ExpiryDateParseResult? _bestDetection;
  int _frameCounter = 0;

  bool get _usesIosCameraFormat =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    _captureSession = ExpiryOcrCaptureSession(autoCaptureEnabled: true);
    unawaited(_initializeCapture());
  }

  @override
  void dispose() {
    unawaited(_stopImageStream());
    _cameraController?.dispose();
    _textRecognizer?.close();
    super.dispose();
  }

  Future<void> _initializeCapture() async {
    await _loadPreferences();
    await _initializeCamera();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationPrefs = await NotificationPreferencesStore().load();

    _autoCaptureEnabled = prefs.getBool(_expiryOcrAutoCaptureKey) ?? true;
    _hapticsEnabled = notificationPrefs.vibrationEnabled;
    _captureSession.autoCaptureEnabled = _autoCaptureEnabled;
  }

  Future<void> _setAutoCaptureEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_expiryOcrAutoCaptureKey, enabled);
    if (!mounted) {
      return;
    }
    setState(() {
      _autoCaptureEnabled = enabled;
      _captureSession.autoCaptureEnabled = enabled;
    });
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
      _torchEnabled = false;

      _cameraController = controller;
      _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

      if (!mounted) {
        return;
      }

      setState(() {
        _initializing = false;
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
        _errorMessage = 'Unable to start the camera';
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
    if (!mounted ||
        _capturing ||
        _processingFrame ||
        _captureSession.hasReachedPhotoLimit) {
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
      final parsed = _parser.parse(
        recognized.text,
        preferredDateFormat: widget.preferredDateFormat,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _liveText = recognized.text.trim().isEmpty
            ? null
            : recognized.text.trim();
        _liveDetection = parsed;
        _liveInsights = _insightExtractor.extract(recognized.text);
      });

      if (parsed == null) {
        return;
      }

      final feedback = _captureSession.registerDetection(parsed);
      if (feedback.shouldTriggerHaptic && _hapticsEnabled) {
        HapticFeedback.selectionClick();
      }

      if (feedback.shouldAutoCapture) {
        await _capturePhoto(autoCaptured: true);
      }
    } catch (_) {
      // Ignore transient frame analysis failures and keep the live camera active.
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

  Future<void> _capturePhoto({required bool autoCaptured}) async {
    final controller = _cameraController;
    if (controller == null ||
        _capturing ||
        _captureSession.hasReachedPhotoLimit) {
      return;
    }

    setState(() {
      _capturing = true;
    });

    try {
      await _stopImageStream();
      final photo = await controller.takePicture();
      _photoThumbnailBytes[photo.path] = await photo.readAsBytes();
      final analysis = await _analyzeCapturedPhoto(photo.path);

      _captureSession.registerPhotoCaptured();
      _photos.add(photo);
      if (analysis.isSuccess) {
        _capturedDetections.add(analysis.parsed!);
      }
      _bestDetection = _selectBestDetection(_capturedDetections);

      if (analysis.isSuccess) {
        if (!mounted) {
          return;
        }
        Navigator.of(
          context,
        ).pop(ExpiryDateOcrScanResult.success(analysis.parsed!));
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        if (analysis.isSuccess) {
          _liveDetection = analysis.parsed;
        }
      });

      _showSnack(
        autoCaptured
            ? 'Captured angle ${_photos.length}/$_maxPhotos'
            : 'Captured angle ${_photos.length}/$_maxPhotos',
      );
    } on CameraException catch (error) {
      _showSnack(_mapCameraException(error));
    } catch (_) {
      _showSnack('Unable to capture photo');
    } finally {
      if (!_captureSession.hasReachedPhotoLimit) {
        await _startImageStream();
      }
      if (mounted) {
        setState(() {
          _capturing = false;
        });
      }
    }
  }

  Future<ExpiryDateOcrScanResult> _analyzeCapturedPhoto(String path) async {
    final textRecognizer = _textRecognizer;
    if (textRecognizer == null) {
      return const ExpiryDateOcrScanResult.failure(
        ExpiryDateOcrFailure.unavailable,
      );
    }

    try {
      final input = InputImage.fromFilePath(path);
      final result = await textRecognizer.processImage(input);
      final parsed = _parser.parse(
        result.text,
        preferredDateFormat: widget.preferredDateFormat,
      );
      if (parsed == null) {
        return const ExpiryDateOcrScanResult.failure(
          ExpiryDateOcrFailure.noDateDetected,
        );
      }
      return ExpiryDateOcrScanResult.success(parsed);
    } catch (_) {
      return const ExpiryDateOcrScanResult.failure(
        ExpiryDateOcrFailure.unknown,
      );
    }
  }

  ExpiryDateParseResult? _selectBestDetection(
    List<ExpiryDateParseResult> detections,
  ) {
    if (detections.isEmpty) {
      return null;
    }

    final grouped = <String, ({int count, ExpiryDateParseResult result})>{};
    for (final detection in detections) {
      final key = detection.date.toIso8601String();
      final current = grouped[key];
      grouped[key] = (count: (current?.count ?? 0) + 1, result: detection);
    }

    final ranked = grouped.values.toList()
      ..sort((a, b) {
        final countCompare = b.count.compareTo(a.count);
        if (countCompare != 0) {
          return countCompare;
        }
        return b.result.date.compareTo(a.result.date);
      });

    return ranked.first.result;
  }

  void _finishWithDetectedDate() {
    final detection = _bestDetection;
    if (detection == null) {
      Navigator.of(context).pop(
        const ExpiryDateOcrScanResult.failure(
          ExpiryDateOcrFailure.noDateDetected,
        ),
      );
      return;
    }

    Navigator.of(context).pop(ExpiryDateOcrScanResult.success(detection));
  }

  void _useManualEntry() {
    Navigator.of(context).pop(
      const ExpiryDateOcrScanResult.failure(
        ExpiryDateOcrFailure.noDateDetected,
      ),
    );
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
      return 'Camera permission denied. Enable it in Settings to scan expiry dates.';
    }
    return 'Unable to start the camera';
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
      appBar: AppBar(title: const Text('Scan Expiry Date')),
      body: _initializing
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorState()
          : Padding(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPreview(theme),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Photos ${_photos.length}/$_maxPhotos',
                          style: AppTextStyles.h4,
                        ),
                      ),
                      IconButton(
                        tooltip: _torchEnabled
                            ? 'Turn torch off'
                            : 'Turn torch on',
                        onPressed: _toggleTorch,
                        icon: Icon(
                          _torchEnabled
                              ? Icons.flashlight_off_outlined
                              : Icons.flashlight_on_outlined,
                        ),
                      ),
                      Switch.adaptive(
                        value: _autoCaptureEnabled,
                        onChanged: (value) => _setAutoCaptureEnabled(value),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const Text('Auto-capture'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _autoCaptureEnabled
                        ? 'Move the product to up to five angles. The app will capture when it can read the expiry text.'
                        : 'Auto-capture is off. Use the shutter button to capture up to five angles manually.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Embossed or stamped dates: tilt the package and use side lighting or the torch so the numbers cast a small shadow.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Canadian labels may show BB/MA before the date. Aim so both the label and date stay inside the frame.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: 72,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _photos.length,
                      separatorBuilder: (_, index) =>
                          const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final photo = _photos[index];
                        final thumbnailBytes = _photoThumbnailBytes[photo.path];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          child: thumbnailBytes == null
                              ? const SizedBox(width: 72, height: 72)
                              : Image.memory(
                                  thumbnailBytes,
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                ),
                        );
                      },
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _useManualEntry,
                          child: const Text('Use Manual Entry'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              _captureSession.hasReachedPhotoLimit || _capturing
                              ? null
                              : () => _capturePhoto(autoCaptured: false),
                          icon: _capturing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.camera_alt_outlined),
                          label: Text(
                            _autoCaptureEnabled
                                ? 'Capture Now'
                                : 'Manual Capture',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _bestDetection == null
                          ? null
                          : _finishWithDetectedDate,
                      child: Text(
                        _bestDetection == null
                            ? 'No expiry date detected yet'
                            : 'Use ${_bestDetection!.date.toLocal().toString().split(' ')[0]}',
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPreview(ThemeData theme) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return _buildErrorState();
    }

    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(controller),
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white54, width: 2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  margin: const EdgeInsets.all(AppSpacing.lg),
                ),
              ),
            ),
            Positioned(
              top: AppSpacing.md,
              left: AppSpacing.md,
              right: AppSpacing.md,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _liveDetection == null
                          ? 'Point the camera at the expiry text'
                          : 'Detected expiry: ${_liveDetection!.date.toLocal().toString().split(' ')[0]}',
                      style: AppTextStyles.body.copyWith(color: Colors.white),
                    ),
                    if (_liveInsights.productName != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Product: ${_liveInsights.productName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                    if (_liveInsights.brandName != null ||
                        _liveInsights.productType != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        [
                          if (_liveInsights.brandName != null)
                            'Brand: ${_liveInsights.brandName}',
                          if (_liveInsights.productType != null)
                            'Type: ${_liveInsights.productType}',
                        ].join('  •  '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                    if (_liveInsights.storageHint != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _liveInsights.storageHint!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                    if (_liveInsights.keywords.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Keywords: ${_liveInsights.keywords.take(3).join(', ')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _liveText == null || _liveText!.isEmpty
                          ? 'The app will vibrate when it recognizes a valid expiry date.'
                          : _liveText!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: AppSpacing.md,
              left: AppSpacing.md,
              right: AppSpacing.md,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Text(
                  'Aim at the expiry label, then tilt the package to capture up to five angles. For embossed dates, use side lighting or the torch.',
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
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
            const Icon(Icons.camera_alt_outlined, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(_errorMessage ?? 'Unable to start the camera'),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: _useManualEntry,
              child: const Text('Use Manual Entry'),
            ),
          ],
        ),
      ),
    );
  }
}
