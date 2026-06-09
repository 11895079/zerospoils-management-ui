library;

/// Badge service for checking and awarding badges
/// Based on planning/milestones/M3/300 acceptance criteria
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/badge_model.dart';
import '../models/item_model.dart';

/// Badge trigger requirements
class BadgeRequirements {
  // No Waste Week: 7 consecutive days with 0 waste
  static const int noWasteWeekDays = 7;

  // Used Before Expiry: 5+ items consumed before expiry in past 30 days
  static const int usedBeforeExpiryThreshold = 5;
  static const int usedBeforeExpiryLookbackDays = 30;

  // Cooked from Pantry: 3+ "prepared" items as consumed in past 30 days
  static const int cookedFromPantryThreshold = 3;
  static const int cookedFromPantryLookbackDays = 30;

  // Savings Milestone: Every $50 saved
  static const double savingsMilestoneIncrement = 50.0;

  // Environmental Impact: Every 5 kg CO₂ avoided
  // Assumption: ~2 kg CO₂ per kg of food waste prevented
  static const double environmentalImpactIncrement = 5.0;
  static const double co2PerKgWaste = 2.0;
}

/// Badge service for checking and awarding achievements
class BadgeService {
  // Stub for now - will be injected with real repository
  // final ItemRepository _repository;
  //
  // BadgeService(this._repository);

  /// Check if user earned "No Waste Week" badge
  /// Condition: 7 consecutive days with 0% waste
  Future<bool> checkNoWasteWeekBadge(
    List<Item> items,
    List<Item> wastedItems,
  ) async {
    if (items.isEmpty) {
      return false;
    }

    final today = _startOfDay(DateTime.now());
    final windowStart = today.subtract(
      const Duration(days: BadgeRequirements.noWasteWeekDays - 1),
    );

    final hasWasteInWindow = wastedItems.any((item) {
      final wasteDate = _startOfDay(item.updatedAt);
      return !wasteDate.isBefore(windowStart) && !wasteDate.isAfter(today);
    });

    if (hasWasteInWindow) {
      return false;
    }

    final earliestTrackedDate = items
        .map((item) => _startOfDay(item.createdAt))
        .reduce((a, b) => a.isBefore(b) ? a : b);

    // Require at least 7 calendar days of tracked history.
    return !earliestTrackedDate.isAfter(windowStart);
  }

  DateTime _startOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  /// Check if user earned "Used Before Expiry" badge
  /// Condition: 5+ items consumed before expiry in past 30 days
  Future<bool> checkUsedBeforeExpiryBadge(List<Item> items) async {
    final thirtyDaysAgo = DateTime.now().subtract(
      const Duration(days: BadgeRequirements.usedBeforeExpiryLookbackDays),
    );

    final consumedBeforeExpiry = items.where((item) {
      final isConsumed = item.status == ItemStatus.consumed;
      final hasExpiry = item.expiryDate != null;
      final isWithin30Days = item.updatedAt.isAfter(thirtyDaysAgo);
      final wasConsumedBeforeExpiry =
          hasExpiry && item.expiryDate!.isAfter(DateTime.now());

      return isConsumed && isWithin30Days && wasConsumedBeforeExpiry;
    }).length;

    return consumedBeforeExpiry >= BadgeRequirements.usedBeforeExpiryThreshold;
  }

  /// Check if user earned "Cooked from Pantry" badge
  /// Condition: 3+ "prepared" items consumed in past 30 days
  Future<bool> checkCookedFromPantryBadge(List<Item> items) async {
    final thirtyDaysAgo = DateTime.now().subtract(
      const Duration(days: BadgeRequirements.cookedFromPantryLookbackDays),
    );

    // Count items from pantry category that were consumed
    final pantryConsumed = items.where((item) {
      final isPantryCategory =
          item.category == ItemCategory.pantry ||
          item.category == ItemCategory.grains;
      final isConsumed = item.status == ItemStatus.consumed;
      final isWithin30Days = item.updatedAt.isAfter(thirtyDaysAgo);

      return isPantryCategory && isConsumed && isWithin30Days;
    }).length;

    return pantryConsumed >= BadgeRequirements.cookedFromPantryThreshold;
  }

  /// Check if user earned "Savings Milestone" badge
  /// Condition: Every $50 saved
  Future<BadgeProgress> checkSavingsMilestoneBadge(List<Item> items) async {
    // Calculate total savings from prevented waste
    double totalSavings = 0.0;

    for (final item in items) {
      if (item.status == ItemStatus.consumed && item.purchasePrice != null) {
        // Credit $0.50 for each item consumed (prevented 50% waste estimate)
        totalSavings += item.purchasePrice! * 0.5;
      }
    }

    final milestonesReached =
        (totalSavings / BadgeRequirements.savingsMilestoneIncrement).floor();

    return BadgeProgress(
      badgeType: BadgeType.savingsMilestone,
      currentProgress: totalSavings.toInt(),
      requiredProgress:
          ((milestonesReached + 1) *
                  BadgeRequirements.savingsMilestoneIncrement)
              .toInt(),
      progressPercentage:
          (totalSavings % BadgeRequirements.savingsMilestoneIncrement) /
          BadgeRequirements.savingsMilestoneIncrement,
      isEarned: milestonesReached > 0,
    );
  }

