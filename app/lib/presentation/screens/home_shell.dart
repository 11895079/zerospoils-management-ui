// Home shell with 4-tab navigation
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../di/repository_providers.dart';
import '../di/service_locator.dart' show telemetryClientProvider;
import '../widgets/beta_feedback_button.dart';
import 'inventory_screen.dart';
import 'expiring_today_screen.dart';
import 'shopping_list_screen.dart';
import 'progress_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  bool _dailyWelcomeTriggered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dailyWelcomeTriggered) {
      return;
    }
    _dailyWelcomeTriggered = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(zestoServiceProvider).onAppOpened());
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomNavigationTheme = Theme.of(context).bottomNavigationBarTheme;
    final selectedIndex = ref.watch(homeTabIndexProvider);
    final screens = [
      const InventoryScreen(),
      const ExpiringTodayScreen(),
      const ShoppingListScreen(),
      const ProgressScreen(),
    ];

    const tabNames = ['inventory', 'expiring', 'shopping', 'progress'];

    return Scaffold(
      // ZestoOverlay is mounted at the MaterialApp.router level (see
      // main.dart `builder:`) so it renders above all pushed routes, not
      // just HomeShell. Don't add it back here — that would double-mount
      // it and the in-shell instance would be hidden behind any pushed
      // page anyway (the original bug Copilot called out).
      body: screens[selectedIndex],
      // FAB is now handled by individual screens (e.g., InventoryScreen)
      // The beta feedback FAB sits at bottom-left to avoid conflicting with
      // screen-level FABs at bottom-right. Hidden in production builds.
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: const BetaFeedbackButton(),
      bottomNavigationBar: BottomNavigationBar(
        key: const Key('home_bottom_nav'),
        currentIndex: selectedIndex,
        onTap: (index) {
          ref.read(homeTabIndexProvider.notifier).state = index;
          // Track tab switch
          ref.read(telemetryClientProvider).enqueue({
            'name': 'tab_switched',
            'properties': {'tab_name': tabNames[index]},
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: bottomNavigationTheme.backgroundColor,
        selectedItemColor: bottomNavigationTheme.selectedItemColor,
        unselectedItemColor: bottomNavigationTheme.unselectedItemColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2, key: Key('nav_inventory')),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule, key: Key('nav_expiring')),
            label: 'Expiring',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart, key: Key('nav_shopping')),
            label: 'Shopping',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights, key: Key('nav_progress')),
            label: 'Progress',
          ),
        ],
      ),
    );
  }
}
