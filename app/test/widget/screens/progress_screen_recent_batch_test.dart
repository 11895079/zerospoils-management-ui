import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerospoils/domain/models/item_model.dart';
import 'package:zerospoils/domain/models/receipt_batch.dart';
import 'package:zerospoils/data/repositories/item_repository_base.dart';
import 'package:zerospoils/data/repositories/receipt_batch_repository.dart';
import 'package:zerospoils/domain/models/badge_model.dart';
import 'package:zerospoils/domain/repositories/progress_stats_service.dart';
import 'package:zerospoils/presentation/di/repository_providers.dart';
import 'package:zerospoils/presentation/screens/progress_screen.dart';
import 'package:zerospoils/presentation/themes/app_theme.dart';
import '../../helpers/telemetry_test_helpers.dart';

class MockItemRepository implements ItemRepositoryBase {
  final List<Item> _items;
  MockItemRepository(this._items);

  @override
  Future<void> init() async {}

  @override
  Future<void> clear() async {}

  @override
  Future<void> close() async {}

  @override
  Future<void> deleteItem(String id) async {}

  @override
  Future<List<Item>> getAllItems() async => _items;

  @override
  Future<Item?> getItem(String id) async {
    return _items.firstWhere((item) => item.id == id);
  }

  @override
  Future<void> saveItem(Item item) async {}
}

class MockReceiptBatchRepository implements ReceiptBatchRepository {
  final List<ReceiptBatch> _batches;
  MockReceiptBatchRepository(this._batches);

  @override
  Future<void> init() async {}

  @override
  Future<void> saveBatch(ReceiptBatch batch) async {}

  @override
  Future<List<ReceiptBatch>> getAllBatches() async => _batches;

  @override
  Future<ReceiptBatch?> getBatch(String id) async =>
      _batches.firstWhere((b) => b.id == id);
}

