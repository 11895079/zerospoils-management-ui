// Home shell with 4-tab navigation
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../di/repository_providers.dart';
import '../di/service_locator.dart' show telemetryClientProvider;
import 'inventory_screen.dart';
import 'expiring_today_screen.dart';
import 'shopping_list_screen.dart';
import 'progress_screen.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(homeTabIndexProvider);
    final screens = [
      const InventoryScreen(),
      const ExpiringTodayScreen(),
      const ShoppingListScreen(),
      const ProgressScreen(),
    ];

    const tabNames = ['inventory', 'expiring', 'shopping', 'progress'];

    return Scaffold(
      body: screens[selectedIndex],
      // FAB is now handled by individual screens (e.g., InventoryScreen)
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
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.textSecondary,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.inventory_2,
              key: Key('nav_inventory'),
              color: Color(0xFF2E7D32),
            ),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.schedule,
              key: Key('nav_expiring'),
              color: Color(0xFFEF6C00),
            ),
            label: 'Expiring',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.shopping_cart,
              key: Key('nav_shopping'),
              color: Color(0xFF1565C0),
            ),
            label: 'Shopping',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.insights,
              key: Key('nav_progress'),
              color: Color(0xFF6A1B9A),
            ),
            label: 'Progress',
          ),
        ],
      ),
    );
  }
}