  /// Check if user earned "Environmental Impact" badge
  /// Condition: Every 5 kg CO₂ avoided
  Future<BadgeProgress> checkEnvironmentalImpactBadge(List<Item> items) async {
    // Estimate CO₂ prevented by items consumed vs wasted
    double estimatedKgPrevented = 0.0;

    for (final item in items) {
      if (item.status == ItemStatus.consumed) {
        // Rough estimate: 0.2 kg per item (average food item)
        estimatedKgPrevented += 0.2;
      }
    }

    final totalCO2Avoided =
        estimatedKgPrevented * BadgeRequirements.co2PerKgWaste;

    final milestonesReached =
        (totalCO2Avoided / BadgeRequirements.environmentalImpactIncrement)
            .floor();

    return BadgeProgress(
      badgeType: BadgeType.environmentalImpact,
      currentProgress: totalCO2Avoided.toInt(),
      requiredProgress:
          ((milestonesReached + 1) *
                  BadgeRequirements.environmentalImpactIncrement)
              .toInt(),
      progressPercentage:
          (totalCO2Avoided % BadgeRequirements.environmentalImpactIncrement) /
          BadgeRequirements.environmentalImpactIncrement,
      isEarned: milestonesReached > 0,
    );
  }

  /// Check all badges and return newly earned ones
  Future<List<Badge>> checkAllBadges(
    List<Item> items,
    List<Badge> previouslyEarned,
  ) async {
    final nowEarned = <Badge>[];
    final now = DateTime.now();

    // Get wasted items for no-waste-week check
    final wastedItems = items
        .where((item) => item.status == ItemStatus.wasted)
        .toList();

    // Check No Waste Week
    if (await checkNoWasteWeekBadge(items, wastedItems)) {
      if (!previouslyEarned.any((b) => b.type == BadgeType.noWasteWeek)) {
        nowEarned.add(
          Badge(
            id: BadgeType.noWasteWeek.id,
            type: BadgeType.noWasteWeek,
            emoji: BadgeType.noWasteWeek.emoji,
            name: BadgeType.noWasteWeek.displayName,
            description: '7 days without wasting food',
            earnedAt: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
    }

    // Check Used Before Expiry
    if (await checkUsedBeforeExpiryBadge(items)) {
      if (!previouslyEarned.any((b) => b.type == BadgeType.usedBeforeExpiry)) {
        nowEarned.add(
          Badge(
            id: BadgeType.usedBeforeExpiry.id,
            type: BadgeType.usedBeforeExpiry,
            emoji: BadgeType.usedBeforeExpiry.emoji,
            name: BadgeType.usedBeforeExpiry.displayName,
            description: 'Used 5+ items before they expired',
            earnedAt: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
    }

    // Check Cooked from Pantry
    if (await checkCookedFromPantryBadge(items)) {
      if (!previouslyEarned.any((b) => b.type == BadgeType.cookedFromPantry)) {
        nowEarned.add(
          Badge(
            id: BadgeType.cookedFromPantry.id,
            type: BadgeType.cookedFromPantry,
            emoji: BadgeType.cookedFromPantry.emoji,
            name: BadgeType.cookedFromPantry.displayName,
            description: 'Cooked 3 meals from pantry staples',
            earnedAt: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
    }

    // Note: Savings Milestone and Environmental Impact are checked separately
    // as they can be earned multiple times

    return nowEarned;
  }

  /// Get human-readable description for badge progress
  String getProgressDescription(BadgeType type, BadgeProgress progress) {
    return switch (type) {
      BadgeType.noWasteWeek =>
        'Keep your streak going! ${progress.requiredProgress - progress.currentProgress} days to go.',
      BadgeType.usedBeforeExpiry =>
        'You\'ve used ${progress.currentProgress}/${progress.requiredProgress} items before expiry.',
      BadgeType.cookedFromPantry =>
        'You\'ve cooked ${progress.currentProgress}/${progress.requiredProgress} meals from pantry.',
      BadgeType.savingsMilestone =>
        '\$${progress.currentProgress} saved. \$${progress.requiredProgress - progress.currentProgress} to next milestone!',
      BadgeType.environmentalImpact =>
        '${progress.currentProgress} kg CO₂ avoided. ${progress.requiredProgress - progress.currentProgress} kg to next milestone!',
    };
  }
}

/// Riverpod provider for BadgeService
final badgeServiceProvider = Provider((ref) {
  return BadgeService();
});
