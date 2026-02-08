library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/models/item_model.dart'
    show Item, ItemCategory, ItemStatus, Unit;
import '../../domain/models/shopping_list_item.dart';
import '../di/repository_providers.dart';
import '../di/service_locator.dart' show telemetryClientProvider;
import '../widgets/app_drawer.dart';
import '../widgets/item_entry_sheet.dart';

final shoppingListItemsProvider = FutureProvider<List<ShoppingListItem>>((
  ref,
) async {
  final repository = ref.watch(shoppingListRepositoryProvider);
  await repository.init();
  return repository.getAllItems();
});

class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(shoppingListItemsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Shopping List', style: AppTextStyles.h3),
        elevation: 1,
      ),
      drawer: const AppDrawer(),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Unable to load shopping list',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return _EmptyState(onAdd: () => _showAddItemSheet(context, ref));
          }

          final unpurchased = items.where((item) => !item.isPurchased).toList();
          final purchased = items.where((item) => item.isPurchased).toList();

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              _SectionHeader(
                key: const Key('shopping_unpurchased_section'),
                title: 'Next Shop',
              ),
              const SizedBox(height: AppSpacing.sm),
              ...unpurchased.map(
                (item) => _ShoppingItemTile(
                  key: Key('shopping_item_tile_${item.id}'),
                  item: item,
                  checkboxKey: Key('shopping_item_checkbox_${item.id}'),
                  onChanged: (value) async {
                    await _handleToggle(
                      context: context,
                      ref: ref,
                      item: item,
                      value: value,
                      isPurchasedSection: false,
                    );
                  },
                  onDelete: () async {
                    final repository = ref.read(shoppingListRepositoryProvider);
                    await repository.deleteItem(item.id);
                    ref.invalidate(shoppingListItemsProvider);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionHeader(
                key: const Key('shopping_purchased_section'),
                title: 'Purchased',
              ),
              const SizedBox(height: AppSpacing.sm),
              ...purchased.map(
                (item) => _ShoppingItemTile(
                  key: Key('shopping_item_tile_${item.id}'),
                  item: item,
                  checkboxKey: Key('shopping_item_checkbox_${item.id}'),
                  onChanged: (value) async {
                    await _handleToggle(
                      context: context,
                      ref: ref,
                      item: item,
                      value: value,
                      isPurchasedSection: true,
                    );
                  },
                  onDelete: () async {
                    final repository = ref.read(shoppingListRepositoryProvider);
                    await repository.deleteItem(item.id);
                    ref.invalidate(shoppingListItemsProvider);
                  },
                ),
              ),
              if (purchased.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    key: const Key('shopping_convert_batch_button'),
                    onPressed: () => _runBatchConvert(
                      context: context,
                      ref: ref,
                      items: List<ShoppingListItem>.from(purchased),
                    ),
                    child: Text('Convert Purchased (${purchased.length})'),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const Key('shopping_add_item_button'),
                  onPressed: () => _showAddItemSheet(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddItemSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (sheetContext) => _AddShoppingItemSheet(
        onSave: (name) async {
          final repository = ref.read(shoppingListRepositoryProvider);
          final now = DateTime.now();
          final item = ShoppingListItem(
            id: now.microsecondsSinceEpoch.toString(),
            name: name,
            createdAt: now,
            updatedAt: now,
          );
          await repository.saveShoppingListItem(item);
          ref.invalidate(shoppingListItemsProvider);
          if (sheetContext.mounted) Navigator.of(sheetContext).pop();
        },
      ),
    );
  }

  Future<void> _handleToggle({
    required BuildContext context,
    required WidgetRef ref,
    required ShoppingListItem item,
    required bool? value,
    required bool isPurchasedSection,
  }) async {
    final repository = ref.read(shoppingListRepositoryProvider);
    if (value == true) {
      if (!item.isPurchased) {
        await repository.markAsPurchased(item.id);
      }
      ref.invalidate(shoppingListItemsProvider);

      if (!context.mounted) return;

      final result = await showModalBottomSheet<ItemEntryResult>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg),
          ),
        ),
        builder: (_) => ItemEntrySheet(
          requireExpiry: true,
          seed: ItemEntrySeed(
            name: item.name,
            category: ItemCategory.fromString(item.category ?? 'other'),
            quantity: item.quantity,
            unit: Unit.fromString(item.unit ?? 'count'),
            purchasePrice: item.estimatedCost,
          ),
          sourceLabel: 'From Shopping List',
          showSkip: true,
        ),
      );
      if (result == null) {
        await repository.markAsUnpurchased(item.id);
        ref.invalidate(shoppingListItemsProvider);
        return;
      }

      if (result.skipped) {
        _trackConvertSkipped(ref, item.id);
        return;
      }

      await _convertToInventory(ref: ref, item: item, result: result);
      ref.invalidate(shoppingListItemsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.name} added to inventory'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    if (value == false && (item.isPurchased || isPurchasedSection)) {
      await repository.markAsUnpurchased(item.id);
      ref.invalidate(shoppingListItemsProvider);
    }
  }

  Future<void> _runBatchConvert({
    required BuildContext context,
    required WidgetRef ref,
    required List<ShoppingListItem> items,
  }) async {
    ItemEntryResult? batchDefaults;
    for (final item in items) {
      if (!context.mounted) return;
      final result =
          batchDefaults ??
          await showModalBottomSheet<ItemEntryResult>(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusLg),
              ),
            ),
            builder: (_) => ItemEntrySheet(
              requireExpiry: true,
              seed: ItemEntrySeed(
                name: item.name,
                category: ItemCategory.fromString(item.category ?? 'other'),
                quantity: item.quantity,
                unit: Unit.fromString(item.unit ?? 'count'),
                purchasePrice: item.estimatedCost,
              ),
              sourceLabel: 'From Shopping List',
              showSkip: true,
              showApplyToAll: true,
            ),
          );
      if (result == null) break;

      if (result.skipped) {
        _trackConvertSkipped(ref, item.id);
        continue;
      }

      final resolved = ItemEntryResult(
        name: item.name,
        category: result.category,
        location: result.location,
        quantity: result.quantity,
        unit: result.unit,
        expiryDate: result.expiryDate,
        purchasePrice: result.purchasePrice,
        type: result.type,
        preparedDate: result.preparedDate,
        applyToAll: result.applyToAll,
      );

      await _convertToInventory(ref: ref, item: item, result: resolved);
      ref.invalidate(shoppingListItemsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${resolved.name} added to inventory'),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      if (result.applyToAll && batchDefaults == null) {
        batchDefaults = result;
      }
    }
  }

  Future<void> _convertToInventory({
    required WidgetRef ref,
    required ShoppingListItem item,
    required ItemEntryResult result,
  }) async {
    if (result.expiryDate == null) return;

    final itemRepository = ref.read(itemRepositoryProvider);
    await itemRepository.init();

    final now = DateTime.now();
    final converted = Item(
      id: now.microsecondsSinceEpoch.toString(),
      name: result.name,
      category: result.category,
      type: result.type,
      preparedDate: result.preparedDate,
      location: result.location,
      quantity: result.quantity,
      unit: result.unit,
      expiryDate: result.expiryDate,
      purchasePrice: result.purchasePrice ?? item.estimatedCost,
      status: ItemStatus.available,
      createdAt: now,
      updatedAt: now,
    );

    await itemRepository.saveItem(converted);
    ref.invalidate(itemsFutureProvider);

    final shoppingRepository = ref.read(shoppingListRepositoryProvider);
    await shoppingRepository.deleteItem(item.id);

    _trackConverted(ref, item.id, true);
  }

  void _trackConverted(WidgetRef ref, String itemId, bool hadLocation) {
    final telemetry = ref.read(telemetryClientProvider);
    telemetry.enqueue({
      'name': 'shopping_converted',
      'properties': {
        'item_id': itemId,
        'entry_method': 'shopping_convert',
        'had_location': hadLocation,
      },
    });
  }

  void _trackConvertSkipped(WidgetRef ref, String itemId) {
    final telemetry = ref.read(telemetryClientProvider);
    telemetry.enqueue({
      'name': 'shopping_convert_skipped',
      'properties': {'item_id': itemId},
    });
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
    );
  }
}

