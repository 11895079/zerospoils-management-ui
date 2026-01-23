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
import '../widgets/item_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Provider to persist filter state across tab switches
final inventoryFilterProvider = StateProvider<InventoryFilterState>((ref) {
  return const InventoryFilterState();
});

class InventoryFilterState {
  final ItemCategory? category;
  final StorageLocation? location;
  final bool expiringSoonOnly;
  final String searchQuery;

  const InventoryFilterState({
    this.category,
    this.location,
    this.expiringSoonOnly = false,
    this.searchQuery = '',
  });

  InventoryFilterState copyWith({
    ItemCategory? category,
    StorageLocation? location,
    bool? expiringSoonOnly,
    String? searchQuery,
  }) {
    return InventoryFilterState(
      category: category ?? this.category,
      location: location ?? this.location,
      expiringSoonOnly: expiringSoonOnly ?? this.expiringSoonOnly,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
  int get activeFilterCount {
    int count = 0;
    if (category != null) count++;
    if (location != null) count++;
    if (expiringSoonOnly) count++;
    return count;
  }

  bool get hasActiveFilters => activeFilterCount > 0;
}

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _listController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Restore search query from persisted state
    final filterState = ref.read(inventoryFilterProvider);
    _searchController.text = filterState.searchQuery;
  }

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

  List<Item> _applyFilters(List<Item> items, InventoryFilterState filterState) {
    var filtered = items;

    if (filterState.category != null) {
      filtered = filtered
          .where((item) => item.category == filterState.category)
          .toList();
    }

    if (filterState.searchQuery.isNotEmpty) {
      final query = filterState.searchQuery.toLowerCase();
      filtered = filtered
          .where((item) => item.name.toLowerCase().contains(query))
          .toList();
    }

    if (filterState.location != null) {
      filtered = filtered
          .where((item) => item.location == filterState.location)
          .toList();
    }

    if (filterState.expiringSoonOnly) {
      filtered = filtered.where((item) => item.isExpiringSoon).toList();
    }

    return filtered;
  }

  void _showFilterOptions() {
    final currentState = ref.read(inventoryFilterProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (ctx) {
        var tempCategory = currentState.category;
        var tempLocation = currentState.location;
        var tempExpiringSoonOnly = currentState.expiringSoonOnly;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  top: AppSpacing.lg,
                  bottom:
                      MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
                ),
                child: SingleChildScrollView(
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
                        'Category',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: <ItemCategory?>[null, ...ItemCategory.values]
                            .map((category) {
                              final isSelected =
                                  tempCategory == category ||
                                  (category == null && tempCategory == null);
                              return ChoiceChip(
                                label: Text(category?.displayName ?? 'All'),
                                selected: isSelected,
                                onSelected: (_) {
                                  setSheetState(() {
                                    tempCategory = category;
                                  });
                                },
                              );
                            })
                            .toList(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
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
                                tempCategory = null;
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
                              ref
                                  .read(inventoryFilterProvider.notifier)
                                  .state = InventoryFilterState(
                                category: tempCategory,
                                location: tempLocation,
                                expiringSoonOnly: tempExpiringSoonOnly,
                                searchQuery: _searchController.text,
                              );
                              ref.read(telemetryClientProvider).enqueue({
                                'name': 'filters_applied',
                                'properties': {
                                  'category': tempCategory?.name ?? 'all',
                                  'location': tempLocation?.name ?? 'all',
                                  'expiringSoonOnly': tempExpiringSoonOnly,
                                  'searchQuery': _searchController.text,
                                },
                              });
                              Navigator.of(ctx).pop();
                              setState(() {}); // Trigger rebuild
                            },
                            child: const Text('Apply'),
                          ),
                        ],
                      ),
                    ],
                  ),
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
    final filterState = ref.watch(inventoryFilterProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Inventory', style: AppTextStyles.h3),
        elevation: 0,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              TextButton(
                onPressed: _showFilterOptions,
                child: const Text(
                  'Filter',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              if (filterState.activeFilterCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${filterState.activeFilterCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: itemsAsync.when(
        data: (items) {
          final filteredItems = _applyFilters(items, filterState);

          return Column(
            children: [
              _buildSearchBar(),
              if (filterState.hasActiveFilters)
                _buildActiveFilters(filterState),
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

  Widget _buildActiveFilters(InventoryFilterState filterState) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Text(
            'Active filters:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                if (filterState.category != null)
                  _buildFilterChip(
                    label: filterState.category!.displayName,
                    onRemove: () {
                      ref
                          .read(inventoryFilterProvider.notifier)
                          .state = InventoryFilterState(
                        category: null,
                        location: filterState.location,
                        expiringSoonOnly: filterState.expiringSoonOnly,
                        searchQuery: filterState.searchQuery,
                      );
                      setState(() {});
                    },
                  ),
                if (filterState.location != null)
                  _buildFilterChip(
                    label: filterState.location!.displayName,
                    onRemove: () {
                      ref
                          .read(inventoryFilterProvider.notifier)
                          .state = InventoryFilterState(
                        category: filterState.category,
                        location: null,
                        expiringSoonOnly: filterState.expiringSoonOnly,
                        searchQuery: filterState.searchQuery,
                      );
                      setState(() {});
                    },
                  ),
                if (filterState.expiringSoonOnly)
                  _buildFilterChip(
                    label: 'Expiring Soon',
                    onRemove: () {
                      ref
                          .read(inventoryFilterProvider.notifier)
                          .state = InventoryFilterState(
                        category: filterState.category,
                        location: filterState.location,
                        expiringSoonOnly: false,
                        searchQuery: filterState.searchQuery,
                      );
                      setState(() {});
                    },
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(inventoryFilterProvider.notifier).state =
                  InventoryFilterState(searchQuery: _searchController.text);
              setState(() {});
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Clear filters', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: AppColors.primary),
          ),
        ],
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
        onChanged: (value) {
          ref
              .read(inventoryFilterProvider.notifier)
              .state = InventoryFilterState(
            category: ref.read(inventoryFilterProvider).category,
            location: ref.read(inventoryFilterProvider).location,
            expiringSoonOnly: ref
                .read(inventoryFilterProvider)
                .expiringSoonOnly,
            searchQuery: value,
          );
          setState(() {});
        },
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
