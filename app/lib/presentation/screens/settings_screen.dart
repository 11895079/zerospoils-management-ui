library;

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/feedback/feedback_service.dart';
import '../../core/feedback/feedback_providers.dart';
import '../../core/notifications/notification_preferences.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/feature_flags/feature_flag_key.dart';
import '../../core/feature_flags/feature_flags_provider.dart';
import '../di/service_locator.dart'
    show telemetryClientProvider, analyticsConsentProvider;
import '../di/repository_providers.dart';
import '../di/theme_providers.dart';
import '../../data/services/backup_restore_service.dart';
import '../../core/auth/auth_providers.dart';
import '../../core/auth/firebase_auth_service.dart';
import 'onboarding_screen.dart';
import '../widgets/feedback_drawer.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  StreamSubscription<User?>? _authStateSubscription;
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _darkModeEnabled = false;
  bool _mealPlanningEnabled = false;
  bool _dataSyncEnabled = false;
  bool _analyticsConsent = true;
  bool _feedbackHapticEnabled = true;
  bool _feedbackAudioEnabled = true;
  double _feedbackBeepVolume = 0.8;
  HapticIntensity _feedbackHapticIntensity = HapticIntensity.medium;
  bool _feedbackBarcodeEnabled = true;
  bool _feedbackExpiryEnabled = true;
  bool _feedbackReceiptEnabled = true;
  bool _feedbackProduceEnabled = true;
  int _leadTimeDays = 3;
  String _dateFormat = 'MM/DD/YYYY';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    // Eagerly start the FeedbackService FutureProvider so it is resolved by
    // the time the user interacts with the Feedback & Sounds toggles.
    ref.read(feedbackServiceProvider);
    try {
      _authStateSubscription = ref
          .read(firebaseAuthServiceProvider)
          .authStateChanges
          .listen((_) {
            if (!mounted) return;
            setState(() {});
          });
    } catch (e) {
      debugPrint('[Settings] Auth listener unavailable: $e');
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled =
          prefs.getBool(NotificationPreferencesStore.notificationsEnabledKey) ??
          true;
      _soundEnabled =
          prefs.getBool(NotificationPreferencesStore.soundEnabledKey) ?? true;
      _vibrationEnabled =
          prefs.getBool(NotificationPreferencesStore.vibrationEnabledKey) ??
          true;
      _darkModeEnabled = prefs.getBool('dark_mode_enabled') ?? false;
      _mealPlanningEnabled = prefs.getBool('meal_planning_enabled') ?? false;
      _dataSyncEnabled = prefs.getBool('data_sync_enabled') ?? false;
      _analyticsConsent = prefs.getBool('analytics_consent') ?? true;
      _feedbackHapticEnabled = prefs.getBool('feedback_haptic_enabled') ?? true;
      _feedbackAudioEnabled = prefs.getBool('feedback_audio_enabled') ?? true;
      _feedbackBeepVolume = prefs.getDouble('feedback_beep_volume') ?? 0.8;
      _feedbackHapticIntensity = switch (prefs.getString(
        'feedback_haptic_intensity',
      )) {
        'light' => HapticIntensity.light,
        'heavy' => HapticIntensity.heavy,
        _ => HapticIntensity.medium,
      };
      _feedbackBarcodeEnabled =
          prefs.getBool('feedback_scanner_barcode_enabled') ?? true;
      _feedbackExpiryEnabled =
          prefs.getBool('feedback_scanner_expiry_enabled') ?? true;
      _feedbackReceiptEnabled =
          prefs.getBool('feedback_scanner_receipt_enabled') ?? true;
      _feedbackProduceEnabled =
          prefs.getBool('feedback_scanner_produce_enabled') ?? true;
      _leadTimeDays =
          prefs.getInt(NotificationPreferencesStore.leadTimeDaysKey) ?? 3;
      _dateFormat = prefs.getString('date_format') ?? 'MM/DD/YYYY';
    });
  }

  Future<void> _persistDemoMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('demo_mode_enabled', enabled);
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    // Show export format selector
    final format = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Format'),
        content: const Text('Choose export format:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'json'),
            child: const Text('JSON (Complete Backup)'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'csv'),
            child: const Text('CSV (Inventory Only)'),
          ),
        ],
      ),
    );

    if (format == null) return;

    try {
      final telemetry = ref.read(telemetryClientProvider);
      final service = BackupRestoreService(telemetry: telemetry);
      final PreparedBackupExport preparedExport = format == 'json'
          ? await service.prepareJsonExport()
          : await service.prepareCsvExport();

      final extension = format == 'json' ? 'json' : 'csv';
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save $format export as',
        fileName: preparedExport.suggestedFileName,
        type: FileType.custom,
        allowedExtensions: [extension],
        bytes: preparedExport.bytes,
      );

      final BackupResult result;
      if (savePath != null) {
        result = BackupResult(
          success: true,
          filePath: savePath,
          sizeBytes: preparedExport.bytes.length,
          metadata: preparedExport.metadata,
        );
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
        final resolvedPath =
            '${directory.path}/zerospoils_export_$timestamp.$extension';
        result = await service.writePreparedExport(
          preparedExport,
          resolvedPath,
        );
      }

      telemetry.trackBackupSucceeded(
        sizeBytes: result.sizeBytes,
        itemCount: result.metadata?.itemCount ?? 0,
        appVersion: result.metadata?.appVersion ?? 'unknown',
      );

      // Persist export metadata
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_export_path', result.filePath);
      await prefs.setString('last_export_format', format);
      if (result.metadata != null) {
        await prefs.setString(
          'last_export_at',
          result.metadata!.exportedAt.toIso8601String(),
        );
      }
      await prefs.setInt('last_export_size', result.sizeBytes);

      // Emit telemetry
      telemetry.enqueue({
        'name': 'privacy_data_exported',
        'properties': {
          'export_format': format,
          'file_size_kb': result.sizeBytes / 1024,
          'items_count': result.metadata?.itemCount ?? 0,
        },
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$format export saved to: ${result.filePath}'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e, st) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'settings_export_failed',
        fatal: false,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
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
    } catch (e, st) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'settings_restore_failed',
        fatal: false,
      );
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
      key: const Key('screen_settings'),
      appBar: AppBar(
        title: Text(
          'Settings',
          style: Theme.of(
            context,
          ).appBarTheme.titleTextStyle?.copyWith(fontWeight: FontWeight.w600),
        ),
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
              subtitle: _accountSubtitle(),
              onTap: () => _showAccountDialog(context),
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
                // Emit telemetry event for demo mode toggle
                ref.read(telemetryClientProvider).enqueue({
                  'name': 'demo_mode_toggled',
                  'properties': {
                    'enabled': value,
                    'active_namespace': value ? 'demo' : 'live',
                  },
                });
                if (!context.mounted) return;
                _showSnack(
                  context,
                  value ? 'Demo mode enabled' : 'Demo mode disabled',
                );
              },
            ),
          ]),
          const SizedBox(height: AppSpacing.xl),
          _buildSectionHeader('PRIVACY & DATA'),
          _buildCard([
            // TODO(M6): Remove "(not yet available)" when cloud sync launches
            _buildToggleTile(
              icon: Icons.analytics_outlined,
              label: 'Share Anonymous Usage Data',
              subtitle:
                  'Grants permission for cloud export when available (not yet available)',
              value: _analyticsConsent,
              onChanged: (value) => _setBool(
                key: 'analytics_consent',
                value: value,
                onUpdate: () => _analyticsConsent = value,
                onChange: () => _trackAnalyticsConsentChange(ref, value),
              ),
            ),
            // Feature-gated: Cloud Analytics Export (demonstrates feature flags)
            ref
                .watch(
                  isFlagEnabledProvider(FeatureFlagKey.cloudAnalyticsExport),
                )
                .when(
                  data: (enabled) => enabled
                      ? _buildToggleTile(
                          icon: Icons.cloud_upload,
                          label: 'Cloud Analytics Export',
                          subtitle: 'Send telemetry data to cloud',
                          value: _analyticsConsent,
                          onChanged: (value) => _setBool(
                            key: 'cloud_analytics_export_enabled',
                            value: value,
                            onUpdate: () {},
                          ),
                        )
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (error, stack) => const SizedBox.shrink(),
                ),
            _buildLinkTile(
              icon: Icons.backup,
              label: 'Export My Data',
              subtitle: 'Download your inventory and settings',
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
              label: 'Delete All Data',
              subtitle: 'Permanently remove all data (irreversible)',
              onTap: () => _confirmClearAllData(context),
            ),
          ]),
          const SizedBox(height: AppSpacing.xl),
          _buildSectionHeader('FEEDBACK & SOUNDS'),
          _buildCard([
            _buildToggleTile(
              key: const Key('feedback_haptic_toggle'),
              icon: Icons.vibration,
              label: 'Haptic Feedback',
              subtitle: 'Enable vibration on user interactions',
              value: _feedbackHapticEnabled,
              onChanged: (value) {
                final svc = ref.read(feedbackServiceProvider).value;
                if (svc != null) unawaited(svc.setHapticEnabled(value));
                _trackFeedbackPreferenceChange(
                  ref,
                  name: 'feedback_haptic_toggle_changed',
                  properties: {'enabled': value},
                );
                if (mounted) setState(() => _feedbackHapticEnabled = value);
              },
            ),
            _buildToggleTile(
              key: const Key('feedback_audio_toggle'),
              icon: Icons.volume_up,
              label: 'Audio Feedback',
              subtitle: 'Enable sound effects on interactions',
              value: _feedbackAudioEnabled,
              onChanged: (value) {
                final svc = ref.read(feedbackServiceProvider).value;
                if (svc != null) unawaited(svc.setAudioEnabled(value));
                _trackFeedbackPreferenceChange(
                  ref,
                  name: 'feedback_audio_toggle_changed',
                  properties: {'enabled': value},
                );
                if (mounted) setState(() => _feedbackAudioEnabled = value);
              },
            ),
            _buildSliderTile(
              key: const Key('feedback_beep_volume_slider'),
              icon: Icons.graphic_eq,
              label: 'Beep Volume',
              subtitle: 'Adjust POS-style beep volume (0-100%)',
              value: _feedbackBeepVolume,
              // Update local state on every tick for smooth UI; persist only
              // when the drag ends to avoid dozens of disk writes per second.
              onChanged: (value) {
                if (mounted) setState(() => _feedbackBeepVolume = value);
              },
              onChangeEnd: (value) {
                final svc = ref.read(feedbackServiceProvider).value;
                if (svc != null) unawaited(svc.setBeepVolume(value));
                _trackFeedbackPreferenceChange(
                  ref,
                  name: 'feedback_beep_volume_changed',
                  properties: {'volume': value},
                );
              },
            ),
            _buildDropdownTile<HapticIntensity>(
              key: const Key('feedback_haptic_intensity_dropdown'),
              icon: Icons.flash_on,
              label: 'Haptic Intensity',
              value: _feedbackHapticIntensity,
              items: HapticIntensity.values,
              itemLabel: (value) => switch (value) {
                HapticIntensity.light => 'Light',
                HapticIntensity.medium => 'Medium',
                HapticIntensity.heavy => 'Heavy',
              },
              onChanged: (value) {
                final svc = ref.read(feedbackServiceProvider).value;
                if (svc != null) unawaited(svc.setHapticIntensity(value));
                _trackFeedbackPreferenceChange(
                  ref,
                  name: 'feedback_haptic_intensity_changed',
                  properties: {'intensity': value.name},
                );
                if (mounted) setState(() => _feedbackHapticIntensity = value);
              },
            ),
            _buildToggleTile(
              key: const Key('feedback_scanner_barcode_toggle'),
              icon: Icons.qr_code_scanner,
              label: 'Barcode Scan Success',
              subtitle: 'Vibrate and beep when barcode is recognized',
              value: _feedbackBarcodeEnabled,
              onChanged: (value) {
                final svc = ref.read(feedbackServiceProvider).value;
                if (svc != null) {
                  unawaited(
                    svc.setScannerEnabled(FeedbackType.barcodeSuccess, value),
                  );
                }
                _trackFeedbackPreferenceChange(
                  ref,
                  name: 'feedback_scanner_toggle_changed',
                  properties: {'scanner': 'barcodeSuccess', 'enabled': value},
                );
                if (mounted) setState(() => _feedbackBarcodeEnabled = value);
              },
            ),
            _buildToggleTile(
              key: const Key('feedback_scanner_expiry_toggle'),
              icon: Icons.event,
              label: 'Expiry Date Recognition',
              subtitle: 'Vibrate and beep when expiry date is captured',
              value: _feedbackExpiryEnabled,
              onChanged: (value) {
                final svc = ref.read(feedbackServiceProvider).value;
                if (svc != null) {
                  unawaited(
                    svc.setScannerEnabled(FeedbackType.expirySuccess, value),
                  );
                }
                _trackFeedbackPreferenceChange(
                  ref,
                  name: 'feedback_scanner_toggle_changed',
                  properties: {'scanner': 'expirySuccess', 'enabled': value},
                );
                if (mounted) setState(() => _feedbackExpiryEnabled = value);
              },
            ),
            _buildToggleTile(
              key: const Key('feedback_scanner_receipt_toggle'),
              icon: Icons.receipt_long,
              label: 'Receipt Recognition',
              subtitle: 'Vibrate and beep when receipt items are extracted',
              value: _feedbackReceiptEnabled,
              onChanged: (value) {
                final svc = ref.read(feedbackServiceProvider).value;
                if (svc != null) {
                  unawaited(
                    svc.setScannerEnabled(FeedbackType.receiptSuccess, value),
                  );
                }
                _trackFeedbackPreferenceChange(
                  ref,
                  name: 'feedback_scanner_toggle_changed',
                  properties: {'scanner': 'receiptSuccess', 'enabled': value},
                );
                if (mounted) setState(() => _feedbackReceiptEnabled = value);
              },
            ),
            _buildToggleTile(
              key: const Key('feedback_scanner_produce_toggle'),
              icon: Icons.local_grocery_store,
              label: 'Produce Label Recognition',
              subtitle: 'Vibrate and beep when produce sticker is read',
              value: _feedbackProduceEnabled,
              onChanged: (value) {
                final svc = ref.read(feedbackServiceProvider).value;
                if (svc != null) {
                  unawaited(
                    svc.setScannerEnabled(FeedbackType.produceSuccess, value),
                  );
                }
                _trackFeedbackPreferenceChange(
                  ref,
                  name: 'feedback_scanner_toggle_changed',
                  properties: {'scanner': 'produceSuccess', 'enabled': value},
                );
                if (mounted) setState(() => _feedbackProduceEnabled = value);
              },
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
                key: NotificationPreferencesStore.notificationsEnabledKey,
                value: value,
                onUpdate: () => _notificationsEnabled = value,
                onChange: () {
                  _trackNotificationToggle(ref, value);
                  unawaited(_rescheduleNotifications());
                },
              ),
            ),
            _buildDropdownTile<int>(
              icon: Icons.timer,
              label: 'Expiry Warning Lead Time',
              value: _leadTimeDays,
              items: const [1, 3, 7],
              itemLabel: (val) => '$val days',
              onChanged: (value) => _setInt(
                key: NotificationPreferencesStore.leadTimeDaysKey,
                value: value,
                onUpdate: () => _leadTimeDays = value,
                onChange: () {
                  _trackExpiryWarningChange(ref, value);
                  unawaited(_rescheduleNotifications());
                },
              ),
            ),
            _buildToggleTile(
              icon: Icons.music_note,
              label: 'Sound',
              value: _soundEnabled,
              onChanged: (value) => _setBool(
                key: NotificationPreferencesStore.soundEnabledKey,
                value: value,
                onUpdate: () => _soundEnabled = value,
                onChange: () => _trackSoundToggle(ref, value),
              ),
            ),
            _buildToggleTile(
              icon: Icons.vibration,
              label: 'Vibration',
              value: _vibrationEnabled,
              onChanged: (value) => _setBool(
                key: NotificationPreferencesStore.vibrationEnabledKey,
                value: value,
                onUpdate: () => _vibrationEnabled = value,
                onChange: () => _trackVibrationToggle(ref, value),
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
              onChanged: (value) => _setBool(
                key: 'dark_mode_enabled',
                value: value,
                onUpdate: () => _darkModeEnabled = value,
                onChange: () {
                  final nextTheme = value ? ThemeMode.dark : ThemeMode.light;
                  ref.read(themeModeProvider.notifier).state = nextTheme;
                  _trackThemeChanged(ref, value);
                },
              ),
            ),
            _buildDropdownTile<String>(
              icon: Icons.date_range,
              label: 'Date Format',
              value: _dateFormat,
              items: const ['MM/DD/YYYY', 'DD/MM/YYYY', 'YYYY-MM-DD'],
              itemLabel: (val) => val,
              onChanged: (value) {
                _trackDateFormatChange(ref, value);
                _setString(
                  key: 'date_format',
                  value: value,
                  onUpdate: () => _dateFormat = value,
                );
              },
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
              onTap: () => showFeedbackDrawer(context, ref, source: 'settings'),
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
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: textTheme.bodySmall?.color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? const Color(0x33000000)
                : const Color(0x11000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(children: _withDividers(children)),
      ),
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
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: theme.colorScheme.onSurface),
      title: Text(label, style: theme.textTheme.bodyMedium),
      subtitle: subtitle == null
          ? null
          : Text(subtitle, style: theme.textTheme.bodySmall),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildToggleTile({
    Key? key,
    required IconData icon,
    required String label,
    String? subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    String? trailingLabel,
  }) {
    final theme = Theme.of(context);

    return Semantics(
      enabled: onChanged != null,
      onTap: onChanged != null ? () => onChanged(!value) : null,
      child: ListTile(
        key: key,
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: theme.colorScheme.onSurface),
        title: Text(label, style: theme.textTheme.bodyMedium),
        subtitle: subtitle == null
            ? null
            : Text(subtitle, style: theme.textTheme.bodySmall),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailingLabel != null)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Text(trailingLabel, style: theme.textTheme.bodySmall),
              ),
            Semantics(
              label: '$label: ${value ? "on" : "off"}',
              enabled: onChanged != null,
              child: Switch(value: value, onChanged: onChanged),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownTile<T>({
    Key? key,
    required IconData icon,
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T> onChanged,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      key: key,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: theme.colorScheme.onSurface),
      title: Text(label, style: theme.textTheme.bodyMedium),
      trailing: DropdownButton<T>(
        value: value,
        dropdownColor: theme.cardColor,
        style: theme.textTheme.bodyMedium,
        underline: const SizedBox.shrink(),
        items: items
            .map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Text(itemLabel(item), style: theme.textTheme.bodyMedium),
              ),
            )
            .toList(),
        onChanged: (val) {
          if (val != null) onChanged(val);
        },
      ),
    );
  }

  Widget _buildSliderTile({
    Key? key,
    required IconData icon,
    required String label,
    String? subtitle,
    required double value,
    required ValueChanged<double> onChanged,
    ValueChanged<double>? onChangeEnd,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      key: key,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: theme.colorScheme.onSurface),
      title: Text(label, style: theme.textTheme.bodyMedium),
      subtitle: subtitle == null
          ? null
          : Text(subtitle, style: theme.textTheme.bodySmall),
      trailing: SizedBox(
        width: 164,
        child: Slider(
          value: value.clamp(0.0, 1.0).toDouble(),
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
        ),
      ),
    );
  }

  Widget _buildDangerTile({
    required IconData icon,
    required String label,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.danger),
      title: Text(
        label,
        style: AppTextStyles.body.copyWith(color: AppColors.danger),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(color: AppColors.danger),
            )
          : null,
      trailing: const Icon(Icons.chevron_right, color: AppColors.danger),
      onTap: onTap,
    );
  }

  Future<void> _setBool({
    required String key,
    required bool value,
    required VoidCallback onUpdate,
    VoidCallback? onChange,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    onChange?.call();
    if (!mounted) return;
    setState(onUpdate);
  }

  Future<void> _setInt({
    required String key,
    required int value,
    required VoidCallback onUpdate,
    VoidCallback? onChange,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
    onChange?.call();
    if (!mounted) return;
    setState(onUpdate);
  }

  Future<void> _setString({
    required String key,
    required String value,
    required VoidCallback onUpdate,
    VoidCallback? onChange,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
    onChange?.call();
    if (!mounted) return;
    setState(onUpdate);
  }

  Future<void> _confirmClearAllData(BuildContext context) async {
    // Show confirmation dialog that requires typing "DELETE"
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will permanently delete ALL your data including:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text('• Inventory items'),
              const Text('• Shopping lists'),
              const Text('• Waste tracking data'),
              const Text('• All settings and preferences'),
              const SizedBox(height: 16),
              const Text(
                'This action cannot be undone.',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Type "DELETE" to confirm:'),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Type DELETE',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('Cancel'),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              final isConfirmed = value.text == 'DELETE';
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isConfirmed ? AppColors.danger : Colors.grey,
                ),
                onPressed: isConfirmed
                    ? () {
                        Navigator.pop(context, true);
                      }
                    : null,
                child: const Text('Delete Permanently'),
              );
            },
          ),
        ],
      ),
    );

    controller.dispose();

    if (confirmed != true || !context.mounted) return;

    try {
      final repo = ref.read(itemRepositoryProvider);
      await repo.init();

      // Get item count for telemetry BEFORE deletion
      final itemCount = (await repo.getAllItems()).length;
      final userTier = 'free'; // TODO: Get from auth provider

      // Delete via service (emits telemetry before deletion)
      final service = BackupRestoreService();
      await service.clearAllData(userTier: userTier, itemCount: itemCount);

      // Clear repository
      await repo.clear();
      ref.invalidate(itemsFutureProvider);

      if (!context.mounted) return;

      // Show success feedback
      _showSnack(context, 'All data permanently deleted');

      // Redirect to onboarding after short delay
      await Future.delayed(const Duration(milliseconds: 500));
      if (!context.mounted) return;

      // Navigate to onboarding (home_shell will handle this)
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushReplacementNamed('/onboarding');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deletion failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _accountSubtitle() {
    late final FirebaseAuthService authService;
    try {
      authService = ref.read(firebaseAuthServiceProvider);
    } catch (_) {
      return 'Not signed in';
    }

    final user = authService.currentUser;

    if (user == null) {
      return 'Not signed in';
    }

    if (user.isAnonymous) {
      return 'Anonymous session';
    }

    final email = user.email;
    if (email != null && email.isNotEmpty) {
      return email;
    }

    return 'Signed in';
  }

  Future<void> _showAccountDialog(BuildContext context) async {
    FirebaseAuthService authService;
    try {
      authService = ref.read(firebaseAuthServiceProvider);
    } catch (_) {
      _showSnack(context, 'Authentication service is unavailable.');
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) => _AccountDialog(authService: authService),
    );

    if (!mounted) return;
    setState(() {});
  }

  /// Reschedule all notifications when notification preferences change.
  /// Called after master toggle or lead time changes are persisted.
  Future<void> _rescheduleNotifications() async {
    try {
      final repo = ref.read(itemRepositoryProvider);
      await repo.init();
      final items = await repo.getAllItems();

      final notificationService = NotificationService();
      await notificationService.rescheduleAllNotifications(items);
    } catch (e) {
      // Silently fail; notifications will still respect the preference
      // on next app launch via NotificationService.scheduleForItem
    }
  }

  void _trackDateFormatChange(WidgetRef ref, String format) {
    final telemetry = ref.read(telemetryClientProvider);
    telemetry.enqueue({
      'name': 'date_format_changed',
      'properties': {'format': format},
    });
  }

  void _trackNotificationToggle(WidgetRef ref, bool enabled) {
    final telemetry = ref.read(telemetryClientProvider);
    telemetry.enqueue({
      'name': 'notification_toggle_changed',
      'properties': {'notifications_enabled': enabled},
    });
  }

  void _trackExpiryWarningChange(WidgetRef ref, int leadTimeDays) {
    final telemetry = ref.read(telemetryClientProvider);
    telemetry.enqueue({
      'name': 'expiry_warning_changed',
      'properties': {'lead_time_days': leadTimeDays},
    });
  }

  void _trackSoundToggle(WidgetRef ref, bool enabled) {
    final telemetry = ref.read(telemetryClientProvider);
    telemetry.enqueue({
      'name': 'sound_toggle_changed',
      'properties': {'sound_enabled': enabled},
    });
  }

  void _trackVibrationToggle(WidgetRef ref, bool enabled) {
    final telemetry = ref.read(telemetryClientProvider);
    telemetry.enqueue({
      'name': 'vibration_toggle_changed',
      'properties': {'vibration_enabled': enabled},
    });
  }

  void _trackAnalyticsConsentChange(WidgetRef ref, bool consented) {
    // Invalidate providers first so the consent-change event is not dropped
    // due to a stale telemetry client still seeing consent as disabled
    ref.invalidate(analyticsConsentProvider);
    ref.invalidate(telemetryClientProvider);

    final telemetry = ref.read(telemetryClientProvider);
    telemetry.enqueue({
      'name': 'analytics_consent_changed',
      'properties': {'consent_enabled': consented},
    });
  }

  void _trackThemeChanged(WidgetRef ref, bool darkModeEnabled) {
    final telemetry = ref.read(telemetryClientProvider);
    telemetry.enqueue({
      'name': 'theme_changed',
      'properties': {'theme': darkModeEnabled ? 'dark' : 'light'},
    });
  }

  void _trackFeedbackPreferenceChange(
    WidgetRef ref, {
    required String name,
    required Map<String, dynamic> properties,
  }) {
    final telemetry = ref.read(telemetryClientProvider);
    telemetry.enqueue({'name': name, 'properties': properties});
  }
}

