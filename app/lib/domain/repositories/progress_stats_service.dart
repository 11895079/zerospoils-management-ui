library;

import '../models/item_model.dart';
import '../models/badge_model.dart';
import '../repositories/badge_service.dart';
import '../utils/expiry_classifier.dart';
import '../models/expiry_bucket.dart';

class TelemetryAggregationFields {
  static const Map<String, List<String>> requiredFields = {
    'item_added': [
      'source',
      'entry_method',
      'category',
      'location',
      'has_expiry',
      'has_expiry_date',
    ],
    'item_wasted': ['category', 'days_until_expiry', 'waste_reason', 'cost'],
    'item_marked_wasted': ['category', 'location', 'waste_reason'],
    'item_marked_used': ['category', 'location'],
    'inventory_viewed': ['filter_applied', 'sort_by'],
    'filters_applied': [
      'category',
      'location',
      'expiringSoonOnly',
      'hideConsumed',
      'searchQuery',
    ],
    'reminder_opened': ['item_category', 'days_until_expiry'],
    'tab_switched': ['tab_name'],
    'screen_viewed': ['screen_name'],
  };
}

class TelemetryAggregates {
  final Map<String, int> eventCounts;
  final Map<String, int> itemAddedBySource;
  final Map<String, int> itemAddedByCategory;
  final Map<String, int> itemWastedByReason;
  final Map<String, int> itemWastedByCategory;
  final Map<String, int> reminderOpenedByCategory;
  final Map<String, int> inventoryViewedBySort;
  final Map<String, int> tabSwitchedByTab;
  final Map<String, int> screenViewedByScreen;
  final Map<String, int> filtersAppliedByCategory;

  const TelemetryAggregates({
    required this.eventCounts,
    required this.itemAddedBySource,
    required this.itemAddedByCategory,
    required this.itemWastedByReason,
    required this.itemWastedByCategory,
    required this.reminderOpenedByCategory,
    required this.inventoryViewedBySort,
    required this.tabSwitchedByTab,
    required this.screenViewedByScreen,
    required this.filtersAppliedByCategory,
  });

  factory TelemetryAggregates.empty() {
    return const TelemetryAggregates(
      eventCounts: {},
      itemAddedBySource: {},
      itemAddedByCategory: {},
      itemWastedByReason: {},
      itemWastedByCategory: {},
      reminderOpenedByCategory: {},
      inventoryViewedBySort: {},
      tabSwitchedByTab: {},
      screenViewedByScreen: {},
      filtersAppliedByCategory: {},
    );
  }
}

class ProgressStats {
  final int totalItems;
  final int availableItems;
  final int consumedItems;
  final int wastedItems;
  final Map<ItemCategory, int> categoryCounts;
  final Map<StorageLocation, int> locationCounts;
  final Map<ItemType, int> typeCounts;
  final int expiringTodayCount;
  final int expiringThisWeekCount;
  final int expiringSoonCount;
  final int expiredCount;
  final int noExpiryCount;
  final double totalValue;
  final double consumedValue;
  final double wastedValue;
  final double savedValue;
  final int addedLast7Days;
  final int addedLast30Days;
  final int updatedLast7Days;
  final int updatedLast30Days;
  final StreakData noWasteStreak;
  final Map<BadgeType, BadgeProgress> badgeProgress;
  final TelemetryAggregates telemetry;

  const ProgressStats({
    required this.totalItems,
    required this.availableItems,
    required this.consumedItems,
    required this.wastedItems,
    required this.categoryCounts,
    required this.locationCounts,
    required this.typeCounts,
    required this.expiringTodayCount,
    required this.expiringThisWeekCount,
    required this.expiringSoonCount,
    required this.expiredCount,
    required this.noExpiryCount,
    required this.totalValue,
    required this.consumedValue,
    required this.wastedValue,
    required this.savedValue,
    required this.addedLast7Days,
    required this.addedLast30Days,
    required this.updatedLast7Days,
    required this.updatedLast30Days,
    required this.noWasteStreak,
    required this.badgeProgress,
    required this.telemetry,
  });
}

class ProgressStatsService {
  final BadgeService badgeService;

  ProgressStatsService({required this.badgeService});

