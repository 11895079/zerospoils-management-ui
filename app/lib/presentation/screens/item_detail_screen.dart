library;
// ignore_for_file: deprecated_member_use

/// Item detail screen
/// Shows full item details with mark used/wasted actions

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/models/item_model.dart';
import '../../domain/models/receipt_batch.dart';
import '../../core/notifications/reminder_attribution_store.dart';
import '../di/repository_providers.dart';
import '../di/service_locator.dart' hide itemRepositoryProvider;
import '../widgets/app_button.dart';
import '../widgets/item_icon.dart';
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
  ReceiptBatch? _linkedBatch;
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
      ReceiptBatch? linkedBatch;
      if (item?.receiptBatchId != null) {
        final batchRepository = ref.read(receiptBatchRepositoryProvider);
        await batchRepository.init();
        linkedBatch = await batchRepository.getBatch(item!.receiptBatchId!);
      }

      if (mounted) {
        setState(() {
          _item = item;
          _linkedBatch = linkedBatch;
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

    final currentQty = _item!.quantity <= 0 ? 1 : _item!.quantity;
    var consumePercent = 100.0;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final consumedQty = ((currentQty * consumePercent / 100).clamp(
              1,
              currentQty,
            )).round();
            return AlertDialog(
              title: const Text('Mark as Consumed'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('How much did you consume?'),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '${consumePercent.round()}% ($consumedQty of $currentQty)',
                    key: const Key('consume_percentage_value'),
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Slider(
                    key: const Key('consume_percentage_slider'),
                    value: consumePercent,
                    min: 1,
                    max: 100,
                    divisions: 99,
                    label: '${consumePercent.round()}%',
                    onChanged: (value) =>
                        setDialogState(() => consumePercent = value),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  key: const Key('consume_cancel_button'),
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  key: const Key('consume_confirm_button'),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      final repository = ref.read(itemRepositoryProvider);
      final consumedQty = ((_item!.quantity * consumePercent / 100).clamp(
        1,
        _item!.quantity,
      )).round();
      final remaining = (_item!.quantity - consumedQty)
          .clamp(0, _item!.quantity)
          .toInt();
      final isFullyConsumed = remaining == 0;
      final updatedItem = _item!.copyWith(
        status: isFullyConsumed ? ItemStatus.consumed : ItemStatus.available,
        quantity: remaining,
        updatedAt: DateTime.now(),
      );
      await repository.saveItem(updatedItem);
      final zestoService = ref.read(zestoServiceProvider);
      unawaited(zestoService.onItemConsumed(expiryDate: _item!.expiryDate));

      // Track telemetry
      final attribution = ReminderAttributionStore().getContext();
      final properties = {
        'item_id': widget.itemId,
        'category': _item!.category.name,
        'location': _item!.location.name,
        'consumed_quantity': consumedQty,
        'remaining_quantity': remaining,
        'consumed_percentage': consumePercent.round(),
      };

      // Add source attribution if opened from reminder
      if (attribution != null && attribution.itemId == widget.itemId) {
        properties['source'] = 'reminder';
      }

      ref.read(telemetryClientProvider).enqueue({
        'name': isFullyConsumed
            ? 'item_marked_used'
            : 'item_partially_consumed',
        'properties': properties,
      });

      ref.invalidate(itemsFutureProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFullyConsumed
                  ? 'Item marked as consumed'
                  : 'Item updated with remaining quantity',
            ),
          ),
        );
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
            key: const Key('waste_dialog'),
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
                        key: Key('waste_reason_${reason.name}'),
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
                        key: const Key('waste_cancel_button'),
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
                        key: const Key('waste_confirm_button'),
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
      final zestoService = ref.read(zestoServiceProvider);
      unawaited(zestoService.onItemWasted(itemCategory: _item!.category.name));

      // Track telemetry
      final attribution = ReminderAttributionStore().getContext();
      final properties = {
        'item_id': widget.itemId,
        'category': _item!.category.name,
        'location': _item!.location.name,
        'waste_reason': selectedReason?.name ?? 'unknown',
        'waste_percentage': percentageInt,
        'has_notes': notesText.isNotEmpty,
      };

      // Add source attribution if opened from reminder
      if (attribution != null && attribution.itemId == widget.itemId) {
        properties['source'] = 'reminder';
      }

      ref.read(telemetryClientProvider).enqueue({
        'name': 'item_marked_wasted',
        'properties': properties,
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
    final theme = Theme.of(context);
    // Watch date format preference
    final dateFormatAsync = ref.watch(dateFormatPreferenceProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Item Detail'),
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
              child: Text(
                'Edit',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 16,
                ),
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
                    key: const Key('item_detail_error_message'),
                    _errorMessage!,
                    style: AppTextStyles.body.copyWith(color: AppColors.danger),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    text: 'Retry',
                    onPressed: _loadItem,
                    key: const Key('item_detail_retry_button'),
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
                    key: const Key('item_detail_not_found'),
                    'Item not found',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    text: 'Go Back',
                    onPressed: () => context.pop(),
                    key: const Key('item_detail_go_back'),
                    secondary: true,
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Item hero section (large icon + name)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xl,
                      horizontal: AppSpacing.lg,
                    ),
                    decoration: BoxDecoration(color: theme.cardColor),
                    child: Column(
                      children: [
                        ItemIcon(
                          itemName: _item!.name,
                          category: _item!.category,
                          size: 64,
                          showBackground: true,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          key: const Key('item_detail_name'),
                          _item!.name,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_item!.brand?.trim().isNotEmpty == true) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            key: const Key('item_detail_brand'),
                            _item!.brand!.trim(),
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Details card
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Card(
                      color: theme.cardTheme.color ?? theme.cardColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: theme.dividerColor, width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              'Brand',
                              _item!.brand?.trim().isNotEmpty == true
                                  ? _item!.brand!.trim()
                                  : '—',
                              valueKey: const Key('item_detail_brand_value'),
                            ),
                            const Divider(height: 1),
                            _buildInfoRow(
                              'Category',
                              '${_item!.customCategoryName != null ? '🏷️' : _item!.category.emoji} ${_item!.categoryLabel}',
                              valueKey: const Key('item_detail_category'),
                            ),
                            const Divider(height: 1),
                            _buildInfoRow(
                              'Type',
                              _item!.type.displayName,
                              valueKey: const Key('item_detail_type'),
                            ),
                            const Divider(height: 1),
                            if (_item!.preparedDate != null) ...[
                              _buildInfoRow(
                                'Prepared Date',
                                dateFormatAsync.when(
                                  data: (format) =>
                                      AppDateFormatter.formatDateWithYear(
                                        _item!.preparedDate!,
                                        format,
                                      ),
                                  loading: () => '...',
                                  error: (_, _) => DateFormat.yMMMd().format(
                                    _item!.preparedDate!,
                                  ),
                                ),
                                valueKey: const Key(
                                  'item_detail_prepared_date',
                                ),
                              ),
                              const Divider(height: 1),
                            ] else ...[
                              _buildInfoRow('Prepared Date', '—'),
                              const Divider(height: 1),
                            ],
                            _buildInfoRow(
                              'Location',
                              '${_item!.location.emoji} ${_item!.location.displayName}',
                              valueKey: const Key('item_detail_location'),
                            ),
                            const Divider(height: 1),
                            _buildInfoRow(
                              'Quantity',
                              '${_item!.quantity} ${_item!.unit.displayName}',
                              valueKey: const Key('item_detail_quantity'),
                            ),
                            const Divider(height: 1),
                            _buildInfoRow(
                              'Added',
                              dateFormatAsync.when(
                                data: (format) =>
                                    AppDateFormatter.formatDateWithYear(
                                      _item!.createdAt,
                                      format,
                                    ),
                                loading: () => '...',
                                error: (_, _) =>
                                    DateFormat.yMMMd().format(_item!.createdAt),
                              ),
                              valueKey: const Key('item_detail_added'),
                            ),
                            const Divider(height: 1),
                            _buildInfoRow(
                              'Shopping Batch',
                              _item!.receiptBatchId == null
                                  ? '—'
                                  : (_linkedBatch?.storeName
                                                ?.trim()
                                                .isNotEmpty ==
                                            true
                                        ? '${_linkedBatch!.storeName!.trim()} (${_item!.receiptBatchId})'
                                        : _item!.receiptBatchId!),
                              valueKey: const Key('item_detail_batch'),
                            ),
                            if (_item!.receiptBatchId != null) ...[
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.xs,
                                  bottom: AppSpacing.sm,
                                ),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    key: const Key(
                                      'item_detail_open_batch_button',
                                    ),
                                    onPressed: () {
                                      context.pushNamed(
                                        'receipt-batch-detail',
                                        pathParameters: {
                                          'id': _item!.receiptBatchId!,
                                        },
                                      );
                                    },
                                    child: const Text('View Batch'),
                                  ),
                                ),
                              ),
                            ],
                            const Divider(height: 1),
                            if (_item!.expiryDate != null) ...[
                              _buildInfoRow(
                                'Expiry Date',
                                dateFormatAsync.when(
                                  data: (format) =>
                                      AppDateFormatter.formatDateWithYear(
                                        _item!.expiryDate!,
                                        format,
                                      ),
                                  loading: () => '...',
                                  error: (_, _) => DateFormat.yMMMd().format(
                                    _item!.expiryDate!,
                                  ),
                                ),
                                valueKey: const Key('item_detail_expiry'),
                              ),
                              const Divider(height: 1),
                            ],
                            _buildInfoRow(
                              'Status',
                              _getStatusText(),
                              valueColor: _getStatusColor(),
                              valueKey: const Key('item_detail_status'),
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
                              key: const Key('item_edit_button'),
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
                            key: const Key('item_mark_consumed_button'),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppButton(
                            text: '🗑️ Mark as Wasted',
                            onPressed: _markItemWasted,
                            secondary: true,
                            key: const Key('item_mark_wasted_button'),
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

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    Key? valueKey,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          Text(
            key: valueKey,
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
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