void main() {
  testWidgets('Progress shows recent receipt batch stats', (
    WidgetTester tester,
  ) async {
    final batch = ReceiptBatch(
      id: 'batch-1',
      createdAt: DateTime(2026, 2, 9),
      source: ReceiptBatchSource.inventory,
      items: [
        ReceiptBatchItem(
          id: 'r1',
          name: 'Milk',
          price: 4.99,
          quantity: 1,
          destination: ReceiptBatchDestination.inventory,
          inventoryItemId: 'i1',
        ),
      ],
    );

    final items = [
      Item(
        id: 'i1',
        name: 'Milk',
        category: ItemCategory.dairy,
        location: StorageLocation.fridge,
        purchasePrice: 4.99,
        status: ItemStatus.available,
        createdAt: DateTime(2026, 2, 9),
        updatedAt: DateTime(2026, 2, 9),
      ),
    ];

    final fakeStats = ProgressStats(
      totalItems: 1,
      availableItems: 1,
      consumedItems: 0,
      wastedItems: 0,
      categoryCounts: {ItemCategory.dairy: 1},
      locationCounts: {StorageLocation.fridge: 1},
      typeCounts: {ItemType.raw: 1},
      expiringTodayCount: 0,
      expiringThisWeekCount: 0,
      expiringSoonCount: 0,
      expiredCount: 0,
      noExpiryCount: 1,
      totalValue: 4.99,
      consumedValue: 0,
      wastedValue: 0,
      savedValue: 0,
      addedLast7Days: 1,
      addedLast30Days: 1,
      updatedLast7Days: 0,
      updatedLast30Days: 0,
      noWasteStreak: StreakData(
        badgeType: BadgeType.noWasteWeek,
        streakDays: 1,
        streakStartDate: DateTime(2026, 2, 8),
        lastActivityDate: DateTime(2026, 2, 9),
        isActive: false,
      ),
      badgeProgress: const {},
      telemetry: TelemetryAggregates.empty(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemRepositoryProvider.overrideWithValue(MockItemRepository(items)),
          receiptBatchRepositoryProvider.overrideWithValue(
            MockReceiptBatchRepository([batch]),
          ),
          progressStatsProvider.overrideWith((ref) => Stream.value(fakeStats)),
          zestoTestOverride(),
        ],
        child: const MaterialApp(home: ProgressScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('screen_progress')), findsOneWidget);
  });

  testWidgets('Progress uses dark theme surfaces in dark mode', (
    WidgetTester tester,
  ) async {
    final fakeStats = ProgressStats(
      totalItems: 1,
      availableItems: 1,
      consumedItems: 0,
      wastedItems: 0,
      categoryCounts: {ItemCategory.dairy: 1},
      locationCounts: {StorageLocation.fridge: 1},
      typeCounts: {ItemType.raw: 1},
      expiringTodayCount: 0,
      expiringThisWeekCount: 0,
      expiringSoonCount: 0,
      expiredCount: 0,
      noExpiryCount: 1,
      totalValue: 4.99,
      consumedValue: 0,
      wastedValue: 0,
      savedValue: 0,
      addedLast7Days: 1,
      addedLast30Days: 1,
      updatedLast7Days: 0,
      updatedLast30Days: 0,
      noWasteStreak: StreakData(
        badgeType: BadgeType.noWasteWeek,
        streakDays: 1,
        streakStartDate: DateTime(2026, 2, 8),
        lastActivityDate: DateTime(2026, 2, 9),
        isActive: false,
      ),
      badgeProgress: const {},
      telemetry: TelemetryAggregates.empty(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemRepositoryProvider.overrideWithValue(
            MockItemRepository(const []),
          ),
          receiptBatchRepositoryProvider.overrideWithValue(
            MockReceiptBatchRepository(const []),
          ),
          progressStatsProvider.overrideWith((ref) => Stream.value(fakeStats)),
          zestoTestOverride(),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const ProgressScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    final theme = Theme.of(tester.element(find.byType(ProgressScreen)));

    expect(scaffold.backgroundColor, theme.scaffoldBackgroundColor);
    expect(
      appBar.backgroundColor ?? theme.appBarTheme.backgroundColor,
      theme.appBarTheme.backgroundColor,
    );
  });

  testWidgets('Progress section headers use dark theme text colors', (
    WidgetTester tester,
  ) async {
    final fakeStats = ProgressStats(
      totalItems: 1,
      availableItems: 1,
      consumedItems: 0,
      wastedItems: 0,
      categoryCounts: {ItemCategory.dairy: 1},
      locationCounts: {StorageLocation.fridge: 1},
      typeCounts: {ItemType.raw: 1},
      expiringTodayCount: 0,
      expiringThisWeekCount: 0,
      expiringSoonCount: 0,
      expiredCount: 0,
      noExpiryCount: 1,
      totalValue: 4.99,
      consumedValue: 0,
      wastedValue: 0,
      savedValue: 0,
      addedLast7Days: 1,
      addedLast30Days: 1,
      updatedLast7Days: 0,
      updatedLast30Days: 0,
      noWasteStreak: StreakData(
        badgeType: BadgeType.noWasteWeek,
        streakDays: 1,
        streakStartDate: DateTime(2026, 2, 8),
        lastActivityDate: DateTime(2026, 2, 9),
        isActive: false,
      ),
      badgeProgress: const {},
      telemetry: TelemetryAggregates.empty(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemRepositoryProvider.overrideWithValue(
            MockItemRepository(const []),
          ),
          receiptBatchRepositoryProvider.overrideWithValue(
            MockReceiptBatchRepository(const []),
          ),
          progressStatsProvider.overrideWith((ref) => Stream.value(fakeStats)),
          zestoTestOverride(),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const ProgressScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final heading = tester.widget<Text>(
      find.byKey(const Key('progress_section_title_summary')),
    );
    final theme = Theme.of(tester.element(find.byType(ProgressScreen)));

    expect(heading.style?.color, theme.textTheme.headlineMedium?.color);
  });

  testWidgets('Progress summary tiles update when stats stream emits', (
    WidgetTester tester,
  ) async {
    ProgressStats buildStats({required int totalItems}) {
      return ProgressStats(
        totalItems: totalItems,
        availableItems: totalItems,
        consumedItems: 0,
        wastedItems: 0,
        categoryCounts: {ItemCategory.dairy: totalItems},
        locationCounts: {StorageLocation.fridge: totalItems},
        typeCounts: {ItemType.raw: totalItems},
        expiringTodayCount: 0,
        expiringThisWeekCount: 0,
        expiringSoonCount: 0,
        expiredCount: 0,
        noExpiryCount: totalItems,
        totalValue: 4.99 * totalItems,
        consumedValue: 0,
        wastedValue: 0,
        savedValue: 0,
        addedLast7Days: totalItems,
        addedLast30Days: totalItems,
        updatedLast7Days: 0,
        updatedLast30Days: 0,
        noWasteStreak: StreakData(
          badgeType: BadgeType.noWasteWeek,
          streakDays: 1,
          streakStartDate: DateTime(2026, 2, 8),
          lastActivityDate: DateTime(2026, 2, 9),
          isActive: false,
        ),
        badgeProgress: const {},
        telemetry: TelemetryAggregates.empty(),
      );
    }

    final controller = StreamController<ProgressStats>();
    addTearDown(controller.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemRepositoryProvider.overrideWithValue(
            MockItemRepository(const []),
          ),
          receiptBatchRepositoryProvider.overrideWithValue(
            MockReceiptBatchRepository(const []),
          ),
          progressStatsProvider.overrideWith((ref) => controller.stream),
          zestoTestOverride(),
        ],
        child: const MaterialApp(home: ProgressScreen()),
      ),
    );

    controller.add(buildStats(totalItems: 1));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const Key('progress_stat_card_total_items')),
        matching: find.byKey(const Key('progress_stat_value_total_items')),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const Key('progress_stat_value_total_items')),
          )
          .data,
      '1',
    );

    controller.add(buildStats(totalItems: 3));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<Text>(
            find.byKey(const Key('progress_stat_value_total_items')),
          )
          .data,
      '3',
    );
  });

  testWidgets('Progress remains visible across periodic refresh in demo mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [zestoTestOverride()],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const ProgressScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen_progress')), findsOneWidget);

    // Allow fallback polling stream to emit at least once.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('screen_progress')), findsOneWidget);
    expect(find.textContaining('Unable to load progress'), findsNothing);
  });
}
