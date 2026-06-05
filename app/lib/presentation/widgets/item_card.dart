library;

/// Item card for inventory list
/// Matches prototype design with icon, name, location, expiry

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../generated_l10n/app_localizations.dart';
import '../../generated_l10n/app_localizations_en.dart';
import '../../domain/models/item_model.dart';
import 'quantity_toggle.dart';
import 'item_icon.dart';

/// Formats a date as "MMM d" in the app's locale. Falls back to the default
/// locale if that locale's date symbols have not been initialized (e.g. in
/// widget tests that don't load GlobalMaterialLocalizations, which would
/// otherwise throw LocaleDataException).
String _formatMonthDay(DateTime date, String localeName) {
  try {
    return DateFormat('MMM d', localeName).format(date);
  } catch (_) {
    return DateFormat('MMM d').format(date);
  }
}

class ItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<int>? onQuantityChanged;

  const ItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEn();
    final textTheme = theme.textTheme;
    final daysLeft = item.daysUntilExpiry;
    final isExpired = daysLeft != null && daysLeft < 0;
    final isUrgent = daysLeft != null && daysLeft <= 1 && !isExpired;
    final isConsumedOrWasted = item.status != ItemStatus.available;
    final hasWasteBadge =
        item.wastePercentage != null && item.wastePercentage! > 0;
    final isDarkMode = theme.brightness == Brightness.dark;
    final secondaryTextColor =
        textTheme.bodySmall?.color ?? theme.colorScheme.onSurfaceVariant;

    final cardBackgroundColor = isConsumedOrWasted
        ? theme.colorScheme.surfaceContainerHigh
        : isExpired
        ? (isDarkMode ? const Color(0xFF3A1F25) : const Color(0xFFFCE4EC))
        : isUrgent
        ? (isDarkMode ? const Color(0xFF3A321C) : const Color(0xFFFFF8E1))
        : theme.cardColor;

    // Calculate progress percentage (0-1)
    double? expiryProgress;
    Color? progressColor;
    if (item.expiryDate != null) {
      final totalDays = item.expiryDate!.difference(item.createdAt).inDays;
      final daysElapsed = DateTime.now().difference(item.createdAt).inDays;
      if (totalDays > 0) {
        expiryProgress = (daysElapsed / totalDays).clamp(0.0, 1.0);
        // Color based on progress
        if (expiryProgress >= 0.85 || isExpired) {
          progressColor = AppColors.danger;
        } else if (expiryProgress >= 0.6) {
          progressColor = AppColors.warning;
        } else {
          progressColor = AppColors.success;
        }
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding,
          vertical: AppSpacing.sm,
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: cardBackgroundColor,
          border: Border.all(
            color: isConsumedOrWasted
                ? theme.dividerColor
                : isExpired
                ? AppColors.danger
                : isUrgent
                ? AppColors.warning
                : theme.dividerColor,
            width: isExpired || isUrgent ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isConsumedOrWasted
                        ? theme.dividerColor
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity: isConsumedOrWasted ? 0.4 : 1.0,
                    child: ItemIcon(
                      itemName: item.name,
                      category: item.category,
                      size: 28,
                      showBackground: false,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Main item details (name, unit, etc.)
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Opacity(
                        opacity: isConsumedOrWasted ? 0.5 : 1.0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (item.type == ItemType.prepared ||
                                hasWasteBadge ||
                                isConsumedOrWasted)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: 2,
                                  children: [
                                    if (item.type == ItemType.prepared)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.sm,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          l10n.itemCardPrepared,
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    if (hasWasteBadge)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.sm,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.danger.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          l10n.itemCardWastedPercent(
                                            item.wastePercentage ?? 0,
                                          ),
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.danger,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    if (isConsumedOrWasted)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.sm,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              item.status == ItemStatus.consumed
                                              ? AppColors.textSecondary
                                                    .withValues(alpha: 0.2)
                                              : AppColors.danger.withValues(
                                                  alpha: 0.2,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          item.status == ItemStatus.consumed
                                              ? l10n.itemCardUsed
                                              : l10n.itemCardWasted,
                                          style: AppTextStyles.caption.copyWith(
                                            color:
                                                item.status ==
                                                    ItemStatus.consumed
                                                ? AppColors.textSecondary
                                                : AppColors.danger,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 2),
                            if (item.brand?.trim().isNotEmpty == true) ...[
                              Text(
                                key: Key('item_card_brand_${item.id}'),
                                item.brand!.trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall?.copyWith(
                                  color: secondaryTextColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                            ],
                            Text(
                              item.unit.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: secondaryTextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Opacity(
                        opacity: isConsumedOrWasted ? 0.5 : 1.0,
                        child: Text(
                          _getLocationDisplay(item.location, l10n),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: secondaryTextColor,
                          ),
                        ),
                      ),
                      if (!isConsumedOrWasted) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _getExpiryDisplay(l10n),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: isExpired
                                      ? AppColors.danger
                                      : isUrgent
                                      ? AppColors.warning
                                      : secondaryTextColor,
                                  fontWeight: isUrgent || isExpired
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: isUrgent || isExpired ? 14 : 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.itemCardAddedDate(
                            _formatMonthDay(item.createdAt, l10n.localeName),
                          ),
                          style: textTheme.bodySmall?.copyWith(
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (item.purchasePrice != null)
                    Text(
                      '\$${item.purchasePrice!.toStringAsFixed(2)}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  QuantityToggle(
                    quantity: item.quantity,
                    isEnabled: !isConsumedOrWasted,
                    onConfirm: (newQty) {
                      if (onQuantityChanged != null &&
                          newQty != item.quantity) {
                        onQuantityChanged!(newQty);
                      }
                    },
                  ),
                  if (onEdit != null && !isConsumedOrWasted)
                    IconButton(
                      key: Key('item_card_edit_${item.id}'),
                      tooltip: l10n.itemCardEditTooltip,
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: onEdit,
                    ),
                  if (onDelete != null && !isConsumedOrWasted)
                    IconButton(
                      key: Key('item_card_delete_${item.id}'),
                      tooltip: l10n.itemCardDeleteTooltip,
                      icon: const Icon(Icons.delete_outline),
                      color: AppColors.danger,
                      onPressed: onDelete,
                    ),
                ],
              ),
            ),
            // Progress bar at bottom
            if (expiryProgress != null && !isConsumedOrWasted)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: expiryProgress,
                    backgroundColor: theme.dividerColor,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor!),
                    minHeight: 4,
                  ),
                ),
              ),
            if (item.expiryDate == null && !isConsumedOrWasted)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: 0.5,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.textTertiary,
                    ),
                    minHeight: 4,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getLocationDisplay(StorageLocation location, AppLocalizations l10n) {
    String locationLabel;
    switch (location) {
      case StorageLocation.fridge:
        locationLabel = l10n.itemCardLocationFridge;
        break;
      case StorageLocation.freezer:
        locationLabel = l10n.itemCardLocationFreezer;
        break;
      case StorageLocation.pantry:
        locationLabel = l10n.itemCardLocationPantry;
        break;
      case StorageLocation.other:
        locationLabel = l10n.itemCardLocationOther;
        break;
    }

    if (item.type == ItemType.prepared && item.preparedDate != null) {
      final formatted = _formatMonthDay(item.preparedDate!, l10n.localeName);
      return l10n.itemCardLocationPrepared(locationLabel, formatted);
    }

    return locationLabel;
  }

  String _getExpiryDisplay(AppLocalizations l10n) {
    if (item.expiryDate == null) return l10n.itemCardNoExpirySet;

    final days = item.daysUntilExpiry;
    if (days == null) return l10n.itemCardExpired;

    if (days < 0) return l10n.itemCardExpired;
    if (days == 0) return l10n.itemCardExpiresToday;
    if (days == 1) return l10n.itemCardExpiresTomorrow;
    return l10n.itemCardExpiresInDays(days);
  }
}
