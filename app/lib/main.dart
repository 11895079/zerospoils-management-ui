import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'presentation/routing/router.dart';
import 'presentation/themes/app_theme.dart';
import 'presentation/di/service_locator.dart';

void main() async {
  // Initialize Hive for local storage
  await Hive.initFlutter();

  // TODO: M1/090 - Register Hive adapters for models
  // Hive.registerAdapter(ItemAdapter());
  // Hive.registerAdapter(ShoppingListItemAdapter());
  // Hive.registerAdapter(EventAdapter());

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