  Future<ProgressStats> build({
    required List<Item> items,
    required List<Map<String, dynamic>> telemetryEvents,
    DateTime? now,
  }) async {
    final effectiveNow = now ?? DateTime.now();
    final totals = _computeTotals(items);
    final categoryCounts = _buildCategoryCounts(items);
    final locationCounts = _buildLocationCounts(items);
    final typeCounts = _buildTypeCounts(items);

    final expiryStats = _computeExpiryStats(items, effectiveNow);
    final valueStats = _computeValueStats(items);
    final recencyStats = _computeRecencyStats(items, effectiveNow);
    final streak = _computeNoWasteStreak(items, effectiveNow);
    final badgeProgress = await _computeBadgeProgress(
      items,
      streak,
      effectiveNow,
    );
    final telemetry = _aggregateTelemetry(telemetryEvents);

    return ProgressStats(
      totalItems: totals.totalItems,
      availableItems: totals.availableItems,
      consumedItems: totals.consumedItems,
      wastedItems: totals.wastedItems,
      categoryCounts: categoryCounts,
      locationCounts: locationCounts,
      typeCounts: typeCounts,
      expiringTodayCount: expiryStats.expiringTodayCount,
      expiringThisWeekCount: expiryStats.expiringThisWeekCount,
      expiringSoonCount: expiryStats.expiringSoonCount,
      expiredCount: expiryStats.expiredCount,
      noExpiryCount: expiryStats.noExpiryCount,
      totalValue: valueStats.totalValue,
      consumedValue: valueStats.consumedValue,
      wastedValue: valueStats.wastedValue,
      savedValue: valueStats.savedValue,
      addedLast7Days: recencyStats.addedLast7Days,
      addedLast30Days: recencyStats.addedLast30Days,
      updatedLast7Days: recencyStats.updatedLast7Days,
      updatedLast30Days: recencyStats.updatedLast30Days,
      noWasteStreak: streak,
      badgeProgress: badgeProgress,
      telemetry: telemetry,
    );
  }

  _Totals _computeTotals(List<Item> items) {
    final totalItems = items.length;
    final availableItems = items
        .where((item) => item.status == ItemStatus.available)
        .length;
    final consumedItems = items
        .where((item) => item.status == ItemStatus.consumed)
        .length;
    final wastedItems = items
        .where((item) => item.status == ItemStatus.wasted)
        .length;

    return _Totals(
      totalItems: totalItems,
      availableItems: availableItems,
      consumedItems: consumedItems,
      wastedItems: wastedItems,
    );
  }

  Map<ItemCategory, int> _buildCategoryCounts(List<Item> items) {
    final counts = {for (final c in ItemCategory.values) c: 0};
    for (final item in items) {
      counts[item.category] = (counts[item.category] ?? 0) + 1;
    }
    return counts;
  }

  Map<StorageLocation, int> _buildLocationCounts(List<Item> items) {
    final counts = {for (final l in StorageLocation.values) l: 0};
    for (final item in items) {
      counts[item.location] = (counts[item.location] ?? 0) + 1;
    }
    return counts;
  }

  Map<ItemType, int> _buildTypeCounts(List<Item> items) {
    final counts = {for (final t in ItemType.values) t: 0};
    for (final item in items) {
      counts[item.type] = (counts[item.type] ?? 0) + 1;
    }
    return counts;
  }

  _ExpiryStats _computeExpiryStats(List<Item> items, DateTime now) {
    int expiringToday = 0;
    int expiringThisWeek = 0;
    int expired = 0;
    int expiringSoon = 0;
    int noExpiry = 0;

    for (final item in items) {
      if (item.expiryDate == null) {
        noExpiry++;
        continue;
      }

      final days = _daysUntilExpiry(item, now);
      if (days == null) continue;

      if (days < 0) {
        expired++;
      }

      if (days >= 0 && days <= 3) {
        expiringSoon++;
      }

      final bucket = ExpiryClassifier.classify(item, now: now);
      if (bucket == ExpiryBucket.today) expiringToday++;
      if (bucket == ExpiryBucket.thisWeek) expiringThisWeek++;
    }

    return _ExpiryStats(
      expiringTodayCount: expiringToday,
      expiringThisWeekCount: expiringThisWeek,
      expiringSoonCount: expiringSoon,
      expiredCount: expired,
      noExpiryCount: noExpiry,
    );
  }

  _ValueStats _computeValueStats(List<Item> items) {
    double totalValue = 0;
    double consumedValue = 0;
    double wastedValue = 0;

    for (final item in items) {
      final price = item.purchasePrice;
      if (price == null) continue;
      totalValue += price;
      if (item.status == ItemStatus.consumed) consumedValue += price;
      if (item.status == ItemStatus.wasted) wastedValue += price;
    }

    final savedValue = consumedValue * 0.5;

    return _ValueStats(
      totalValue: totalValue,
      consumedValue: consumedValue,
      wastedValue: wastedValue,
      savedValue: savedValue,
    );
  }

