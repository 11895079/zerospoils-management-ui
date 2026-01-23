library;

/// Inventory list screen
/// Main screen showing all items with category filters and search

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/models/item_model.dart';
import '../di/repository_providers.dart';
import '../di/service_locator.dart';
import '../widgets/category_chip.dart';
import '../widgets/item_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  ItemCategory? _selectedCategory;
  StorageLocation? _selectedLocation;
  bool _expiringSoonOnly = false;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _listController = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _listController.dispose();
    super.dispose();
  }

  Future<void> _refreshItems() async {
    ref.invalidate(itemsFutureProvider);
    await ref.read(hiveItemRepositoryProvider).init();
  }

  List<Item> _applyFilters(List<Item> items) {
    var filtered = items;

    if (_selectedCategory != null) {
      filtered = filtered
          .where((item) => item.category == _selectedCategory)
          .toList();
    }

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered
          .where((item) => item.name.toLowerCase().contains(query))
          .toList();
    }

    if (_selectedLocation != null) {
      filtered = filtered
          .where((item) => item.location == _selectedLocation)
          .toList();
    }

    if (_expiringSoonOnly) {
      filtered = filtered.where((item) => item.isExpiringSoon).toList();
    }

    return filtered;
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (ctx) {
        var tempLocation = _selectedLocation;
        var tempExpiringSoonOnly = _expiringSoonOnly;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                        ),
                      ),
                    ),
                    Text('Filters', style: AppTextStyles.h3),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Location',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children:
                          <StorageLocation?>[
                            null,
                            ...StorageLocation.values,
                          ].map((location) {
                            final isSelected =
                                tempLocation == location ||
                                (location == null && tempLocation == null);
                            return ChoiceChip(
                              label: Text(location?.displayName ?? 'All'),
                              selected: isSelected,
                              onSelected: (_) {
                                setSheetState(() {
                                  tempLocation = location;
                                });
                              },
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SwitchListTile(
                      value: tempExpiringSoonOnly,
                      onChanged: (value) {
                        setSheetState(() {
                          tempExpiringSoonOnly = value;
                        });
                      },
                      activeTrackColor: AppColors.primary,
                      title: const Text('Expiring soon only'),
                      subtitle: const Text(
                        'Show items expiring within the next 3 days',
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              tempLocation = null;
                              tempExpiringSoonOnly = false;
                            });
                          },
                          child: const Text('Reset'),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl,
                              vertical: AppSpacing.sm,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSm,
                              ),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedLocation = tempLocation;
                              _expiringSoonOnly = tempExpiringSoonOnly;
                            });
                            ref.read(telemetryClientProvider).enqueue({
                              'name': 'filters_applied',
                              'properties': {
                                'category': _selectedCategory?.name ?? 'all',
                                'location': _selectedLocation?.name ?? 'all',
                                'expiringSoonOnly': _expiringSoonOnly,
                                'searchQuery': _searchController.text,
                              },
                            });
                            Navigator.of(ctx).pop();
                          },
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(itemsFutureProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Inventory', style: AppTextStyles.h3),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _showFilterOptions,
            child: const Text(
              'Filter',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: itemsAsync.when(
        data: (items) {
          final filteredItems = _applyFilters(items);

          return Column(
            children: [
              _buildSearchBar(),
              _buildCategoryChips(),
              Expanded(
                child: filteredItems.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        key: const PageStorageKey('inventory_list'),
                        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                        controller: _listController,
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return ItemCard(
                            item: item,
                            onTap: () {
                              ref.read(telemetryClientProvider).enqueue({
                                'name': 'item_detail_opened',
                                'properties': {
                                  'item_id': item.id,
                                  'category': item.category.name,
                                  'location': item.location.name,
                                },
                              });
                              context.goNamed(
                                'item-detail',
                                pathParameters: {'id': item.id},
                              );
                            },
                            onEdit: () async {
                              ref.read(telemetryClientProvider).enqueue({
                                'name': 'item_edit_opened',
                                'properties': {
                                  'item_id': item.id,
                                  'category': item.category.name,
                                  'location': item.location.name,
                                },
                              });
                              await context.pushNamed(
                                'edit-item',
                                pathParameters: {'id': item.id},
                              );
                              await _refreshItems();
                              setState(() {});
                            },
                            onDelete: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) {
                                  return AlertDialog(
                                    title: const Text('Delete Item?'),
                                    content: Text(
                                      'Are you sure you want to delete "${item.name}" from your inventory?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(true),
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(
                                            color: AppColors.danger,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (confirmed == true) {
                                final repo = ref.read(
                                  hiveItemRepositoryProvider,
                                );
                                await repo.init();
                                await repo.deleteItem(item.id);
                                ref.read(telemetryClientProvider).enqueue({
                                  'name': 'item_deleted',
                                  'properties': {
                                    'item_id': item.id,
                                    'category': item.category.name,
                                    'location': item.location.name,
                                  },
                                });
                                await _refreshItems();
                                setState(() {});
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('⚠️', style: TextStyle(fontSize: 40)),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Unable to load items',
                  style: AppTextStyles.h3,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  error.toString(),
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          ref.read(telemetryClientProvider).enqueue({
            'name': 'item_add_opened',
            'properties': {},
          });
          await context.pushNamed('add-item');
          await _refreshItems();
          setState(() {});
        },
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        elevation: 4,
        child: const Text(
          '+',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: '🔍 Search items...',
          hintStyle: AppTextStyles.body.copyWith(color: AppColors.textTertiary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = <ItemCategory?>[null, ...ItemCategory.values];

    return SizedBox(
      height: 50,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
        scrollDirection: Axis.horizontal,
        children: categories
            .map(
              (category) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: CategoryChip(
                  label: category?.displayName ?? 'All',
                  isSelected:
                      _selectedCategory == category ||
                      (_selectedCategory == null && category == null),
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                ),
              ),
            )
            .toList(),
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
