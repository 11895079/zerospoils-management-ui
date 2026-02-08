library;

/// Inventory list screen
/// Main screen showing all items with category filters and search

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/models/item_model.dart';
import '../../domain/repositories/progress_stats_service.dart';
import '../di/repository_providers.dart';
import '../di/service_locator.dart' hide itemRepositoryProvider;
import '../widgets/item_card.dart';
import '../widgets/app_drawer.dart';
import '../widgets/item_entry_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider to persist filter state across tab switches
final inventoryFilterProvider = StateProvider<InventoryFilterState>((ref) {
  return const InventoryFilterState();
});

class InventoryFilterState {
  final ItemCategory? category;
  final StorageLocation? location;
  final bool expiringSoonOnly;
  final bool hideConsumed;
  final bool preparedOnly;
  final DateTime? createdAfter;
  final DateTime? createdBefore;
  final String searchQuery;

  const InventoryFilterState({
    this.category,
    this.location,
    this.expiringSoonOnly = false,
    this.hideConsumed = true,
    this.preparedOnly = false,
    this.createdAfter,
    this.createdBefore,
    this.searchQuery = '',
  });

  InventoryFilterState copyWith({
    ItemCategory? category,
    StorageLocation? location,
    bool? expiringSoonOnly,
    bool? hideConsumed,
    bool? preparedOnly,
    DateTime? createdAfter,
    DateTime? createdBefore,
    String? searchQuery,
  }) {
    return InventoryFilterState(
      category: category ?? this.category,
      location: location ?? this.location,
      expiringSoonOnly: expiringSoonOnly ?? this.expiringSoonOnly,
      hideConsumed: hideConsumed ?? this.hideConsumed,
      preparedOnly: preparedOnly ?? this.preparedOnly,
      createdAfter: createdAfter ?? this.createdAfter,
      createdBefore: createdBefore ?? this.createdBefore,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  int get activeFilterCount {
    int count = 0;
    if (category != null) count++;
    if (location != null) count++;
    if (expiringSoonOnly) count++;
    if (!hideConsumed) count++; // Count if showing consumed items
    if (preparedOnly) count++;
    if (createdAfter != null) count++;
    if (createdBefore != null) count++;
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
  late final ProviderSubscription<AsyncValue<List<Item>>> _itemsSubscription;

  @override
  void initState() {
    super.initState();
    // Restore search query from persisted state
    final filterState = ref.read(inventoryFilterProvider);
    _searchController.text = filterState.searchQuery;

    _itemsSubscription = ref.listenManual<AsyncValue<List<Item>>>(
      itemsFutureProvider,
      (previous, next) {
        if (ref.read(demoModeProvider)) return;

        next.whenData((items) {
          final hasItems = items.isNotEmpty;
          final notifier = ref.read(hasManualItemsProvider.notifier);
          if (notifier.state == hasItems) return;

          notifier.state = hasItems;
          () async {
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('has_manual_items', hasItems);
            } catch (_) {}
          }();
        });
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _itemsSubscription.close();
    _searchController.dispose();
    _listController.dispose();
    super.dispose();
  }

  Future<void> _refreshItems() async {
    ref.invalidate(itemsFutureProvider);
    await ref.read(itemRepositoryProvider).init();
  }

  Future<void> _openAddItemSheet({bool emitOpenedTelemetry = true}) async {
    if (emitOpenedTelemetry) {
      ref.read(telemetryClientProvider).enqueue({
        'name': 'item_add_opened',
        'properties': {},
      });
    }
    ItemEntrySeed? seed;
    var keepAdding = true;

    while (keepAdding && mounted) {
      final result = await showModalBottomSheet<ItemEntryResult>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg),
          ),
        ),
        builder: (_) => ItemEntrySheet(
          requireExpiry: false,
          seed: seed,
          showAddAnother: true,
        ),
      );

      if (result == null || result.skipped) break;

      final repo = ref.read(itemRepositoryProvider);
      await repo.init();
      final now = DateTime.now();
      final item = Item(
        id: now.microsecondsSinceEpoch.toString(),
        name: result.name,
        category: result.category,
        type: result.type,
        preparedDate: result.preparedDate,
        location: result.location,
        quantity: result.quantity,
        unit: result.unit,
        expiryDate: result.expiryDate,
        purchasePrice: result.purchasePrice,
        status: ItemStatus.available,
        createdAt: now,
        updatedAt: now,
      );
      await repo.saveItem(item);
      ref.invalidate(itemsFutureProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} added to inventory'),
          duration: const Duration(seconds: 2),
        ),
      );

