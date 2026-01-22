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
  final VoidCallback? onDelete;

  const ItemCard({super.key, required this.item, this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final daysLeft = item.daysUntilExpiry;
    final isExpired = daysLeft != null && daysLeft < 0;
    final isUrgent = daysLeft != null && daysLeft <= 1 && !isExpired;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding,
          vertical: AppSpacing.sm,
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isExpired
              ? const Color(0xFFFCE4EC) // Light pink background
              : isUrgent
              ? const Color(0xFFFFF8E1) // Light yellow background
              : Colors.white,
          border: Border.all(
            color: isExpired
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
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              alignment: Alignment.center,
              child: Text(
                _getCategoryEmoji(item.category),
                style: const TextStyle(fontSize: 28),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Item info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: AppTextStyles.h4),
                  const SizedBox(height: 2),
                  Text(
                    _getLocationDisplay(item.location),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getExpiryDisplay(),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isExpired
                          ? AppColors.danger
                          : isUrgent
                          ? AppColors.warning
                          : AppColors.textSecondary,
                      fontWeight: isUrgent || isExpired
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),

            // Delete button
            if (onDelete != null)
              GestureDetector(
                onTap: onDelete,
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('🗑️', style: TextStyle(fontSize: 18)),
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
