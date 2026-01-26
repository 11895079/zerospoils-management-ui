library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../di/service_locator.dart' show telemetryClientProvider;
import '../di/repository_providers.dart';
import '../../data/services/backup_restore_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _persistDemoMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('demo_mode_enabled', enabled);
  }

  Future<void> _clearAllItems(WidgetRef ref) async {
    final repository = ref.read(itemRepositoryProvider);
    await repository.init();
    await repository.clear();
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    try {
      final telemetry = ref.read(telemetryClientProvider);

      // Let user choose destination (fallback to app documents if canceled)
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save backup as',
        fileName: 'zerospoils_backup.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      String resolvedPath;
      if (savePath != null) {
        resolvedPath = savePath;
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
        resolvedPath = '${directory.path}/zerospoils_backup_$timestamp.json';
      }

      final service = BackupRestoreService(telemetry: telemetry);
      final result = await service.exportToJson(resolvedPath);

      // Persist last backup metadata
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_backup_path', result.filePath);
      if (result.metadata != null) {
        await prefs.setString(
          'last_backup_at',
          result.metadata!.exportedAt.toIso8601String(),
        );
      }
      await prefs.setInt('last_backup_size', result.sizeBytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup saved to: ${result.filePath}'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> _loadLastBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('last_backup_path');
    final at = prefs.getString('last_backup_at');
    final size = prefs.getInt('last_backup_size');
    if (path == null || at == null || size == null) return null;
    return {'path': path, 'at': DateTime.tryParse(at), 'size': size};
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    try {
      final telemetry = ref.read(telemetryClientProvider);

      // Pick file
      final pickResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (pickResult == null || pickResult.files.single.path == null) return;

      final filePath = pickResult.files.single.path!;
      final service = BackupRestoreService(telemetry: telemetry);

      // Preview backup
      final preview = await service.previewRestore(filePath);

      if (!context.mounted) return;

      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Restore Backup'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('This will restore ${preview.itemCount} items.'),
              const SizedBox(height: 8),
              if (preview.requiresMigration)
                Text(
                  'Migration required from version ${preview.schemaVersionFrom}',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              const SizedBox(height: 8),
              const Text(
                'All existing data will be replaced. Continue?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Restore'),
            ),
          ],
        ),
      );

      if (confirmed != true || !context.mounted) return;

      // Perform restore
      final restoreResult = await service.importFromJson(filePath);

      if (!context.mounted) return;

      if (restoreResult.success) {
        // Refresh inventory
        ref.invalidate(itemsFutureProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Restored ${restoreResult.itemsImported} items'
              '${restoreResult.migrationsApplied > 0 ? " (${restoreResult.migrationsApplied} migrations applied)" : ""}',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: ${restoreResult.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demoEnabled = ref.watch(demoModeProvider);
    final hasManualItems = ref.watch(hasManualItemsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Settings', style: AppTextStyles.h3),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x11000000),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Demo Mode', style: AppTextStyles.h4),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        hasManualItems
                            ? 'Demo mode is disabled after manual items are added.'
                            : 'Preload sample items for quick exploration. Will turn off automatically after you add your first item.',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: demoEnabled,
                  onChanged: hasManualItems
                      ? null
                      : (value) async {
                          // Update provider and persist
                          ref.read(demoModeProvider.notifier).state = value;
                          await _persistDemoMode(value);

                          // Clear items if turning off demo mode
                          if (!value) {
                            await _clearAllItems(ref);
                          }

                          // Force refresh of inventory list
                          ref.invalidate(itemsFutureProvider);

                          // Show feedback
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  value
                                      ? 'Demo mode enabled'
                                      : 'Demo mode disabled',
                                ),
                              ),
                            );
                          }
                        },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Data Management', style: AppTextStyles.h4),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x11000000),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FutureBuilder<Map<String, dynamic>?>(
                  future: _loadLastBackup(),
                  builder: (context, snapshot) {
                    final info = snapshot.data;
                    if (info == null) return const SizedBox.shrink();
                    final at = info['at'] as DateTime?;
                    final size = info['size'] as int?;
                    final path = info['path'] as String?;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text(
                        'Last backup: '
                        '${at != null ? at.toLocal().toString() : 'unknown'}'
                        '${size != null ? ' • ${(size / 1024).toStringAsFixed(1)} KB' : ''}'
                        '${path != null ? '\n$path' : ''}',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  },
                ),
                ElevatedButton.icon(
                  onPressed: () => _exportBackup(context, ref),
                  icon: const Icon(Icons.backup),
                  label: const Text('Backup Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: () => _importBackup(context, ref),
                  icon: const Icon(Icons.restore),
                  label: const Text('Restore from Backup'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('About', style: AppTextStyles.h4),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'ZeroSpoils helps households reduce food waste by tracking inventory, expiry, and usage.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
