library;
// ignore_for_file: deprecated_member_use

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

      ref.invalidate(itemsFutureProvider);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Item marked as used')));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).maybePop();
        });
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
    double wastePercentage = 100.0; // Default to 100%
    String notesText = '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final dialogWidth = MediaQuery.of(context).size.width * 0.9;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            titlePadding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            contentPadding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            actionsPadding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            title: Text('Mark as Wasted', style: AppTextStyles.h3),
            content: SizedBox(
              width: dialogWidth,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Why was "${_item!.name}" wasted?',
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Reason',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...WasteReason.values.map(
                      (reason) => RadioListTile<WasteReason>(
                        title: Text(reason.displayName),
                        value: reason,
                        groupValue: selectedReason,
                        dense: false,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: AppSpacing.xs,
                        ),
                        onChanged: (value) {
                          setDialogState(() => selectedReason = value);
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Percentage wasted',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: wastePercentage,
                            min: 0,
                            max: 100,
                            divisions: 20,
                            label: '${wastePercentage.toInt()}%',
                            onChanged: (value) {
                              setDialogState(() => wastePercentage = value);
                            },
                          ),
                        ),
                        SizedBox(
                          width: 56,
                          child: Text(
                            '${wastePercentage.toInt()}%',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Use your best estimate',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Notes (optional)',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      maxLines: 3,
                      onChanged: (value) => notesText = value,
                      decoration: InputDecoration(
                        hintText: 'e.g., half the pot burned',
                        hintStyle: TextStyle(color: AppColors.textSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                        contentPadding: const EdgeInsets.all(AppSpacing.md),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 48,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: 48,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: selectedReason == null
                            ? null
                            : () => Navigator.pop(context, true),
                        child: const Text('Confirm'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true || selectedReason == null || !mounted) return;

    try {
      final repository = ref.read(itemRepositoryProvider);
      final percentageInt = wastePercentage.round().clamp(0, 100);
      final remainingQuantity = percentageInt >= 100
          ? 0
          : (_item!.quantity * (1 - (percentageInt / 100))).ceil();
      final isFullyWasted = remainingQuantity <= 0;

      final updatedItem = _item!.copyWith(
        status: isFullyWasted ? ItemStatus.wasted : ItemStatus.available,
        wasteReason: selectedReason,
        wastePercentage: percentageInt,
        quantity: remainingQuantity.clamp(0, _item!.quantity),
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
          'waste_percentage': percentageInt,
          'has_notes': notesText.isNotEmpty,
        },
      });

      ref.invalidate(itemsFutureProvider);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Item marked as wasted')));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).maybePop();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error marking item as wasted: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Item Detail', style: AppTextStyles.h3),
        actions: [
          if (_item != null && _item!.status == ItemStatus.available)
            TextButton(
              onPressed: () async {
                await context.pushNamed(
                  'edit-item',
                  pathParameters: {'id': widget.itemId},
                );
                _loadItem(); // Reload after edit
              },
              child: const Text(
                'Edit',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Item hero section (large emoji + name)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xl,
                      horizontal: AppSpacing.lg,
                    ),
                    decoration: BoxDecoration(color: AppColors.cardBackground),
                    child: Column(
                      children: [
                        Text(
                          _item!.category.emoji,
                          style: const TextStyle(fontSize: 64),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _item!.name,
                          style: AppTextStyles.h1,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Details card
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppColors.border, width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              'Category',
                              '${_item!.category.emoji} ${_item!.category.displayName}',
                            ),
                            const Divider(height: 1),
                            _buildInfoRow('Type', _item!.type.displayName),
                            const Divider(height: 1),
                            if (_item!.preparedDate != null) ...[
                              _buildInfoRow(
                                'Prepared Date',
                                DateFormat.yMMMd().format(_item!.preparedDate!),
                              ),
                              const Divider(height: 1),
                            ] else ...[
                              _buildInfoRow('Prepared Date', '—'),
                              const Divider(height: 1),
                            ],
                            _buildInfoRow(
                              'Location',
                              '${_item!.location.emoji} ${_item!.location.displayName}',
                            ),
                            const Divider(height: 1),
                            _buildInfoRow(
                              'Quantity',
                              '${_item!.quantity} ${_item!.unit.displayName}',
                            ),
                            const Divider(height: 1),
                            _buildInfoRow(
                              'Added',
                              DateFormat.yMMMd().format(_item!.createdAt),
                            ),
                            const Divider(height: 1),
                            if (_item!.expiryDate != null) ...[
                              _buildInfoRow(
                                'Expiry Date',
                                DateFormat.yMMMd().format(_item!.expiryDate!),
                              ),
                              const Divider(height: 1),
                            ],
                            _buildInfoRow(
                              'Status',
                              _getStatusText(),
                              valueColor: _getStatusColor(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Action buttons (only show for available items)
                  if (_item!.status == ItemStatus.available) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 48,
                            child: TextButton(
                              onPressed: () async {
                                await context.pushNamed(
                                  'edit-item',
                                  pathParameters: {'id': widget.itemId},
                                );
                                _loadItem();
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                              ),
                              child: const Text('Edit Item'),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppButton(
                            text: '✓ Mark as Consumed',
                            onPressed: _markItemUsed,
                            secondary: false,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppButton(
                            text: '🗑️ Mark as Wasted',
                            onPressed: _markItemWasted,
                            secondary: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText() {
    if (_item!.status != ItemStatus.available) {
      return _item!.status.displayName;
    }

    if (_item!.expiryDate == null) {
      return 'Available';
    }

    final daysLeft = _item!.expiryDate!.difference(DateTime.now()).inDays;

    if (daysLeft < 0) {
      return 'Expired';
    } else if (daysLeft == 0) {
      return 'Expires today';
    } else if (daysLeft == 1) {
      return 'Expires in 1 day';
    } else {
      return 'Expires in $daysLeft days';
    }
  }

  Color? _getStatusColor() {
    if (_item!.status != ItemStatus.available) {
      return _item!.status == ItemStatus.consumed
          ? AppColors.success
          : AppColors.danger;
    }

    if (_item!.expiryDate == null) {
      return AppColors.success;
    }

    final daysLeft = _item!.expiryDate!.difference(DateTime.now()).inDays;

    if (daysLeft < 0) {
      return AppColors.danger;
    } else if (daysLeft <= 3) {
      return AppColors.warning;
    } else {
      return AppColors.success;
    }
  }
}
