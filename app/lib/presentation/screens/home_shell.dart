// Home shell with 4-tab navigation
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../di/repository_providers.dart';
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

    return Scaffold(
      body: screens[selectedIndex],
      // FAB is now handled by individual screens (e.g., InventoryScreen)
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          ref.read(homeTabIndexProvider.notifier).state = index;
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.textSecondary,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2, color: Color(0xFF2E7D32)),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule, color: Color(0xFFEF6C00)),
            label: 'Expiring',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart, color: Color(0xFF1565C0)),
            label: 'Shopping',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights, color: Color(0xFF6A1B9A)),
            label: 'Progress',
          ),
        ],
      ),
    );
  }
}
