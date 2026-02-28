import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:zerospoils/presentation/screens/item_detail_screen.dart';
import 'package:zerospoils/domain/models/item_model.dart';
import 'package:zerospoils/presentation/di/repository_providers.dart';
import 'package:zerospoils/presentation/di/service_locator.dart' as sl;
import 'package:zerospoils/data/repositories/item_repository_base.dart';
import 'package:zerospoils/core/notifications/reminder_attribution_store.dart';

class MockTelemetryClient extends Mock implements sl.TelemetryClient {
  int enqueueCallCount = 0;
  Map<String, dynamic>? lastEvent;
  @override
  void enqueue(Map<String, dynamic> event) {
    enqueueCallCount++;
    lastEvent = event;
  }
}

class MockItemRepository extends Mock implements ItemRepositoryBase {
  @override
  Future<void> init() async {}
  Item? testItem;
  @override
  Future<Item?> getItem(String id) async {
    return testItem;
  }

  int saveItemCallCount = 0;
  Item? lastSavedItem;
  bool shouldThrow = false;
  @override
  Future<void> saveItem(Item item) async {
    saveItemCallCount++;
    lastSavedItem = item;
    if (shouldThrow) throw Exception('fail');
  }

  // ...existing code...
}

void main() {
  group('ItemDetailScreen - Mark as Wasted', () {
    late MockItemRepository mockRepo;
    late MockTelemetryClient mockTelemetry;
    late Item testItem;

    setUp(() {
      mockRepo = MockItemRepository();
      mockTelemetry = MockTelemetryClient();
      ReminderAttributionStore().clear();
      testItem = Item(
        id: 'item-1',
        name: 'Milk',
        status: ItemStatus.available,
        category: ItemCategory.dairy,
        location: StorageLocation.fridge,
        expiryDate: DateTime.now().add(const Duration(days: 2)),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
    });

    testWidgets('saves item with wasted status and emits telemetry', (
      tester,
    ) async {
      mockRepo.testItem = testItem;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            itemRepositoryProvider.overrideWithValue(mockRepo),
            sl.telemetryClientProvider.overrideWithValue(mockTelemetry),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) =>
                      ItemDetailScreen(itemId: 'item-1'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find and tap any ElevatedButton (the mark as wasted action button)
      final wastedButton = find.byType(ElevatedButton).at(1); // Second button
      await tester.ensureVisible(wastedButton);
      await tester.tap(wastedButton);
      await tester.pumpAndSettle();

      // Find and interact with waste reason radio button
      final reasonTile = find.byType(RadioListTile<WasteReason>).first;
      await tester.tap(reasonTile);
      await tester.pump();

      // Find and tap the confirm button
      final confirmBtn = find.byType(TextButton).last;
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Verify actions: saveItem called with wasted status
      expect(mockRepo.saveItemCallCount, 1);
      expect(mockRepo.lastSavedItem?.status, ItemStatus.wasted);

      // Verify telemetry event was emitted
      expect(mockTelemetry.enqueueCallCount, greaterThan(0));
      expect(mockTelemetry.lastEvent?['name'], 'item_marked_wasted');
    });

    testWidgets('adds reminder source when opened from reminder', (
      tester,
    ) async {
      mockRepo.testItem = testItem;

      ReminderAttributionStore().setContext(
        ReminderAttribution(
          itemId: 'item-1',
          leadTimeDays: 1,
          openedAt: DateTime(2026, 1, 1, 9),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            itemRepositoryProvider.overrideWithValue(mockRepo),
            sl.telemetryClientProvider.overrideWithValue(mockTelemetry),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) =>
                      ItemDetailScreen(itemId: 'item-1'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final wastedButton = find.byType(ElevatedButton).at(1);
      await tester.ensureVisible(wastedButton);
      await tester.tap(wastedButton);
      await tester.pumpAndSettle();

      final reasonTile = find.byType(RadioListTile<WasteReason>).first;
      await tester.tap(reasonTile);
      await tester.pump();

      final confirmBtn = find.byType(TextButton).last;
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(mockTelemetry.lastEvent?['name'], 'item_marked_wasted');
      expect(mockTelemetry.lastEvent?['properties']['source'], 'reminder');
    });

    testWidgets('handles save failure gracefully', (tester) async {
      mockRepo.testItem = testItem;
      mockRepo.shouldThrow = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            itemRepositoryProvider.overrideWithValue(mockRepo),
            sl.telemetryClientProvider.overrideWithValue(mockTelemetry),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) =>
                      ItemDetailScreen(itemId: 'item-1'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap mark as wasted button
      final wastedButton = find.byType(ElevatedButton).at(1);
      await tester.ensureVisible(wastedButton);
      await tester.tap(wastedButton);
      await tester.pumpAndSettle();

      // Select a waste reason
      final reasonTile = find.byType(RadioListTile<WasteReason>).first;
      await tester.tap(reasonTile);
      await tester.pump();

      // Tap confirm
      final confirmBtn = find.byType(TextButton).last;
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Verify: snackbar appears on error
      expect(find.byType(SnackBar), findsOneWidget);

      // Verify: save was attempted even though it failed
      expect(mockRepo.saveItemCallCount, 1);
    });

    testWidgets('does not throw after confirming waste dialog', (tester) async {
      mockRepo.testItem = testItem;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            itemRepositoryProvider.overrideWithValue(mockRepo),
            sl.telemetryClientProvider.overrideWithValue(mockTelemetry),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) =>
                      ItemDetailScreen(itemId: 'item-1'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final wastedButton = find.byType(ElevatedButton).at(1);
      await tester.ensureVisible(wastedButton);
      await tester.tap(wastedButton);
      await tester.pumpAndSettle();

      final reasonTile = find.byType(RadioListTile<WasteReason>).first;
      await tester.tap(reasonTile);
      await tester.pump();

      final confirmBtn = find.byType(TextButton).last;
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('partial waste keeps item available with reduced quantity', (
      tester,
    ) async {
      testItem = testItem.copyWith(quantity: 2);
      mockRepo.testItem = testItem;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            itemRepositoryProvider.overrideWithValue(mockRepo),
            sl.telemetryClientProvider.overrideWithValue(mockTelemetry),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) =>
                      ItemDetailScreen(itemId: 'item-1'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final wastedButton = find.byType(ElevatedButton).at(1);
      await tester.ensureVisible(wastedButton);
      await tester.tap(wastedButton);
      await tester.pumpAndSettle();

      final reasonTile = find.byType(RadioListTile<WasteReason>).first;
      await tester.tap(reasonTile);
      await tester.pump();

      final slider = find.byType(Slider);
      await tester.ensureVisible(slider);
      final sliderRect = tester.getRect(slider);
      await tester.tapAt(
        Offset(sliderRect.left + sliderRect.width * 0.6, sliderRect.center.dy),
      );
      await tester.pump();

      final confirmBtn = find.byType(TextButton).last;
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(mockRepo.lastSavedItem?.status, ItemStatus.available);
      expect(mockRepo.lastSavedItem?.quantity, 1);
      expect(mockRepo.lastSavedItem?.wastePercentage, isNotNull);
      expect(mockRepo.lastSavedItem?.wastePercentage, lessThan(100));
    });
  });
}
