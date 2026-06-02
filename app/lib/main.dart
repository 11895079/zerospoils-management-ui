import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:async';
import 'generated_l10n/app_localizations.dart';
import 'domain/models/item_model.dart';
import 'presentation/routing/router.dart';
import 'presentation/themes/app_theme.dart';
import 'presentation/di/localization_providers.dart';
import 'presentation/di/service_locator.dart' hide itemRepositoryProvider;
import 'presentation/di/repository_providers.dart';
import 'presentation/di/theme_providers.dart';
import 'presentation/widgets/zesto_overlay.dart';
import 'data/adapters/item_adapter.dart';
import 'data/adapters/receipt_batch_adapter.dart';
import 'domain/models/user_category.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/notifications/notification_service.dart';
import 'core/bootstrap/bootstrap.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bootstrap Firebase services (telemetry, crash reporting, remote config)
  unawaited(
    FirebaseBootstrapService.initialize()
        .timeout(
          const Duration(seconds: 8),
          onTimeout: () {
            FirebaseBootstrapService.recordStartupBreadcrumb(
              'startup/firebase_bootstrap_timeout',
            );
          },
        )
        .catchError((Object e, StackTrace stackTrace) {
          FirebaseBootstrapService.recordStartupError(
            'firebase_bootstrap_background',
            e,
            stackTrace,
          );
        }),
  );

  // Supabase bootstrap is intentionally disabled for now.
  // We keep the integration code/dependencies in-repo but avoid invoking it
  // during startup until backend rollout is re-enabled.

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Register Hive adapters for domain models
  Hive.registerAdapter(ItemAdapter());
  Hive.registerAdapter(ItemCategoryAdapter());
  Hive.registerAdapter(StorageLocationAdapter());
  Hive.registerAdapter(ItemStatusAdapter());
  Hive.registerAdapter(WasteReasonAdapter());
  Hive.registerAdapter(ItemTypeAdapter());
  Hive.registerAdapter(UnitAdapter());
  Hive.registerAdapter(ReceiptBatchItemAdapter());
  Hive.registerAdapter(ReceiptBatchAdapter());
  Hive.registerAdapter(UserCategoryAdapter());

  final prefs = await SharedPreferences.getInstance();
  configureLaunchRouting(
    onboardingComplete: prefs.getBool('onboarding_complete') ?? false,
  );

  runApp(const ProviderScope(child: ZeroSpoilsApp()));
}

class ZeroSpoilsApp extends ConsumerStatefulWidget {
  final bool skipInit;
  const ZeroSpoilsApp({super.key, this.skipInit = false});

  // Test-only constructor
  const ZeroSpoilsApp.test({super.key}) : skipInit = true;

  @override
  ConsumerState<ZeroSpoilsApp> createState() => _ZeroSpoilsAppState();
}

class _ZeroSpoilsAppState extends ConsumerState<ZeroSpoilsApp> {
  // Removed unused _initialLocation
  bool _initialized = false;

  Future<void> _runInitStep(
    String name,
    Future<void> Function() action, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    FirebaseBootstrapService.recordStartupBreadcrumb('startup/$name/start');
    try {
      await action().timeout(timeout);
      FirebaseBootstrapService.recordStartupBreadcrumb('startup/$name/ok');
    } on TimeoutException catch (e, stackTrace) {
      FirebaseBootstrapService.recordStartupError(
        'startup/$name/timeout',
        e,
        stackTrace,
      );
    } catch (e, stackTrace) {
      FirebaseBootstrapService.recordStartupError(
        'startup/$name/fail',
        e,
        stackTrace,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.skipInit) {
      _initialized = true;
    } else {
      _initPrefs();
    }
  }

  Future<void> _initPrefs() async {
    try {
      await _runInitStep('notifications_initialize', () async {
        await NotificationService().initialize();
      }, timeout: const Duration(seconds: 5));

      await _runInitStep('telemetry_wireup', () async {
        final telemetry = ref.read(telemetryClientProvider);
        NotificationService().setTelemetryCallback((eventName, properties) {
          telemetry.enqueue({'name': eventName, 'properties': properties});
        });
        telemetry.trackAppInstalled(isFirstInstall: true);
      });

      await _runInitStep('notification_restore', () async {
        final itemRepository = ref.read(itemRepositoryProvider);
        await itemRepository.init();
        final items = await itemRepository.getAllItems();
        await NotificationService().restoreScheduled(items: items);
      });

      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool('demo_mode_enabled');
      if (saved != null) {
        ref.read(demoModeProvider.notifier).state = saved;
      }

      await _runInitStep('locale_preferences_load', () async {
        await loadAppLocalePreference(ref);
        await loadReferencePackPreferences(ref);
      });

      final hasManual = prefs.getBool('has_manual_items') ?? false;
      if (hasManual) {
        ref.read(hasManualItemsProvider.notifier).state = true;
      }

      await _runInitStep('theme_preferences_load', () async {
        await loadThemeModePreference(ref);
      });
    } finally {
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    final themeMode = ref.watch(themeModeProvider);
    final locale = resolveAppLocale(ref.watch(appLocaleTagProvider));

    return MaterialApp.router(
      title: 'ZeroSpoils',
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        if (deviceLocale == null) {
          return const Locale('en');
        }

        for (final supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == deviceLocale.languageCode &&
              supportedLocale.countryCode == deviceLocale.countryCode) {
            return supportedLocale;
          }
        }

        for (final supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == deviceLocale.languageCode) {
            return supportedLocale;
          }
        }

        return const Locale('en');
      },
      supportedLocales: supportedAppLocales,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      // Mount ZestoOverlay above the Navigator so mascot bubbles render on
      // top of every routed page (HomeShell, ItemFormScreen, ItemDetail,
      // etc.). Mounting it inside a child screen would leave it behind
      // pushed routes and the mascot would be invisible when triggered
      // from item-add or item-detail flows.
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            if (child case != null)
              child
            else
              const Scaffold(body: Center(child: CircularProgressIndicator())),
            const ZestoOverlay(),
          ],
        );
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
