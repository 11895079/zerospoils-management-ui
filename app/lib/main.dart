import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
  await FirebaseBootstrapService.initialize();

  // Bootstrap Supabase services (auth, entitlements)
  await SupabaseBootstrapService.initialize();

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

  // Initialize notifications
  await NotificationService().initialize();

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
    final telemetry = ref.read(telemetryClientProvider);
    NotificationService().setTelemetryCallback((eventName, properties) {
      telemetry.enqueue({'name': eventName, 'properties': properties});
    });
    telemetry.trackAppInstalled(isFirstInstall: true);

    // Restore scheduled notifications from saved items
    try {
      final itemRepository = ref.read(itemRepositoryProvider);
      await itemRepository.init();
      final items = await itemRepository.getAllItems();
      await NotificationService().restoreScheduled(items: items);
    } catch (e) {
      // Silently fail; notifications will still be scheduled per item
    }

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool('demo_mode_enabled');
    if (saved != null) {
      ref.read(demoModeProvider.notifier).state = saved;
    }
    await loadAppLocalePreference(ref);
    final hasManual = prefs.getBool('has_manual_items') ?? false;
    if (hasManual) {
      ref.read(hasManualItemsProvider.notifier).state = true;
    }

    await loadThemeModePreference(ref);

    setState(() {
      _initialized = true;
    });
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
          children: [if (child case != null) child, const ZestoOverlay()],
        );
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