class _AccountDialog extends StatefulWidget {
  const _AccountDialog({required this.authService});

  final FirebaseAuthService authService;

  @override
  State<_AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends State<_AccountDialog> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = widget.authService;
    final user = authService.currentUser;
    final isAnonymous = user?.isAnonymous ?? false;
    final isSignedIn = user != null && !isAnonymous;

    return AlertDialog(
      title: const Text('Account'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isSignedIn) ...[
              Text('Signed in as ${user.email ?? 'unknown'}'),
              const SizedBox(height: AppSpacing.md),
              const Text('You can sign out to return to an anonymous session.'),
            ] else ...[
              Text(
                isAnonymous
                    ? 'Upgrade your anonymous session to an email account.'
                    : 'Sign in with email to submit authenticated feedback.',
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const Key('account_email_field'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                key: const Key('account_password_field'),
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Password must be at least 6 characters.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: const Key('account_forgot_password_button'),
                  onPressed: _isSubmitting
                      ? null
                      : () => _requestPasswordReset(authService),
                  child: const Text('Forgot password?'),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: const Text('Close'),
        ),
        if (isSignedIn)
          FilledButton.tonal(
            key: const Key('account_signout_button'),
            onPressed: _isSubmitting
                ? null
                : () => _performAuthAction(
                    action: () => authService.signOut(),
                    successMessage: 'Signed out',
                    closeDialogAfterSuccess: true,
                  ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Sign Out'),
          )
        else ...[
          FilledButton.tonal(
            key: const Key('account_create_button'),
            onPressed: _isSubmitting
                ? null
                : () => _performAuthAction(
                    action: () => authService.createEmailPasswordAccount(
                      email: _emailController.text,
                      password: _passwordController.text,
                    ),
                    successMessage: 'Account created',
                    closeDialogAfterSuccess: true,
                    requiresCredentials: true,
                  ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create Account'),
          ),
          FilledButton(
            key: const Key('account_signin_button'),
            onPressed: _isSubmitting
                ? null
                : () => _performAuthAction(
                    action: () => authService.signInWithEmailPassword(
                      email: _emailController.text,
                      password: _passwordController.text,
                    ),
                    successMessage: 'Signed in',
                    closeDialogAfterSuccess: true,
                    requiresCredentials: true,
                  ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Sign In'),
          ),
          FilledButton.tonal(
            key: const Key('account_google_signin_button'),
            onPressed: _isSubmitting
                ? null
                : () => _performAuthAction(
                    action: () => authService.signInWithGoogle(),
                    successMessage: 'Signed in with Google',
                    closeDialogAfterSuccess: true,
                  ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Continue with Google'),
          ),
          FilledButton.tonal(
            key: const Key('account_apple_signin_button'),
            onPressed: _isSubmitting
                ? null
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Apple Sign-In will be enabled after email and Google sign-in are fully verified on-device.',
                        ),
                      ),
                    );
                  },
            child: const Text('Continue with Apple (Soon)'),
          ),
        ],
      ],
    );
  }

  Future<void> _requestPasswordReset(FirebaseAuthService authService) async {
    final messenger = ScaffoldMessenger.of(context);
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Enter your account email first.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await authService.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Password reset email sent to $email.')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(_messageForAuthError(e.code))),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not start password reset.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _performAuthAction({
    required Future<void> Function() action,
    required String successMessage,
    required bool closeDialogAfterSuccess,
    bool requiresCredentials = false,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (requiresCredentials) {
      if (email.isEmpty || !email.contains('@')) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Enter a valid email address.')),
        );
        return;
      }
      if (password.length < 6) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Password must be at least 6 characters.'),
          ),
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await action();
      if (!mounted) return;

      messenger.showSnackBar(SnackBar(content: Text(successMessage)));

      if (closeDialogAfterSuccess) {
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(_messageForAuthError(e.code))),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Authentication failed. Try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _messageForAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found for this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Email format is invalid.';
      case 'operation-not-allowed':
        return 'Enable Email/Password in Firebase Authentication settings.';
      case 'weak-password':
        return 'Choose a stronger password.';
      default:
        return 'Authentication failed ($code).';
    }
  }
}
