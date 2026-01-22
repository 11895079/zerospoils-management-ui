library;

/// Inventory list screen
/// Main screen showing all items with category filters and search

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/models/item_model.dart';
import '../widgets/category_chip.dart';
import '../widgets/item_card.dart';
import 'package:go_router/go_router.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  // TODO: Replace with real data from repository
  final List<Item> _mockItems = [
    Item(
      id: '1',
      name: 'Milk',
      category: ItemCategory.dairy,
      location: StorageLocation.fridge,
      quantity: 1,
      expiryDate: DateTime.now().add(const Duration(days: 3)),
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Item(
      id: '2',
      name: 'Apples',
      category: ItemCategory.produce,
      location: StorageLocation.other,
      quantity: 5,
      expiryDate: DateTime.now(),
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Item(
      id: '3',
      name: 'Chicken Breast',
      category: ItemCategory.meat,
      location: StorageLocation.fridge,
      quantity: 500,
      expiryDate: DateTime.now().add(const Duration(days: 2)),
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Item> get _filteredItems {
    var items = _mockItems;

    // Filter by category
    if (_selectedCategory != null && _selectedCategory != 'All') {
      items = items.where((item) {
        return item.category.name.toLowerCase() ==
            _selectedCategory!.toLowerCase();
      }).toList();
    }

    // Filter by search
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      items = items.where((item) {
        return item.name.toLowerCase().contains(query);
      }).toList();
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredItems;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Inventory', style: AppTextStyles.h3),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Show filter options
            },
            child: const Text('Filter', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '🔍 Search items...',
                hintStyle: AppTextStyles.body.copyWith(
                  color: AppColors.textTertiary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
          ),

          // Category chips
          const SizedBox(height: AppSpacing.md),
          CategoryChipList(
            categories: const [
              'All',
              'Dairy',
              'Fruit',
              'Vegetables',
              'Meat',
              'Prepared',
            ],
            selectedCategory: _selectedCategory ?? 'All',
            onCategorySelected: (category) {
              setState(() {
                _selectedCategory = category == 'All' ? null : category;
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Items list or empty state
          Expanded(
            child: filteredItems.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return ItemCard(
                        item: item,
                        onTap: () {
                          // Navigate to item detail screen via named route
                          context.goNamed(
                            'item-detail',
                            pathParameters: {'id': item.id},
                          );
                        },
                        onDelete: () {
                          // TODO: Delete item
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Delete ${item.name}')),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to add item screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add item screen - TODO')),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📦', style: TextStyle(fontSize: 64)),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No items yet',
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tap the + button below to add your first item and start tracking your food inventory.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
