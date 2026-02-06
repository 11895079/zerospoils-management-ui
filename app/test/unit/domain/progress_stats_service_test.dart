import 'package:flutter_test/flutter_test.dart';
import 'package:zerospoils/domain/models/item_model.dart';
import 'package:zerospoils/domain/models/badge_model.dart';
import 'package:zerospoils/domain/repositories/progress_stats_service.dart';
import 'package:zerospoils/domain/repositories/badge_service.dart';

void main() {
  group('ProgressStatsService', () {
    test('aggregates item stats, value stats, streak, and telemetry', () async {
      final now = DateTime(2026, 2, 6, 10);
      final items = <Item>[
        Item(
          id: '1',
          name: 'Milk',
          category: ItemCategory.dairy,
          location: StorageLocation.fridge,
          expiryDate: DateTime(2026, 2, 6),
          purchasePrice: 4.0,
          status: ItemStatus.available,
          createdAt: now.subtract(const Duration(days: 2)),
          updatedAt: now.subtract(const Duration(days: 2)),
        ),
        Item(
          id: '2',
          name: 'Chicken',
          category: ItemCategory.meat,
          location: StorageLocation.freezer,
          expiryDate: DateTime(2026, 2, 8),
          purchasePrice: 8.0,
          status: ItemStatus.available,
          createdAt: now.subtract(const Duration(days: 5)),
          updatedAt: now.subtract(const Duration(days: 5)),
        ),
        Item(
          id: '3',
          name: 'Rice',
          category: ItemCategory.pantry,
          location: StorageLocation.pantry,
          expiryDate: DateTime(2026, 2, 16),
          purchasePrice: 10.0,
          status: ItemStatus.consumed,
          createdAt: now.subtract(const Duration(days: 12)),
          updatedAt: now.subtract(const Duration(days: 1)),
        ),
        Item(
          id: '4',
          name: 'Spinach',
          category: ItemCategory.produce,
          location: StorageLocation.fridge,
          expiryDate: DateTime(2026, 2, 4),
          purchasePrice: 6.0,
          status: ItemStatus.wasted,
          wasteReason: WasteReason.spoiled,
          createdAt: now.subtract(const Duration(days: 7)),
          updatedAt: now.subtract(const Duration(days: 1)),
        ),
        Item(
          id: '5',
          name: 'Flour',
          category: ItemCategory.grains,
          location: StorageLocation.pantry,
          status: ItemStatus.available,
          createdAt: now.subtract(const Duration(days: 20)),
          updatedAt: now.subtract(const Duration(days: 20)),
        ),
      ];

      final telemetryEvents = [
        {
          'name': 'item_added',
          'properties': {
            'source': 'manual',
            'category': 'dairy',
            'has_expiry_date': true,
          },
        },
        {
          'name': 'item_added',
          'properties': {
            'entry_method': 'shopping_convert',
            'category': 'meat',
            'has_expiry': true,
          },
        },
        {
          'name': 'item_wasted',
          'properties': {
            'category': 'produce',
            'days_until_expiry': -2,
            'waste_reason': 'spoiled',
            'cost': 6.0,
          },
        },
        {
          'name': 'reminder_opened',
          'properties': {'item_category': 'dairy', 'days_until_expiry': 1},
        },
        {
          'name': 'inventory_viewed',
          'properties': {'filter_applied': true, 'sort_by': 'expiry'},
        },
        {
          'name': 'tab_switched',
          'properties': {'tab_name': 'progress'},
        },
        {
          'name': 'screen_viewed',
          'properties': {'screen_name': 'progress'},
        },
        {
          'name': 'filters_applied',
          'properties': {
            'category': 'dairy',
            'location': 'fridge',
            'expiringSoonOnly': true,
            'hideConsumed': true,
          },
        },
      ];

      final service = ProgressStatsService(badgeService: BadgeService());
      final stats = await service.build(
        items: items,
        telemetryEvents: telemetryEvents,
        now: now,
      );

      expect(stats.totalItems, 5);
      expect(stats.availableItems, 3);
      expect(stats.consumedItems, 1);
      expect(stats.wastedItems, 1);
      expect(stats.expiringTodayCount, 1);
      expect(stats.expiringThisWeekCount, 1);
      expect(stats.expiredCount, 1);
      expect(stats.expiringSoonCount, 2);
      expect(stats.noExpiryCount, 1);

      expect(stats.totalValue, 28.0);
      expect(stats.consumedValue, 10.0);
      expect(stats.wastedValue, 6.0);
      expect(stats.savedValue, 5.0);

      expect(stats.noWasteStreak.streakDays, 1);
      expect(stats.noWasteStreak.daysRemaining, 6);

      final savingsProgress = stats.badgeProgress[BadgeType.savingsMilestone]!;
      expect(savingsProgress.currentProgress, 5);

      expect(stats.telemetry.eventCounts['item_added'], 2);
      expect(stats.telemetry.eventCounts['item_wasted'], 1);
      expect(stats.telemetry.eventCounts['reminder_opened'], 1);
      expect(stats.telemetry.itemAddedBySource['manual'], 1);
      expect(stats.telemetry.itemAddedBySource['shopping_convert'], 1);
      expect(stats.telemetry.itemAddedByCategory['dairy'], 1);
      expect(stats.telemetry.itemAddedByCategory['meat'], 1);
      expect(stats.telemetry.itemWastedByReason['spoiled'], 1);
      expect(stats.telemetry.reminderOpenedByCategory['dairy'], 1);
      expect(stats.telemetry.tabSwitchedByTab['progress'], 1);
      expect(stats.telemetry.screenViewedByScreen['progress'], 1);
    });
  });
}
