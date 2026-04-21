library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/models/item_model.dart';
import '../../domain/models/receipt_batch.dart';
import '../di/repository_providers.dart';

class LinkItemsToBatchDialog extends ConsumerStatefulWidget {
  final ReceiptBatch batch;

  const LinkItemsToBatchDialog({super.key, required this.batch});

  @override
  ConsumerState<LinkItemsToBatchDialog> createState() =>
      _LinkItemsToBatchDialogState();
}

class _LinkItemsToBatchDialogState
    extends ConsumerState<LinkItemsToBatchDialog> {
  late Future<List<Item>> _unlinkedItemsFuture;
  final Set<String> _selectedItemIds = {};
  bool _isLinking = false;

  @override
  void initState() {
    super.initState();
    _unlinkedItemsFuture = _loadUnlinkedItems();
  }

  Future<List<Item>> _loadUnlinkedItems() async {
    final itemRepo = ref.read(itemRepositoryProvider);
    await itemRepo.init();
    final allItems = await itemRepo.getAllItems();

    // Filter items that are not already linked to this batch
    return allItems
        .where((item) => item.receiptBatchId != widget.batch.id)
        .toList();
  }

  Future<void> _linkSelectedItems() async {
    if (_selectedItemIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one item to link')),
      );
      return;
    }

    setState(() => _isLinking = true);

    try {
      final itemRepo = ref.read(itemRepositoryProvider);

      // Get all items to find the selected ones
      final allItems = await itemRepo.getAllItems();

      for (final item in allItems) {
        if (_selectedItemIds.contains(item.id)) {
          // Update item with batch ID
          final updatedItem = item.copyWith(receiptBatchId: widget.batch.id);
          await itemRepo.saveItem(updatedItem);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Linked ${_selectedItemIds.length} item${_selectedItemIds.length > 1 ? 's' : ''} to batch',
            ),
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error linking items: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLinking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Link Items to Batch',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 0),
          Expanded(
            child: FutureBuilder<List<Item>>(
              future: _unlinkedItemsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading items: ${snapshot.error}',
                      style: AppTextStyles.body,
                    ),
                  );
                }

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      'No unlinked items available',
                      style: AppTextStyles.body,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = _selectedItemIds.contains(item.id);

                    return Container(
                      key: Key('link_item_${item.id}'),
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.primaryColor.withOpacity(0.1)
                            : theme.cardColor,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                        border: Border.all(
                          color: isSelected
                              ? theme.primaryColor
                              : theme.dividerColor,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: CheckboxListTile(
                        key: Key('link_item_checkbox_${item.id}'),
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value ?? false) {
                              _selectedItemIds.add(item.id);
                            } else {
                              _selectedItemIds.remove(item.id);
                            }
                          });
                        },
                        title: Text(item.name, style: AppTextStyles.body),
                        subtitle: Text(
                          '${item.category.toString().split('.').last} • ${item.status.toString().split('.').last}',
                          style: AppTextStyles.caption,
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 0),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLinking
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton(
                  onPressed: _isLinking ? null : _linkSelectedItems,
                  child: _isLinking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Link Selected'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