class _ShoppingItemTile extends StatelessWidget {
  const _ShoppingItemTile({
    super.key,
    required this.item,
    required this.onChanged,
    required this.checkboxKey,
    required this.onDelete,
  });

  final ShoppingListItem item;
  final ValueChanged<bool?> onChanged;
  final Key checkboxKey;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isPurchased = item.isPurchased;
    return Dismissible(
      key: ValueKey('shopping_item_dismiss_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: const Icon(Icons.delete, color: AppColors.danger),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: CheckboxListTile(
          key: checkboxKey,
          value: isPurchased,
          onChanged: onChanged,
          title: Text(
            item.name,
            style: AppTextStyles.body.copyWith(
              color: isPurchased
                  ? AppColors.textSecondary
                  : AppColors.textPrimary,
              decoration: isPurchased ? TextDecoration.lineThrough : null,
            ),
          ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          key: const Key('shopping_empty_state'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 56),
            const SizedBox(height: AppSpacing.md),
            Text('Your shopping list is empty', style: AppTextStyles.h4),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add items you need to buy on your next grocery trip.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              key: const Key('shopping_empty_cta'),
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Start your shopping list'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddShoppingItemSheet extends StatefulWidget {
  const _AddShoppingItemSheet({required this.onSave});

  final ValueChanged<String> onSave;

  @override
  State<_AddShoppingItemSheet> createState() => _AddShoppingItemSheetState();
}

class _AddShoppingItemSheetState extends State<_AddShoppingItemSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Add Item', style: AppTextStyles.h4),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(labelText: 'Item name'),
            textInputAction: TextInputAction.done,
            onSubmitted: (value) {
              if (value.trim().isEmpty) return;
              widget.onSave(value.trim());
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final value = _controller.text.trim();
                    if (value.isEmpty) return;
                    widget.onSave(value);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
