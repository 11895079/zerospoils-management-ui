library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../di/repository_providers.dart';
import '../screens/onboarding_screen.dart';
import '../screens/settings_screen.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(homeTabIndexProvider);

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'ZeroSpoils',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text('Navigation', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            _drawerItem(
              context,
              ref,
              icon: Icons.school,
              iconColor: const Color(0xFF00897B),
              label: 'Onboarding',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                );
              },
            ),
            _drawerItem(
              context,
              ref,
              icon: Icons.inventory_2,
              iconColor: const Color(0xFF2E7D32),
              label: 'Inventory',
              selected: currentIndex == 0,
              onTap: () => _switchTab(context, ref, 0),
            ),
            _drawerItem(
              context,
              ref,
              icon: Icons.schedule,
              iconColor: const Color(0xFFEF6C00),
              label: 'Expiring Soon',
              selected: currentIndex == 1,
              onTap: () => _switchTab(context, ref, 1),
            ),
            _drawerItem(
              context,
              ref,
              icon: Icons.shopping_cart,
              iconColor: const Color(0xFF1565C0),
              label: 'Shopping List',
              selected: currentIndex == 2,
              onTap: () => _switchTab(context, ref, 2),
            ),
            _drawerItem(
              context,
              ref,
              icon: Icons.insights,
              iconColor: const Color(0xFF6A1B9A),
              label: 'Progress',
              selected: currentIndex == 3,
              onTap: () => _switchTab(context, ref, 3),
            ),
            const Divider(height: 1),
            _drawerItem(
              context,
              ref,
              icon: Icons.settings,
              iconColor: const Color(0xFF455A64),
              label: 'Settings',
              tileKey: const Key('drawer_settings_item'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  ListTile _drawerItem(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    Color? iconColor,
    required String label,
    required VoidCallback onTap,
    bool selected = false,
    Key? tileKey,
  }) {
    return ListTile(
      key: tileKey,
      leading: Icon(icon, color: iconColor ?? AppColors.textPrimary),
      title: Text(label),
      selected: selected,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
      onTap: onTap,
    );
  }

  void _switchTab(BuildContext context, WidgetRef ref, int index) {
    Navigator.of(context).pop();
    ref.read(homeTabIndexProvider.notifier).state = index;
  }
}
