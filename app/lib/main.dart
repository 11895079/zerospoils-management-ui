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

  runApp(const ProviderScope(child: ZeroSpoilsApp()));
}

class ZeroSpoilsApp extends ConsumerWidget {
  const ZeroSpoilsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize telemetry client
    final telemetry = ref.watch(telemetryClientProvider);

    // Initialize telemetry and state from prefs
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      telemetry.trackAppInstalled(isFirstInstall: true);
      final prefs = await SharedPreferences.getInstance();

      // Load demo mode preference
      final saved = prefs.getBool('demo_mode_enabled');
      if (saved != null) {
        ref.read(demoModeProvider.notifier).state = saved;
      }

      // Load hasManualItems flag
      final hasManual = prefs.getBool('has_manual_items') ?? false;
      if (hasManual) {
        ref.read(hasManualItemsProvider.notifier).state = true;
      }
    });

    return MaterialApp.router(
      title: 'ZeroSpoils',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
