import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'presentation/routing/router.dart';
import 'presentation/themes/app_theme.dart';
import 'presentation/di/service_locator.dart';
import 'data/adapters/item_adapter.dart';

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

  runApp(const ProviderScope(child: ZeroSpoilsApp()));
}

class ZeroSpoilsApp extends ConsumerWidget {
  const ZeroSpoilsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize telemetry client
    final telemetry = ref.watch(telemetryClientProvider);

    // Track app install on first launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      telemetry.trackAppInstalled(isFirstInstall: true);
    });

    return MaterialApp.router(
      title: 'ZeroSpoils',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

// test comment
