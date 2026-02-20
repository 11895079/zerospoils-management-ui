library;

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/models/receipt_batch.dart';
import '../../domain/utils/receipt_parser.dart';
import '../di/service_locator.dart' show telemetryClientProvider;
import '../widgets/app_drawer.dart';
import 'receipt_batch_review_screen.dart';

class ReceiptBatchCaptureScreen extends ConsumerStatefulWidget {
  final ReceiptBatchSource source;
  const ReceiptBatchCaptureScreen({super.key, required this.source});

  @override
  ConsumerState<ReceiptBatchCaptureScreen> createState() =>
      _ReceiptBatchCaptureScreenState();
}

class _ReceiptBatchCaptureScreenState
    extends ConsumerState<ReceiptBatchCaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _photos = [];
  late final String _batchId;
  bool _processing = false;
  bool _pickingPhoto = false;

  @override
  void initState() {
    super.initState();
    _batchId = _buildBatchId();
    ref.read(telemetryClientProvider).enqueue({
      'name': 'receipt_batch_started',
      'properties': {'source_screen': widget.source.name, 'batch_id': _batchId},
    });
  }

  Future<void> _addPhoto() async {
    if (_processing || _pickingPhoto) return;
    if (_photos.length >= 5) {
      _showSnack('Batch limit reached (5 photos max)');
      return;
    }

    setState(() => _pickingPhoto = true);
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo == null) return;

      if (!mounted) return;
      setState(() => _photos.add(photo));
      ref.read(telemetryClientProvider).enqueue({
        'name': 'receipt_photo_added',
        'properties': {'batch_id': _batchId, 'photo_index': _photos.length},
      });
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
  }

  Future<void> _processReceipts() async {
    if (_photos.isEmpty) {
      _showSnack('Add at least one receipt photo');
      return;
    }

    if (kIsWeb) {
      _showSnack('Receipt scanning is not available on web yet');
      return;
    }

    setState(() => _processing = true);
    final parser = ReceiptParser();
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final allItems = <String>[];
    final start = DateTime.now();

    try {
      for (final photo in _photos) {
        final input = InputImage.fromFilePath(photo.path);
        final result = await textRecognizer.processImage(input);
        allItems.add(result.text);
      }

      final parsedItems = <ParsedReceiptItem>[];
      for (final block in allItems) {
        final items = parser.parse(block);
        for (final item in items) {
          parsedItems.add(
            ParsedReceiptItem(name: item.name, price: item.price),
          );
        }
      }

      final duration = DateTime.now().difference(start).inMilliseconds;
      ref.read(telemetryClientProvider).enqueue({
        'name': 'receipt_batch_processed',
        'properties': {
          'batch_id': _batchId,
          'items_detected': parsedItems.length,
          'duration_ms': duration,
        },
      });

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReceiptBatchReviewScreen(
            source: widget.source,
            photoPaths: _photos.map((e) => e.path).toList(),
            parsedItems: parsedItems,
            batchId: _batchId,
          ),
        ),
      );
    } catch (e) {
      ref.read(telemetryClientProvider).enqueue({
        'name': 'receipt_batch_failed',
        'properties': {'batch_id': _batchId, 'reason': e.toString()},
      });
      _showSnack('Unable to process receipts');
    } finally {
      await textRecognizer.close();
      if (mounted) setState(() => _processing = false);
    }
  }

  String _buildBatchId() {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final suffix = Random().nextInt(9999).toString().padLeft(4, '0');
    return 'batch_$stamp$suffix';
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (intent) {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).maybePop();
              }
              return null;
            },
          ),
        },
        child: Scaffold(
          drawer: const AppDrawer(),
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            leading: Navigator.of(context).canPop()
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).maybePop(),
                  )
                : null,
            title: const Text('Batch Receipt Capture', style: AppTextStyles.h3),
          ),
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Photos (${_photos.length}/5)', style: AppTextStyles.h3),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: List.generate(5, (index) {
                    if (index < _photos.length) {
                      return _buildPhotoTile('Photo ${index + 1}');
                    }
                    return _buildAddTile();
                  }),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Capture clear photos of each receipt section. Max 5 photos.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _processing || _pickingPhoto
                        ? null
                        : _processReceipts,
                    child: _processing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Process Receipts'),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _processing || _pickingPhoto ? null : _addPhoto,
            backgroundColor: AppColors.primary,
            child: _processing || _pickingPhoto
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.camera_alt, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoTile(String label) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(child: Text(label, style: AppTextStyles.caption)),
    );
  }

  Widget _buildAddTile() {
    return GestureDetector(
      onTap: _processing || _pickingPhoto ? null : _addPhoto,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Icon(Icons.add, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
