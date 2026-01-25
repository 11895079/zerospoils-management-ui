library;

/// Item detail screen
/// Shows full item details with mark used/wasted actions

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/models/item_model.dart';
import '../di/repository_providers.dart';
import '../di/service_locator.dart' hide itemRepositoryProvider;
import '../widgets/app_button.dart';
import 'package:go_router/go_router.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  final String itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  bool _isLoading = true;
  Item? _item;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadItem();
    // Track screen view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(telemetryClientProvider).enqueue({
        'name': 'screen_viewed',
        'properties': {'screen_name': 'item_detail', 'item_id': widget.itemId},
      });
    });
  }

  Future<void> _loadItem() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(itemRepositoryProvider);
      await repository.init();
      final item = await repository.getItem(widget.itemId);

      if (mounted) {
        setState(() {
          _item = item;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading item: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markItemUsed() async {
    if (_item == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Used?'),
        content: Text('Mark "${_item!.name}" as consumed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Mark Used'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final repository = ref.read(itemRepositoryProvider);
      final updatedItem = _item!.copyWith(
        status: ItemStatus.consumed,
        updatedAt: DateTime.now(),
      );
      await repository.saveItem(updatedItem);

      // Track telemetry
      ref.read(telemetryClientProvider).enqueue({
        'name': 'item_marked_used',
        'properties': {
          'item_id': widget.itemId,
          'category': _item!.category.name,
          'location': _item!.location.name,
        },
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Item marked as used')));
        context.pop(); // Return to inventory
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error marking item as used: $e')),
        );
      }
    }
  }

  Future<void> _markItemWasted() async {
    if (_item == null) return;

    // Show waste reason selection dialog
    WasteReason? selectedReason;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Mark as Wasted'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Why was "${_item!.name}" wasted?'),
              const SizedBox(height: AppSpacing.md),
              ...WasteReason.values.map(
                (reason) => RadioListTile<WasteReason>(
                  title: Text(reason.displayName),
                  value: reason,
                  groupValue: selectedReason,
                  onChanged: (value) {
                    setDialogState(() => selectedReason = value);
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: selectedReason == null
                  ? null
                  : () => Navigator.pop(context, true),
              child: const Text('Mark Wasted'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || selectedReason == null || !mounted) return;

    try {
      final repository = ref.read(itemRepositoryProvider);
      final updatedItem = _item!.copyWith(
        status: ItemStatus.wasted,
        wasteReason: selectedReason,
        updatedAt: DateTime.now(),
      );
      await repository.saveItem(updatedItem);

      // Track telemetry
      ref.read(telemetryClientProvider).enqueue({
        'name': 'item_marked_wasted',
        'properties': {
          'item_id': widget.itemId,
          'category': _item!.category.name,
          'location': _item!.location.name,
          'waste_reason': selectedReason?.name ?? 'unknown',
        },
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Item marked as wasted')));
        context.pop(); // Return to inventory
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error marking item as wasted: $e')),
        );
      }
    }
  }

  Widget _buildDetailRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: highlight
                  ? AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    )
                  : AppTextStyles.body,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Item Details', style: AppTextStyles.h3),
        actions: [
          if (_item != null && _item!.status == ItemStatus.available)
            IconButton(
              onPressed: () {
                context.pushNamed(
                  'edit-item',
                  pathParameters: {'id': widget.itemId},
                );
              },
              icon: const Text('✏️', style: TextStyle(fontSize: 18)),
              tooltip: 'Edit Item',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _errorMessage!,
                    style: AppTextStyles.body.copyWith(color: AppColors.danger),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    text: 'Retry',
                    onPressed: _loadItem,
                    secondary: true,
                  ),
                ],
              ),
            )
          : _item == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Item not found',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    text: 'Go Back',
                    onPressed: () => context.pop(),
                    secondary: true,
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item name and status
                  Text(_item!.name, style: AppTextStyles.h2),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: _item!.status == ItemStatus.available
                          ? AppColors.success.withOpacity(0.1)
                          : _item!.status == ItemStatus.consumed
                          ? AppColors.textSecondary.withOpacity(0.1)
                          : AppColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _item!.status.displayName,
                      style: AppTextStyles.caption.copyWith(
                        color: _item!.status == ItemStatus.available
                            ? AppColors.success
                            : _item!.status == ItemStatus.consumed
                            ? AppColors.textSecondary
                            : AppColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Details section
                  _buildDetailRow('Category', _item!.category.displayName),
                  _buildDetailRow('Type', _item!.type.displayName),
                  _buildDetailRow('Location', _item!.location.displayName),
                  _buildDetailRow(
                    'Quantity',
                    '${_item!.quantity} ${_item!.unit.displayName}',
                  ),
                  if (_item!.expiryDate != null)
                    _buildDetailRow(
                      'Expires On',
                      DateFormat.yMMMd().format(_item!.expiryDate!),
                      highlight: _item!.expiryDate!.isBefore(
                        DateTime.now().add(const Duration(days: 3)),
                      ),
                    ),
                  if (_item!.preparedDate != null)
                    _buildDetailRow(
                      'Prepared On',
                      DateFormat.yMMMd().format(_item!.preparedDate!),
                    ),
                  if (_item!.purchasePrice != null)
                    _buildDetailRow(
                      'Purchase Price',
                      '\$${_item!.purchasePrice!.toStringAsFixed(2)}',
                    ),
                  if (_item!.wasteReason != null)
                    _buildDetailRow(
                      'Waste Reason',
                      _item!.wasteReason!.displayName,
                    ),
                  _buildDetailRow(
                    'Added On',
                    DateFormat.yMMMd().format(_item!.createdAt),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),

                  // Action buttons (only show for available items)
                  if (_item!.status == ItemStatus.available) ...[
                    const Divider(),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Mark Item Status',
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: '✓ Mark Used',
                            onPressed: _markItemUsed,
                            secondary: false,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppButton(
                            text: '✗ Mark Wasted',
                            onPressed: _markItemWasted,
                            secondary: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
