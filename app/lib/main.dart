import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'domain/models/item_model.dart';
import 'presentation/routing/router.dart';
import 'presentation/themes/app_theme.dart';
import 'presentation/di/service_locator.dart';
import 'presentation/di/repository_providers.dart';
import 'data/adapters/item_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/notifications/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // Initialize notifications
  await NotificationService().initialize();

  // Determine initial route based on onboarding completion
  final initialLocation = await getInitialLocation();
  router.go(initialLocation);

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
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool('demo_mode_enabled');
    if (saved != null) {
      ref.read(demoModeProvider.notifier).state = saved;
    }
    final hasManual = prefs.getBool('has_manual_items') ?? false;
    if (hasManual) {
      ref.read(hasManualItemsProvider.notifier).state = true;
    }
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
    return MaterialApp.router(
      title: 'ZeroSpoils',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