      keepAdding = result.addAnother;
      if (keepAdding) {
        seed = ItemEntrySeed(
          name: '',
          category: result.category,
          quantity: result.quantity,
          unit: result.unit,
          purchasePrice: result.purchasePrice,
          type: result.type,
          preparedDate: result.preparedDate,
        );
      }
    }
  }

  List<Item> _applyFilters(List<Item> items, InventoryFilterState filterState) {
    var filtered = items;

    // Filter out consumed/wasted if hideConsumed is true
    if (filterState.hideConsumed) {
      filtered = filtered
          .where((item) => item.status == ItemStatus.available)
          .toList();
    }

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

    if (filterState.preparedOnly) {
      filtered = filtered
          .where((item) => item.type == ItemType.prepared)
          .toList();
    }

    if (filterState.expiringSoonOnly) {
      filtered = filtered.where((item) => item.isExpiringSoon).toList();
    }

    if (filterState.createdAfter != null) {
      final start = DateTime(
        filterState.createdAfter!.year,
        filterState.createdAfter!.month,
        filterState.createdAfter!.day,
      );
      filtered = filtered
          .where((item) => !item.createdAt.isBefore(start))
          .toList();
    }

    if (filterState.createdBefore != null) {
      final end = DateTime(
        filterState.createdBefore!.year,
        filterState.createdBefore!.month,
        filterState.createdBefore!.day,
        23,
        59,
        59,
        999,
      );
      filtered = filtered
          .where((item) => !item.createdAt.isAfter(end))
          .toList();
    }

    // Sort: available items first, then consumed/wasted at bottom
    filtered.sort((a, b) {
      if (a.status == ItemStatus.available &&
          b.status != ItemStatus.available) {
        return -1;
      }
      if (a.status != ItemStatus.available &&
          b.status == ItemStatus.available) {
        return 1;
      }
      // Within same status group, sort by expiry (items expiring soonest first)
      if (a.expiryDate == null && b.expiryDate == null) return 0;
      if (a.expiryDate == null) return 1;
      if (b.expiryDate == null) return -1;
      return a.expiryDate!.compareTo(b.expiryDate!);
    });

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
        var tempHideConsumed = currentState.hideConsumed;
        var tempPreparedOnly = currentState.preparedOnly;
        DateTime? tempCreatedAfter = currentState.createdAfter;
        DateTime? tempCreatedBefore = currentState.createdBefore;

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
                      Text(
                        'Added date',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              key: const Key('inventory_filter_created_from'),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      tempCreatedAfter ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (picked == null) return;
                                setSheetState(() {
                                  tempCreatedAfter = picked;
                                });
                              },
                              child: Text(
                                tempCreatedAfter == null
                                    ? 'From'
                                    : _formatShortDate(tempCreatedAfter!),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: OutlinedButton(
                              key: const Key('inventory_filter_created_to'),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      tempCreatedBefore ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (picked == null) return;
                                setSheetState(() {
                                  tempCreatedBefore = picked;
                                });
                              },
                              child: Text(
                                tempCreatedBefore == null
                                    ? 'To'
                                    : _formatShortDate(tempCreatedBefore!),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SwitchListTile(
                        key: const Key('inventory_filter_prepared_only'),
                        value: tempPreparedOnly,
                        onChanged: (value) {
                          setSheetState(() {
                            tempPreparedOnly = value;
                          });
                        },
                        activeTrackColor: AppColors.primary,
                        title: const Text('Prepared only'),
                        subtitle: const Text('Show prepared items only'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SwitchListTile(
                        key: const Key('inventory_filter_expiring_soon'),
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
                      const SizedBox(height: AppSpacing.sm),
                      SwitchListTile(
                        key: const Key('inventory_filter_hide_consumed'),
                        value: tempHideConsumed,
                        onChanged: (value) {
                          setSheetState(() {
                            tempHideConsumed = value;
                          });
                        },
                        activeTrackColor: AppColors.primary,
                        title: const Text('Hide consumed items'),
                        subtitle: const Text(
                          'Hide items marked as consumed or wasted',
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
                                tempHideConsumed = true;
                                tempPreparedOnly = false;
                                tempCreatedAfter = null;
                                tempCreatedBefore = null;
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
                                  .state = currentState.copyWith(
                                category: tempCategory,
                                location: tempLocation,
                                expiringSoonOnly: tempExpiringSoonOnly,
                                hideConsumed: tempHideConsumed,
                                preparedOnly: tempPreparedOnly,
                                createdAfter: tempCreatedAfter,
                                createdBefore: tempCreatedBefore,
                                searchQuery: _searchController.text,
                              );
                              ref.read(telemetryClientProvider).enqueue({
                                'name': 'filters_applied',
                                'properties': {
                                  'category': tempCategory?.name ?? 'all',
                                  'location': tempLocation?.name ?? 'all',
                                  'expiringSoonOnly': tempExpiringSoonOnly,
                                  'hideConsumed': tempHideConsumed,
                                  'preparedOnly': tempPreparedOnly,
                                  'createdAfter': tempCreatedAfter
                                      ?.toIso8601String(),
                                  'createdBefore': tempCreatedBefore
                                      ?.toIso8601String(),
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
    final progressStatsAsync = ref.watch(progressStatsProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Inventory', style: AppTextStyles.h3),
        elevation: 1,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: _showFilterOptions,
                icon: const Icon(Icons.tune, color: AppColors.textPrimary),
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
          final demoEnabled = ref.watch(demoModeProvider);

          return Column(
            children: [
              if (demoEnabled) _buildDemoModeWarning(),
              progressStatsAsync.when(
                data: _buildStreakBadge,
                loading: () => const SizedBox.shrink(),
                error: (error, stackTrace) => const SizedBox.shrink(),
              ),
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
                                final repo = ref.read(itemRepositoryProvider);
                                await repo.init();
                                await repo.deleteItem(item.id);

                                // Check if this was the last item; if so, allow demo mode again
                                final remainingItems = await repo.getAllItems();
                                if (remainingItems.isEmpty) {
                                  // Reset manual items flag to allow demo mode again
                                  ref
                                          .read(hasManualItemsProvider.notifier)
                                          .state =
                                      false;
                                  try {
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    await prefs.setBool(
                                      'has_manual_items',
                                      false,
                                    );
                                  } catch (_) {}
                                }

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
                            onQuantityChanged: (newQty) async {
                              final repo = ref.read(itemRepositoryProvider);
                              await repo.init();
                              final updated = item.copyWith(quantity: newQty);
                              await repo.saveItem(updated);
                              await _refreshItems();
                              setState(() {});
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
        onPressed: _openAddItemSheet,
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

  Widget _buildDemoModeWarning() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF3CD),
        border: Border(bottom: BorderSide(color: Color(0xFFFFD700))),
      ),
      child: Row(
        children: [
          const Text('📝', style: TextStyle(fontSize: 18)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Demo Mode',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF856404),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Showing sample items. Turn off in Settings to use real data.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF856404).withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakBadge(ProgressStats stats) {
    final streak = stats.noWasteStreak;
    final daysRemaining = streak.daysRemaining;
    final progress = streak.streakDays / 7;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9BD47F), Color(0xFF5E8F3E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                ),
                child: Text(
                  '🔥 ${streak.streakDays}-day streak',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('Level up'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'No Waste Week',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            daysRemaining == 0
                ? 'You made it! Keep the streak alive.'
                : 'Log $daysRemaining more saves to level up',
            style: AppTextStyles.body.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.35),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFE3F2A8)),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Judgement-free: compare with friends only when you opt in.',
            style: AppTextStyles.body.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  String _formatShortDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
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
                      ref.read(inventoryFilterProvider.notifier).state =
                          filterState.copyWith(category: null);
                      setState(() {});
                    },
                  ),
                if (filterState.location != null)
                  _buildFilterChip(
                    label: filterState.location!.displayName,
                    onRemove: () {
                      ref.read(inventoryFilterProvider.notifier).state =
                          filterState.copyWith(location: null);
                      setState(() {});
                    },
                  ),
                if (filterState.expiringSoonOnly)
                  _buildFilterChip(
                    label: 'Expiring Soon',
                    onRemove: () {
                      ref.read(inventoryFilterProvider.notifier).state =
                          filterState.copyWith(expiringSoonOnly: false);
                      setState(() {});
                    },
                  ),
                if (filterState.preparedOnly)
                  _buildFilterChip(
                    label: 'Prepared',
                    onRemove: () {
                      ref.read(inventoryFilterProvider.notifier).state =
                          filterState.copyWith(preparedOnly: false);
                      setState(() {});
                    },
                  ),
                if (filterState.createdAfter != null)
                  _buildFilterChip(
                    label:
                        'Added from ${_formatShortDate(filterState.createdAfter!)}',
                    onRemove: () {
                      ref.read(inventoryFilterProvider.notifier).state =
                          filterState.copyWith(createdAfter: null);
                      setState(() {});
                    },
                  ),
                if (filterState.createdBefore != null)
                  _buildFilterChip(
                    label:
                        'Added to ${_formatShortDate(filterState.createdBefore!)}',
                    onRemove: () {
                      ref.read(inventoryFilterProvider.notifier).state =
                          filterState.copyWith(createdBefore: null);
                      setState(() {});
                    },
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(inventoryFilterProvider.notifier).state =
                  const InventoryFilterState();
              _searchController.clear();
              setState(() {});
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Clear all', style: TextStyle(fontSize: 12)),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          ref.read(inventoryFilterProvider.notifier).state = ref
              .read(inventoryFilterProvider)
              .copyWith(searchQuery: value);
          setState(() {});
        },
        decoration: InputDecoration(
          hintText: 'Search items...',
          hintStyle: AppTextStyles.body.copyWith(color: AppColors.textTertiary),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: const BorderSide(color: AppColors.border, width: 0.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🛒', style: TextStyle(fontSize: 64)),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Your inventory is empty',
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Start tracking your food to reduce waste and save money',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
              ),
              onPressed: () {
                ref.read(telemetryClientProvider).enqueue({
                  'name': 'add_item_from_empty_state',
                  'properties': {},
                });
                _openAddItemSheet(emitOpenedTelemetry: false);
              },
              child: const Text('Add your first item'),
            ),
          ],
        ),
      ),
    );
  }
}
