library;

/// Item card for inventory list
/// Matches prototype design with icon, name, location, expiry

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/models/item_model.dart';

class ItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final daysLeft = item.daysUntilExpiry;
    final isExpired = daysLeft != null && daysLeft < 0;
    final isUrgent = daysLeft != null && daysLeft <= 1 && !isExpired;
    final isConsumedOrWasted = item.status != ItemStatus.available;

    // Calculate progress percentage (0-1)
    double? expiryProgress;
    Color? progressColor;
    if (item.expiryDate != null && item.createdAt != null) {
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
          color: isConsumedOrWasted
              ? AppColors.backgroundSecondary
              : isExpired
              ? const Color(0xFFFCE4EC) // Light pink background
              : isUrgent
              ? const Color(0xFFFFF8E1) // Light yellow background
              : Colors.white,
          border: Border.all(
            color: isConsumedOrWasted
                ? AppColors.border
                : isExpired
                ? AppColors.danger
                : isUrgent
                ? AppColors.warning
                : AppColors.border,
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
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isConsumedOrWasted
                        ? AppColors.border
                        : AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity: isConsumedOrWasted ? 0.4 : 1.0,
                    child: Text(
                      _getCategoryEmoji(item.category),
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Item info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Opacity(
                              opacity: isConsumedOrWasted ? 0.5 : 1.0,
                              child: Text(item.name, style: AppTextStyles.h4),
                            ),
                          ),
                          if (isConsumedOrWasted)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: item.status == ItemStatus.consumed
                                    ? AppColors.textSecondary.withOpacity(0.2)
                                    : AppColors.danger.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.status == ItemStatus.consumed
                                    ? 'Used'
                                    : 'Wasted',
                                style: AppTextStyles.caption.copyWith(
                                  color: item.status == ItemStatus.consumed
                                      ? AppColors.textSecondary
                                      : AppColors.danger,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Opacity(
                        opacity: isConsumedOrWasted ? 0.5 : 1.0,
                        child: Text(
                          _getLocationDisplay(item.location),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (!isConsumedOrWasted) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _getExpiryDisplay(),
                                style: AppTextStyles.body.copyWith(
                                  color: isExpired
                                      ? AppColors.danger
                                      : isUrgent
                                      ? AppColors.warning
                                      : AppColors.textSecondary,
                                  fontWeight: isUrgent || isExpired
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: isUrgent || isExpired ? 14 : 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                if (onEdit != null && !isConsumedOrWasted)
                  GestureDetector(
                    onTap: onEdit,
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('✏️', style: TextStyle(fontSize: 18)),
                    ),
                  ),

                if (onDelete != null && !isConsumedOrWasted)
                  GestureDetector(
                    onTap: onDelete,
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('🗑️', style: TextStyle(fontSize: 18)),
                    ),
                  ),
              ],
            ),
            // Progress bar at bottom
            if (expiryProgress != null && !isConsumedOrWasted)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: expiryProgress,
                    backgroundColor: AppColors.border,
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

  String _getCategoryEmoji(ItemCategory category) {
    switch (category) {
      case ItemCategory.dairy:
        return '🥛';
      case ItemCategory.produce:
        return '🍎';
      case ItemCategory.meat:
        return '🍗';
      case ItemCategory.grains:
        return '🌾';
      case ItemCategory.pantry:
        return '🗄️';
      case ItemCategory.other:
        return '📦';
    }
  }

  String _getLocationDisplay(StorageLocation location) {
    switch (location) {
      case StorageLocation.fridge:
        return '❄️ Fridge';
      case StorageLocation.freezer:
        return '🧊 Freezer';
      case StorageLocation.pantry:
        return '🗄️ Pantry';
      case StorageLocation.other:
        return '🏠 Other';
    }
  }

  String _getExpiryDisplay() {
    if (item.expiryDate == null) return 'No expiry set';

    final days = item.daysUntilExpiry;
    if (days == null) return 'Expired';

    if (days < 0) return 'Expired';
    if (days == 0) return 'Expires today ⚠️';
    if (days == 1) return 'Expires tomorrow';
    return 'Expires in $days days';
  }
}
