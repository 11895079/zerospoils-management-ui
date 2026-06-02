library;

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/reference/reference_pack_fetchers.dart';
import '../../core/reference/reference_pack_keys.dart';
import '../../core/reference/reference_pack_service.dart';
import '../../generated_l10n/app_localizations.dart';
import '../../generated_l10n/app_localizations_en.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../di/localization_providers.dart';
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
  DateTime? _lastBeepPreviewAt;
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _darkModeEnabled = false;
  bool _mealPlanningEnabled = false;
  bool _dataSyncEnabled = false;
  bool _analyticsConsent = true;
  String? _barcodePackVersion;
  DateTime? _barcodePackUpdatedAt;
  int _barcodePackRecordCount = 0;
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
    // Resolve FeedbackService eagerly and sync its in-memory state into the
    // local UI fields.  This makes the service the single source of truth for
    // feedback settings and avoids duplicating the prefs key strings that live
    // inside FeedbackService as private constants.
    ref.read(feedbackServiceProvider.future).then((svc) {
      if (!mounted) return;
      setState(() {
        _feedbackHapticEnabled = svc.hapticEnabled;
        _feedbackAudioEnabled = svc.audioEnabled;
        _feedbackBeepVolume = svc.beepVolume;
        _feedbackHapticIntensity = svc.hapticIntensity;
        _feedbackBarcodeEnabled = svc.scannerEnabled(
          FeedbackType.barcodeSuccess,
        );
        _feedbackExpiryEnabled = svc.scannerEnabled(FeedbackType.expirySuccess);
        _feedbackReceiptEnabled = svc.scannerEnabled(
          FeedbackType.receiptSuccess,
        );
        _feedbackProduceEnabled = svc.scannerEnabled(
          FeedbackType.produceSuccess,
        );
      });
    });
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
    final referencePackStatus = await ReferencePackService(
      preferences: prefs,
    ).barcodeCatalogStatus();
    await loadAppLocalePreference(ref);
    await loadReferencePackPreferences(ref);
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
      _barcodePackVersion = referencePackStatus.version;
      _barcodePackUpdatedAt = referencePackStatus.updatedAt;
      _barcodePackRecordCount = referencePackStatus.recordCount;
      _leadTimeDays =
          prefs.getInt(NotificationPreferencesStore.leadTimeDaysKey) ?? 3;
      _dateFormat = prefs.getString('date_format') ?? 'MM/DD/YYYY';
    });
  }

  Future<void> _syncReferencePacks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final region = effectiveReferencePackRegion(
        regionTag: ref.read(referencePackRegionTagProvider),
        activeBarcodeRegion: prefs.getString(
          ReferencePackKeys.activeBarcodePackRegion,
        ),
      );
      final locale = effectiveReferencePackLanguage(
        languageTag: ref.read(referencePackLanguageTagProvider),
        appLocaleTag: ref.read(appLocaleTagProvider),
      );

      final service = ReferencePackService(preferences: prefs);
      final manifestProvider = FirebaseRemoteConfigManifestUrlProvider();
      final downloader = HttpReferencePackDownloader();

      await service.syncBarcodeCatalogPack(
        manifestUrlProvider: manifestProvider,
        downloader: downloader,
        region: region,
      );
      await service.syncCategoriesPack(
        manifestUrlProvider: manifestProvider,
        downloader: downloader,
        region: region,
        locale: locale,
      );
      await service.syncLocationsPack(
        manifestUrlProvider: manifestProvider,
        downloader: downloader,
        region: region,
        locale: locale,
      );

      final updatedStatus = await service.barcodeCatalogStatus();
      if (!mounted) {
        return;
      }

      setState(() {
        _barcodePackVersion = updatedStatus.version;
        _barcodePackUpdatedAt = updatedStatus.updatedAt;
        _barcodePackRecordCount = updatedStatus.recordCount;
      });
    } catch (_) {
      // Best-effort refresh only. Preference changes should still persist.
    }
  }

  Future<void> _persistDemoMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('demo_mode_enabled', enabled);
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEn();
    // Show export format selector
    final format = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsExportData),
        content: Text(l10n.settingsChooseExportFormat),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'json'),
            child: Text(l10n.settingsExportJsonCompleteBackup),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'csv'),
            child: Text(l10n.settingsExportCsvInventoryOnly),
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
        dialogTitle: l10n.settingsSaveExportAs(format),
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
            content: Text(l10n.settingsExportSavedTo(format, result.filePath)),
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
            content: Text(l10n.settingsExportFailed(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEn();
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
          title: Text(l10n.settingsImportData),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.settingsRestoreWillRestoreItems(preview.itemCount)),
              const SizedBox(height: 8),
              if (preview.requiresMigration)
                Text(
                  l10n.settingsRestoreMigrationRequiredFromVersion(
                    preview.schemaVersionFrom,
                  ),
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              const SizedBox(height: 8),
              Text(
                l10n.settingsRestoreReplaceAllDataPrompt,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.buttonCancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.buttonImport),
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
              restoreResult.migrationsApplied > 0
                  ? l10n.settingsRestoreCompletedWithMigrations(
                      restoreResult.itemsImported,
                      restoreResult.migrationsApplied,
                    )
                  : l10n.settingsRestoreCompleted(
                      restoreResult.itemsImported,
                    ),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settingsRestoreFailed(restoreResult.error ?? '')),
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
            content: Text(l10n.settingsRestoreFailed(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEn();
    final demoEnabled = ref.watch(demoModeProvider);
    final localeTag = ref.watch(appLocaleTagProvider);
    final referencePackRegionTag = ref.watch(referencePackRegionTagProvider);
    final referencePackLanguageTag = ref.watch(
      referencePackLanguageTagProvider,
    );

    return Scaffold(
      key: const Key('screen_settings'),
      appBar: AppBar(
        title: Text(
          l10n.screenTitleSettings,
          style: Theme.of(
            context,
          ).appBarTheme.titleTextStyle?.copyWith(fontWeight: FontWeight.w600),
        ),
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          _buildSectionHeader(l10n.settingsSectionAccountData),
          _buildCard([
            _buildLinkTile(
              icon: Icons.person,
              label: l10n.settingsAccount,
              subtitle: _accountSubtitle(l10n),
              onTap: () => _showAccountDialog(context),
            ),
            _buildToggleTile(
              icon: Icons.cloud_sync,
              label: l10n.settingsDataSync,
              value: _dataSyncEnabled,
              onChanged: null,
              trailingLabel: l10n.settingsSoon,
            ),
            _buildToggleTile(
              icon: Icons.bug_report,
              label: l10n.settingsDemoMode,
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
                  value
                      ? l10n.settingsDemoModeEnabled
                      : l10n.settingsDemoModeDisabled,
                );
              },
            ),
          ]),
          const SizedBox(height: AppSpacing.xl),
          _buildSectionHeader(l10n.settingsPrivacy),
          _buildCard([
            // TODO(M6): Remove "(not yet available)" when cloud sync launches
            _buildToggleTile(
              icon: Icons.analytics_outlined,
              label: l10n.settingsShareAnonymousUsageData,
              subtitle: l10n.settingsShareAnonymousUsageDataSubtitle,
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
                          label: l10n.settingsCloudAnalyticsExport,
                          subtitle: l10n.settingsCloudAnalyticsExportSubtitle,
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
              label: l10n.settingsExportData,
              subtitle: l10n.settingsExportSubtitle,
              onTap: () => _exportBackup(context, ref),
            ),
            _buildLinkTile(
              icon: Icons.restore,
              label: l10n.settingsImportData,
              subtitle: l10n.settingsImportSubtitle,
              onTap: () => _importBackup(context, ref),
            ),
            _buildInfoTile(
              icon: Icons.dataset_linked,
              label: l10n.settingsReferenceDataPacks,
              subtitle: _referencePackDiagnosticsSubtitle(),
            ),
            _buildDangerTile(
              icon: Icons.delete_forever,
              label: l10n.settingsDeleteAllData,
              subtitle: l10n.settingsDeleteAllDataSubtitle,
              onTap: () => _confirmClearAllData(context),
            ),
          ]),
          const SizedBox(height: AppSpacing.xl),
          _buildSectionHeader(l10n.settingsFeedback),
          _buildCard([
            _buildToggleTile(
              key: const Key('feedback_haptic_toggle'),
              icon: Icons.vibration,
              label: l10n.feedbackHapticFeedback,
              subtitle: l10n.feedbackHapticFeedbackDescription,
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
              label: l10n.feedbackAudioFeedback,
              subtitle: l10n.feedbackAudioFeedbackDescription,
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
              label: l10n.feedbackBeepVolume,
              subtitle: l10n.feedbackBeepVolumeDescription,
              value: _feedbackBeepVolume,
              // Update local state on every tick for smooth UI; persist only
              // when the drag ends to avoid dozens of disk writes per second.
              onChanged: (value) {
                if (mounted) setState(() => _feedbackBeepVolume = value);
                final svc = ref.read(feedbackServiceProvider).value;
                if (svc != null) {
                  unawaited(svc.setBeepVolume(value));
                  final now = DateTime.now();
                  final last = _lastBeepPreviewAt;
                  if (last == null ||
                      now.difference(last).inMilliseconds >= 140) {
                    _lastBeepPreviewAt = now;
                    unawaited(svc.previewBeepVolume(value));
                  }
                }
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
              label: l10n.feedbackHapticIntensity,
              value: _feedbackHapticIntensity,
              items: HapticIntensity.values,
              itemLabel: (value) => switch (value) {
                HapticIntensity.light => l10n.settingsHapticIntensityLight,
                HapticIntensity.medium => l10n.settingsHapticIntensityMedium,
                HapticIntensity.heavy => l10n.settingsHapticIntensityHeavy,
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
              label: l10n.feedbackOcrBarcodeSuccess,
              subtitle: l10n.feedbackOcrBarcodeSuccessDescription,
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
              label: l10n.feedbackOcrExpirySuccess,
              subtitle: l10n.feedbackOcrExpirySuccessDescription,
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
              label: l10n.feedbackOcrReceiptSuccess,
              subtitle: l10n.feedbackOcrReceiptSuccessDescription,
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
              label: l10n.feedbackOcrProduceSuccess,
              subtitle: l10n.feedbackOcrProduceSuccessDescription,
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
          _buildSectionHeader(l10n.settingsReminders),
          _buildCard([
            _buildToggleTile(
              icon: Icons.notifications_active,
              label: l10n.settingsNotifications,
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
              label: l10n.remindersLeadTime,
              value: _leadTimeDays,
              items: const [1, 3, 7],
              itemLabel: (val) => l10n.settingsLeadTimeDays(val),
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
              label: l10n.remindersSound,
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
              label: l10n.remindersVibration,
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
          _buildSectionHeader(l10n.settingsSectionPreferences),
          _buildCard([
            _buildToggleTile(
              icon: Icons.dark_mode,
              label: l10n.settingsDarkMode,
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
              label: l10n.settingsDateFormat,
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
            _buildDropdownTile<String>(
              key: const Key('language_dropdown_tile'),
              icon: Icons.language,
              label: l10n.settingsLanguage,
              value: localeTag,
              items: appLocaleOptions.map((option) => option.tag).toList(),
              itemLabel: appLocaleLabelForTag,
              onChanged: (value) {
                unawaited(() async {
                  await setAppLocalePreference(ref, value);
                  await _syncReferencePacks();
                }());
              },
            ),
            _buildDropdownTile<String>(
              key: const Key('reference_region_dropdown_tile'),
              icon: Icons.public,
              label: l10n.settingsReferenceDataRegion,
              value: referencePackRegionTag,
              items: referencePackRegionOptions
                  .map((option) => option.tag)
                  .toList(),
              itemLabel: referencePackRegionLabelForTag,
              onChanged: (value) {
                unawaited(() async {
                  await setReferencePackRegionPreference(ref, value);
                  await _syncReferencePacks();
                }());
              },
            ),
            _buildDropdownTile<String>(
              key: const Key('reference_language_dropdown_tile'),
              icon: Icons.translate,
              label: l10n.settingsReferenceDataLanguage,
              value: referencePackLanguageTag,
              items: referencePackLanguageOptions
                  .map((option) => option.tag)
                  .toList(),
              itemLabel: referencePackLanguageLabelForTag,
              onChanged: (value) {
                unawaited(() async {
                  await setReferencePackLanguagePreference(ref, value);
                  await _syncReferencePacks();
                }());
              },
            ),
            _buildToggleTile(
              icon: Icons.restaurant,
              label: l10n.settingsMealPlanning,
              value: _mealPlanningEnabled,
              onChanged: null,
              trailingLabel: l10n.settingsSoon,
            ),
          ]),
          const SizedBox(height: AppSpacing.xl),
          _buildSectionHeader(l10n.settingsSectionSupportFeedback),
          _buildCard([
            _buildLinkTile(
              icon: Icons.help_outline,
              label: l10n.settingsHelpFaq,
              onTap: () => _showSnack(context, l10n.settingsHelpCenterComingSoon),
            ),
            _buildLinkTile(
              icon: Icons.feedback_outlined,
              label: l10n.settingsSendFeedback,
              onTap: () => showFeedbackDrawer(context, ref, source: 'settings'),
            ),
            _buildLinkTile(
              icon: Icons.star_rate,
              label: l10n.settingsRateApp,
              onTap: () => _showSnack(context, l10n.settingsThanksForSupport),
            ),
            _buildLinkTile(
              icon: Icons.school_outlined,
              label: l10n.settingsViewTutorial,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                );
              },
            ),
          ]),
          const SizedBox(height: AppSpacing.xl),
          _buildSectionHeader(l10n.settingsSectionLegal),
          _buildCard([
            _buildLinkTile(
              icon: Icons.privacy_tip_outlined,
              label: l10n.settingsPrivacyPolicy,
              onTap: () => _showSnack(context, l10n.settingsPrivacyPolicyComingSoon),
            ),
            _buildLinkTile(
              icon: Icons.gavel_outlined,
              label: l10n.settingsTermsOfService,
              onTap: () => _showSnack(context, l10n.settingsTermsComingSoon),
            ),
            _buildLinkTile(
              icon: Icons.info_outline,
              label: l10n.settingsAbout,
              subtitle: l10n.settingsAboutSubtitle,
              onTap: () =>
                  _showSnack(context, l10n.settingsAboutSnackMessage),
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

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    String? subtitle,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: theme.colorScheme.onSurface),
      title: Text(label, style: theme.textTheme.bodyMedium),
      subtitle: subtitle == null
          ? null
          : Text(subtitle, style: theme.textTheme.bodySmall),
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
          value: value.clamp(0.0, 1.0),
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
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEn();
    // Show confirmation dialog that requires typing "DELETE"
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsDeleteAllData),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.settingsDeleteDataPromptIntro,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text('• ${l10n.settingsDeleteDataBulletInventoryItems}'),
              Text('• ${l10n.settingsDeleteDataBulletShoppingLists}'),
              Text('• ${l10n.settingsDeleteDataBulletWasteTrackingData}'),
              Text('• ${l10n.settingsDeleteDataBulletAllSettingsPreferences}'),
              const SizedBox(height: 16),
              Text(
                l10n.privacyDeleteWarning,
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(l10n.settingsDeleteDataTypeDeleteConfirm),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: l10n.settingsDeleteDataHintTypeDelete,
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
            child: Text(l10n.buttonCancel),
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
                child: Text(l10n.settingsDeletePermanently),
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
      _showSnack(context, l10n.settingsDeleteAllDataSuccess);

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
            content: Text(l10n.settingsDeletionFailed(e.toString())),
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

  String _referencePackDiagnosticsSubtitle() {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEn();
    final version = _barcodePackVersion ?? l10n.settingsReferencePackBundledDefaultOnly;
    final updatedAt = _barcodePackUpdatedAt == null
        ? l10n.settingsReferencePackNeverUpdated
        : DateFormat(
            'yyyy-MM-dd HH:mm',
          ).format(_barcodePackUpdatedAt!.toLocal());

    return l10n.settingsReferencePackDiagnostics(
      version,
      _barcodePackRecordCount,
      updatedAt,
      ReferencePackRemoteConfigKeys.manifestUrl,
    );
  }

  String _accountSubtitle(AppLocalizations l10n) {
    late final FirebaseAuthService authService;
    try {
      authService = ref.read(firebaseAuthServiceProvider);
    } catch (_) {
      return l10n.settingsAccountNotSignedIn;
    }

    final user = authService.currentUser;

    if (user == null) {
      return l10n.settingsAccountNotSignedIn;
    }

    if (user.isAnonymous) {
      return l10n.settingsAccountAnonymousSession;
    }

    final email = user.email;
    if (email != null && email.isNotEmpty) {
      return email;
    }

    return l10n.settingsAccountSignedIn;
  }

  Future<void> _showAccountDialog(BuildContext context) async {
    FirebaseAuthService authService;
    try {
      authService = ref.read(firebaseAuthServiceProvider);
    } catch (_) {
      final l10n = AppLocalizations.of(context) ?? AppLocalizationsEn();
      _showSnack(context, l10n.settingsAuthServiceUnavailable);
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
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEn();
    final authService = widget.authService;
    final user = authService.currentUser;
    final isAnonymous = user?.isAnonymous ?? false;
    final isSignedIn = user != null && !isAnonymous;

    return AlertDialog(
      title: Text(l10n.settingsAccount),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isSignedIn) ...[
              Text(l10n.settingsAccountSignedInAs(user.email ?? 'unknown')),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.settingsAccountSignOutHint),
            ] else ...[
              Text(
                isAnonymous
                    ? l10n.settingsAccountUpgradeAnonymousHint
                    : l10n.settingsAccountSignInHint,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const Key('account_email_field'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: l10n.settingsLabelEmail,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                key: const Key('account_password_field'),
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.settingsLabelPassword,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.settingsPasswordMin6Hint,
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
                  child: Text(l10n.settingsForgotPassword),
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
          child: Text(l10n.buttonClose),
        ),
        if (isSignedIn)
          FilledButton.tonal(
            key: const Key('account_signout_button'),
            onPressed: _isSubmitting
                ? null
                : () => _performAuthAction(
                    action: () => authService.signOut(),
                    successMessage: l10n.settingsSignOutSuccess,
                    closeDialogAfterSuccess: true,
                  ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.settingsSignOut),
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
                    successMessage: l10n.settingsCreateAccountSuccess,
                    closeDialogAfterSuccess: true,
                    requiresCredentials: true,
                  ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                    : Text(l10n.settingsCreateAccount),
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
                    successMessage: l10n.settingsSignInSuccess,
                    closeDialogAfterSuccess: true,
                    requiresCredentials: true,
                  ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                    : Text(l10n.settingsSignIn),
          ),
          FilledButton.tonal(
            key: const Key('account_google_signin_button'),
            onPressed: _isSubmitting
                ? null
                : () => _performAuthAction(
                    action: () => authService.signInWithGoogle(),
                    successMessage: l10n.settingsSignInWithGoogleSuccess,
                    closeDialogAfterSuccess: true,
                  ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                    : Text(l10n.settingsContinueWithGoogle),
          ),
          FilledButton.tonal(
            key: const Key('account_apple_signin_button'),
            onPressed: _isSubmitting
                ? null
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.settingsAppleSignInSoonMessage,
                        ),
                      ),
                    );
                  },
            child: Text(l10n.settingsContinueWithAppleSoon),
          ),
        ],
      ],
    );
  }

  Future<void> _requestPasswordReset(FirebaseAuthService authService) async {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEn();
    final messenger = ScaffoldMessenger.of(context);
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsEnterAccountEmailFirst)),
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
        SnackBar(content: Text(l10n.settingsPasswordResetEmailSent(email))),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(_messageForAuthError(l10n, e.code))),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsPasswordResetFailed)),
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
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEn();
    final messenger = ScaffoldMessenger.of(context);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (requiresCredentials) {
      if (email.isEmpty || !email.contains('@')) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.settingsEnterValidEmail)),
        );
        return;
      }
      if (password.length < 6) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.settingsPasswordMin6Error)),
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
        SnackBar(content: Text(_messageForAuthError(l10n, e.code))),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsAuthenticationFailedTryAgain)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _messageForAuthError(AppLocalizations l10n, String code) {
    switch (code) {
      case 'user-not-found':
        return l10n.settingsAuthErrorUserNotFound;
      case 'wrong-password':
      case 'invalid-credential':
        return l10n.settingsAuthErrorInvalidCredentials;
      case 'email-already-in-use':
        return l10n.settingsAuthErrorEmailAlreadyInUse;
      case 'invalid-email':
        return l10n.settingsAuthErrorInvalidEmail;
      case 'operation-not-allowed':
        return l10n.settingsAuthErrorOperationNotAllowed;
      case 'weak-password':
        return l10n.settingsAuthErrorWeakPassword;
      default:
        return l10n.settingsAuthErrorUnknown(code);
    }
  }
}
