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
import 'onboarding_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _darkModeEnabled = false;
  bool _mealPlanningEnabled = false;
  bool _dataSyncEnabled = false;
  int _leadTimeDays = 3;
  String _dateFormat = 'MM/DD/YYYY';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      _darkModeEnabled = prefs.getBool('dark_mode_enabled') ?? false;
      _mealPlanningEnabled = prefs.getBool('meal_planning_enabled') ?? false;
      _dataSyncEnabled = prefs.getBool('data_sync_enabled') ?? false;
      _leadTimeDays = prefs.getInt('expiry_lead_time_days') ?? 3;
      _dateFormat = prefs.getString('date_format') ?? 'MM/DD/YYYY';
    });
  }

  Future<void> _persistDemoMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('demo_mode_enabled', enabled);
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
  Widget build(BuildContext context) {
    final demoEnabled = ref.watch(demoModeProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Settings', style: AppTextStyles.h3),
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          _buildSectionHeader('ACCOUNT & DATA'),
          _buildCard([
            _buildLinkTile(
              icon: Icons.person,
              label: 'Account',
              subtitle: 'View profile or sign in',
              onTap: () => _showSnack(context, 'Account coming soon'),
            ),
            _buildToggleTile(
              icon: Icons.cloud_sync,
              label: 'Data Sync',
              value: _dataSyncEnabled,
              onChanged: null,
              trailingLabel: 'Soon',
            ),
            _buildToggleTile(
              icon: Icons.bug_report,
              label: 'Demo Mode',
              value: demoEnabled,
              onChanged: (value) async {
                ref.read(demoModeProvider.notifier).state = value;
                await _persistDemoMode(value);
                ref.invalidate(itemsFutureProvider);
                if (!context.mounted) return;
                _showSnack(
                  context,
                  value ? 'Demo mode enabled' : 'Demo mode disabled',
                );
              },
            ),
            _buildLinkTile(
              icon: Icons.backup,
              label: 'Backup Data',
              subtitle: 'Export a local backup file',
              onTap: () => _exportBackup(context, ref),
            ),
            _buildLinkTile(
              icon: Icons.restore,
              label: 'Restore Backup',
              subtitle: 'Import a backup file',
              onTap: () => _importBackup(context, ref),
            ),
            _buildDangerTile(
              icon: Icons.delete_forever,
              label: 'Clear All Data',
              onTap: () => _confirmClearAllData(context),
            ),
          ]),
          const SizedBox(height: AppSpacing.xl),
          _buildSectionHeader('NOTIFICATIONS & ALERTS'),
          _buildCard([
            _buildToggleTile(
              icon: Icons.notifications_active,
              label: 'Notifications',
              value: _notificationsEnabled,
              onChanged: (value) => _setBool(
                key: 'notifications_enabled',
                value: value,
                onUpdate: () => _notificationsEnabled = value,
              ),
            ),
            _buildDropdownTile<int>(
              icon: Icons.timer,
              label: 'Expiry Warning Lead Time',
              value: _leadTimeDays,
              items: const [1, 3, 7],
              itemLabel: (val) => '$val days',
              onChanged: (value) => _setInt(
                key: 'expiry_lead_time_days',
                value: value,
                onUpdate: () => _leadTimeDays = value,
              ),
            ),
            _buildToggleTile(
              icon: Icons.music_note,
              label: 'Sound',
              value: _soundEnabled,
              onChanged: (value) => _setBool(
                key: 'sound_enabled',
                value: value,
                onUpdate: () => _soundEnabled = value,
              ),
            ),
            _buildToggleTile(
              icon: Icons.vibration,
              label: 'Vibration',
              value: _vibrationEnabled,
              onChanged: (value) => _setBool(
                key: 'vibration_enabled',
                value: value,
                onUpdate: () => _vibrationEnabled = value,
              ),
            ),
          ]),
          const SizedBox(height: AppSpacing.xl),
          _buildSectionHeader('PREFERENCES'),
          _buildCard([
            _buildToggleTile(
              icon: Icons.dark_mode,
              label: 'Dark Mode',
              value: _darkModeEnabled,
              onChanged: null,
              trailingLabel: 'Soon',
            ),
            _buildDropdownTile<String>(
              icon: Icons.date_range,
              label: 'Date Format',
              value: _dateFormat,
              items: const ['MM/DD/YYYY', 'DD/MM/YYYY', 'YYYY-MM-DD'],
              itemLabel: (val) => val,
              onChanged: (value) => _setString(
                key: 'date_format',
                value: value,
                onUpdate: () => _dateFormat = value,
              ),
            ),
            _buildToggleTile(
              icon: Icons.restaurant,
              label: 'Meal Planning',
              value: _mealPlanningEnabled,
              onChanged: null,
              trailingLabel: 'Soon',
            ),
          ]),
          const SizedBox(height: AppSpacing.xl),
          _buildSectionHeader('SUPPORT & FEEDBACK'),
          _buildCard([
            _buildLinkTile(
              icon: Icons.help_outline,
              label: 'Help & FAQ',
              onTap: () => _showSnack(context, 'Help center coming soon'),
            ),
            _buildLinkTile(
              icon: Icons.feedback_outlined,
              label: 'Send Feedback',
              onTap: () => _showSnack(context, 'Feedback form coming soon'),
            ),
            _buildLinkTile(
              icon: Icons.star_rate,
              label: 'Rate App',
              onTap: () => _showSnack(context, 'Thanks for the support!'),
            ),
            _buildLinkTile(
              icon: Icons.school_outlined,
              label: 'View Tutorial',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                );
              },
            ),
          ]),
          const SizedBox(height: AppSpacing.xl),
          _buildSectionHeader('LEGAL'),
          _buildCard([
            _buildLinkTile(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy Policy',
              onTap: () => _showSnack(context, 'Privacy policy coming soon'),
            ),
            _buildLinkTile(
              icon: Icons.gavel_outlined,
              label: 'Terms of Service',
              onTap: () => _showSnack(context, 'Terms coming soon'),
            ),
            _buildLinkTile(
              icon: Icons.info_outline,
              label: 'About',
              subtitle: 'ZeroSpoils v1.0.0',
              onTap: () =>
                  _showSnack(context, 'ZeroSpoils helps reduce food waste.'),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: AppTextStyles.body.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
      child: Column(children: _withDividers(children)),
    );
  }

  List<Widget> _withDividers(List<Widget> children) {
    final widgets = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      widgets.add(children[i]);
      if (i != children.length - 1) {
        widgets.add(const Divider(height: AppSpacing.lg));
      }
    }
    return widgets;
  }

  Widget _buildLinkTile({
    required IconData icon,
    required String label,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.textPrimary),
      title: Text(label, style: AppTextStyles.body),
      subtitle: subtitle == null
          ? null
          : Text(subtitle, style: AppTextStyles.bodySmall),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool>? onChanged,
    String? trailingLabel,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.textPrimary),
      title: Text(label, style: AppTextStyles.body),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingLabel != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Text(trailingLabel, style: AppTextStyles.bodySmall),
            ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildDropdownTile<T>({
    required IconData icon,
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.textPrimary),
      title: Text(label, style: AppTextStyles.body),
      trailing: DropdownButton<T>(
        value: value,
        underline: const SizedBox.shrink(),
        items: items
            .map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Text(itemLabel(item)),
              ),
            )
            .toList(),
        onChanged: (val) {
          if (val != null) onChanged(val);
        },
      ),
    );
  }

  Widget _buildDangerTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.danger),
      title: Text(
        label,
        style: AppTextStyles.body.copyWith(color: AppColors.danger),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.danger),
      onTap: onTap,
    );
  }

  Future<void> _setBool({
    required String key,
    required bool value,
    required VoidCallback onUpdate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    if (!mounted) return;
    setState(onUpdate);
  }

  Future<void> _setInt({
    required String key,
    required int value,
    required VoidCallback onUpdate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
    if (!mounted) return;
    setState(onUpdate);
  }

  Future<void> _setString({
    required String key,
    required String value,
    required VoidCallback onUpdate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
    if (!mounted) return;
    setState(onUpdate);
  }

  Future<void> _confirmClearAllData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
          'This will delete all items and settings on this device. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    final repo = ref.read(itemRepositoryProvider);
    await repo.init();
    await repo.clear();
    ref.invalidate(itemsFutureProvider);
    if (!context.mounted) return;
    _showSnack(context, 'All data cleared');
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