  _RecencyStats _computeRecencyStats(List<Item> items, DateTime now) {
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    int addedLast7 = 0;
    int addedLast30 = 0;
    int updatedLast7 = 0;
    int updatedLast30 = 0;

    for (final item in items) {
      if (item.createdAt.isAfter(sevenDaysAgo)) addedLast7++;
      if (item.createdAt.isAfter(thirtyDaysAgo)) addedLast30++;
      if (item.updatedAt.isAfter(sevenDaysAgo)) updatedLast7++;
      if (item.updatedAt.isAfter(thirtyDaysAgo)) updatedLast30++;
    }

    return _RecencyStats(
      addedLast7Days: addedLast7,
      addedLast30Days: addedLast30,
      updatedLast7Days: updatedLast7,
      updatedLast30Days: updatedLast30,
    );
  }

  StreakData _computeNoWasteStreak(List<Item> items, DateTime now) {
    final wasteDates = <String>{};
    for (final item in items) {
      if (item.status == ItemStatus.wasted) {
        final date = _dateKey(item.updatedAt);
        wasteDates.add(date);
      }
    }

    int streakDays = 0;
    for (var i = 0; i < BadgeRequirements.noWasteWeekDays; i++) {
      final date = now.subtract(Duration(days: i));
      if (wasteDates.contains(_dateKey(date))) break;
      streakDays++;
    }

    final latestActivity = items.isEmpty
        ? now
        : items.map((i) => i.updatedAt).reduce((a, b) => a.isAfter(b) ? a : b);

    return StreakData(
      badgeType: BadgeType.noWasteWeek,
      streakDays: streakDays.clamp(0, BadgeRequirements.noWasteWeekDays),
      streakStartDate: streakDays == 0
          ? now
          : now.subtract(Duration(days: streakDays - 1)),
      lastActivityDate: latestActivity,
      isActive: streakDays > 0,
    );
  }

  Future<Map<BadgeType, BadgeProgress>> _computeBadgeProgress(
    List<Item> items,
    StreakData streak,
    DateTime now,
  ) async {
    final usedBeforeExpiryProgress = _buildBadgeProgress(
      type: BadgeType.usedBeforeExpiry,
      current: _countConsumedBeforeExpiry(items, now),
      required: BadgeRequirements.usedBeforeExpiryThreshold,
    );

    final cookedFromPantryProgress = _buildBadgeProgress(
      type: BadgeType.cookedFromPantry,
      current: _countPantryConsumed(items, now),
      required: BadgeRequirements.cookedFromPantryThreshold,
    );

    final noWasteProgress = _buildBadgeProgress(
      type: BadgeType.noWasteWeek,
      current: streak.streakDays,
      required: BadgeRequirements.noWasteWeekDays,
    );

    final savingsProgress = await badgeService.checkSavingsMilestoneBadge(
      items,
    );
    final impactProgress = await badgeService.checkEnvironmentalImpactBadge(
      items,
    );

    return {
      BadgeType.noWasteWeek: noWasteProgress,
      BadgeType.usedBeforeExpiry: usedBeforeExpiryProgress,
      BadgeType.cookedFromPantry: cookedFromPantryProgress,
      BadgeType.savingsMilestone: savingsProgress,
      BadgeType.environmentalImpact: impactProgress,
    };
  }

  int _countConsumedBeforeExpiry(List<Item> items, DateTime now) {
    final thirtyDaysAgo = now.subtract(
      const Duration(days: BadgeRequirements.usedBeforeExpiryLookbackDays),
    );

    return items.where((item) {
      final isConsumed = item.status == ItemStatus.consumed;
      final hasExpiry = item.expiryDate != null;
      final isWithin30Days = item.updatedAt.isAfter(thirtyDaysAgo);
      final wasConsumedBeforeExpiry =
          hasExpiry && item.expiryDate!.isAfter(now);

      return isConsumed && isWithin30Days && wasConsumedBeforeExpiry;
    }).length;
  }

  int _countPantryConsumed(List<Item> items, DateTime now) {
    final thirtyDaysAgo = now.subtract(
      const Duration(days: BadgeRequirements.cookedFromPantryLookbackDays),
    );

    return items.where((item) {
      final isPantryCategory =
          item.category == ItemCategory.pantry ||
          item.category == ItemCategory.grains;
      final isConsumed = item.status == ItemStatus.consumed;
      final isWithin30Days = item.updatedAt.isAfter(thirtyDaysAgo);

      return isPantryCategory && isConsumed && isWithin30Days;
    }).length;
  }

  BadgeProgress _buildBadgeProgress({
    required BadgeType type,
    required int current,
    required int required,
  }) {
    final progress = (current / required).clamp(0, 1).toDouble();
    return BadgeProgress(
      badgeType: type,
      currentProgress: current,
      requiredProgress: required,
      progressPercentage: progress,
      isEarned: current >= required,
    );
  }

