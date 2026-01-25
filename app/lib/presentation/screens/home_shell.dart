// Home shell with 4-tab navigation using emoji icons
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/base_components.dart';
import 'inventory_screen.dart';
import 'expiring_today_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const InventoryScreen(),
    const ExpiringTodayScreen(),
    const PlaceholderScreen(title: 'Shopping List', icon: Icons.shopping_cart),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      // FAB is now handled by individual screens (e.g., InventoryScreen)
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Text('📦', style: TextStyle(fontSize: 20)),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Text('⏰', style: TextStyle(fontSize: 20)),
            label: 'Expiring',
          ),
          BottomNavigationBarItem(
            icon: Text('🛒', style: TextStyle(fontSize: 20)),
            label: 'Shopping',
          ),
          BottomNavigationBarItem(
            icon: Text('⚙️', style: TextStyle(fontSize: 20)),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

/// Add Item modal (bottom sheet)
class AddItemModal extends StatefulWidget {
  const AddItemModal({super.key});

  @override
  State<AddItemModal> createState() => _AddItemModalState();
}

class _AddItemModalState extends State<AddItemModal> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Add Item', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Item Name',
              hintText: 'e.g., Milk, Bread',
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  // TODO: Add item logic
                  Navigator.pop(context);
                },
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