  TelemetryAggregates _aggregateTelemetry(
    List<Map<String, dynamic>> telemetryEvents,
  ) {
    if (telemetryEvents.isEmpty) return TelemetryAggregates.empty();

    final eventCounts = <String, int>{};
    final itemAddedBySource = <String, int>{};
    final itemAddedByCategory = <String, int>{};
    final itemWastedByReason = <String, int>{};
    final itemWastedByCategory = <String, int>{};
    final reminderOpenedByCategory = <String, int>{};
    final inventoryViewedBySort = <String, int>{};
    final tabSwitchedByTab = <String, int>{};
    final screenViewedByScreen = <String, int>{};
    final filtersAppliedByCategory = <String, int>{};

    for (final event in telemetryEvents) {
      final name = event['name'] as String?;
      if (name == null) continue;
      eventCounts[name] = (eventCounts[name] ?? 0) + 1;

      final props =
          (event['properties'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};

      switch (name) {
        case 'item_added':
          final source =
              (props['source'] ?? props['entry_method'])?.toString() ??
              'unknown';
          _increment(itemAddedBySource, source);

          final category = props['category']?.toString();
          if (category != null) _increment(itemAddedByCategory, category);
          break;
        case 'item_wasted':
        case 'item_marked_wasted':
          final reason = (props['waste_reason'] ?? props['reason'])?.toString();
          if (reason != null) _increment(itemWastedByReason, reason);

          final category = props['category']?.toString();
          if (category != null) _increment(itemWastedByCategory, category);
          break;
        case 'reminder_opened':
          final category = (props['item_category'] ?? props['category'])
              ?.toString();
          if (category != null) _increment(reminderOpenedByCategory, category);
          break;
        case 'inventory_viewed':
          final sortBy = props['sort_by']?.toString() ?? 'default';
          _increment(inventoryViewedBySort, sortBy);
          break;
        case 'tab_switched':
          final tab = props['tab_name']?.toString() ?? 'unknown';
          _increment(tabSwitchedByTab, tab);
          break;
        case 'screen_viewed':
          final screen = props['screen_name']?.toString() ?? 'unknown';
          _increment(screenViewedByScreen, screen);
          break;
        case 'filters_applied':
          final category = props['category']?.toString() ?? 'all';
          _increment(filtersAppliedByCategory, category);
          break;
      }
    }

    return TelemetryAggregates(
      eventCounts: eventCounts,
      itemAddedBySource: itemAddedBySource,
      itemAddedByCategory: itemAddedByCategory,
      itemWastedByReason: itemWastedByReason,
      itemWastedByCategory: itemWastedByCategory,
      reminderOpenedByCategory: reminderOpenedByCategory,
      inventoryViewedBySort: inventoryViewedBySort,
      tabSwitchedByTab: tabSwitchedByTab,
      screenViewedByScreen: screenViewedByScreen,
      filtersAppliedByCategory: filtersAppliedByCategory,
    );
  }

  int? _daysUntilExpiry(Item item, DateTime now) {
    if (item.expiryDate == null) return null;
    final today = DateTime(now.year, now.month, now.day);
    final expiryDate = DateTime(
      item.expiryDate!.year,
      item.expiryDate!.month,
      item.expiryDate!.day,
    );
    return expiryDate.difference(today).inDays;
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _increment(Map<String, int> target, String key) {
    target[key] = (target[key] ?? 0) + 1;
  }
}

class _Totals {
  final int totalItems;
  final int availableItems;
  final int consumedItems;
  final int wastedItems;

  const _Totals({
    required this.totalItems,
    required this.availableItems,
    required this.consumedItems,
    required this.wastedItems,
  });
}

class _ExpiryStats {
  final int expiringTodayCount;
  final int expiringThisWeekCount;
  final int expiringSoonCount;
  final int expiredCount;
  final int noExpiryCount;

  const _ExpiryStats({
    required this.expiringTodayCount,
    required this.expiringThisWeekCount,
    required this.expiringSoonCount,
    required this.expiredCount,
    required this.noExpiryCount,
  });
}

class _ValueStats {
  final double totalValue;
  final double consumedValue;
  final double wastedValue;
  final double savedValue;

  const _ValueStats({
    required this.totalValue,
    required this.consumedValue,
    required this.wastedValue,
    required this.savedValue,
  });
}

class _RecencyStats {
  final int addedLast7Days;
  final int addedLast30Days;
  final int updatedLast7Days;
  final int updatedLast30Days;

  const _RecencyStats({
    required this.addedLast7Days,
    required this.addedLast30Days,
    required this.updatedLast7Days,
    required this.updatedLast30Days,
  });
}
