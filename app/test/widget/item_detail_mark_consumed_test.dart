import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerospoils/domain/models/item_model.dart';
import 'package:zerospoils/presentation/di/repository_providers.dart';
import 'package:zerospoils/presentation/di/service_locator.dart' as sl;
import 'package:zerospoils/presentation/screens/item_detail_screen.dart';
import 'package:zerospoils/data/repositories/item_repository_base.dart';
import 'package:zerospoils/core/notifications/reminder_attribution_store.dart';

import '../helpers/telemetry_test_helpers.dart';

class MockTelemetryClient extends Mock implements sl.TelemetryClient {
  int enqueueCallCount = 0;
  Map<String, dynamic>? lastEvent;
  @override
  final List<Map<String, dynamic>> events = [];
  @override
  void enqueue(Map<String, dynamic> event) {
    enqueueCallCount++;
    lastEvent = event;
    events.add(event);
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

  @override
  Future<List<Item>> getAllItems() async => [];
  @override
  Future<void> deleteItem(String id) async {}
  @override
  Future<void> clear() async {}
  Future<void> deleteAllItems() async {}
  Future<List<Item>> getItemsByCategory(ItemCategory category) async => [];
  Future<List<Item>> getItemsByLocation(StorageLocation location) async => [];
  Future<List<Item>> getItemsExpiringSoon({int days = 3}) async => [];
}

void main() {
  group('ItemDetailScreen - Partial Consumption', () {
    late MockItemRepository mockRepo;
    late MockTelemetryClient mockTelemetry;

    setUp(() {
      mockRepo = MockItemRepository();
      mockTelemetry = MockTelemetryClient();
      SharedPreferences.setMockInitialValues({});
      ReminderAttributionStore().clear();
    });

    testWidgets('reduces quantity when partially consumed', (tester) async {
      final testItem = Item(
        id: 'item-1',
        name: 'Apples',
        status: ItemStatus.available,
        category: ItemCategory.produce,
        location: StorageLocation.fridge,
        quantity: 3,
        expiryDate: DateTime.now().add(const Duration(days: 2)),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
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

      final consumeButton = find.byKey(const Key('item_mark_consumed_button'));
      await tester.ensureVisible(consumeButton);
      await tester.tap(consumeButton);
      await tester.pumpAndSettle();

      final slider = find.byKey(const Key('consume_percentage_slider'));
      final sliderBox = tester.renderObject<RenderBox>(slider);
      final sliderOffset = sliderBox.localToGlobal(
        Offset(sliderBox.size.width * 0.5, sliderBox.size.height / 2),
      );
      await tester.tapAt(sliderOffset);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('consume_confirm_button')));
      await tester.pumpAndSettle();

      expect(mockRepo.saveItemCallCount, 1);
      expect(mockRepo.lastSavedItem?.status, ItemStatus.available);
      expect(mockRepo.lastSavedItem?.quantity, 1);
      final consumedEvent = await waitForTelemetryEvent(
        mockTelemetry.events,
        'item_partially_consumed',
        tester,
      );
      expect(consumedEvent['name'], 'item_partially_consumed');
      final mascotEvent = await waitForTelemetryEvent(
        mockTelemetry.events,
        'mascot_shown',
        tester,
      );
      final mascotProps = mascotEvent['properties'] as Map<String, dynamic>;
      expect(mascotProps['messageType'], 'consumed');
    });

    testWidgets('marks consumed when all quantity is used', (tester) async {
      final testItem = Item(
        id: 'item-2',
        name: 'Yogurt',
        status: ItemStatus.available,
        category: ItemCategory.dairy,
        location: StorageLocation.fridge,
        quantity: 2,
        expiryDate: DateTime.now().add(const Duration(days: 2)),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
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
                      ItemDetailScreen(itemId: 'item-2'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final consumeButton = find.byKey(const Key('item_mark_consumed_button'));
      await tester.ensureVisible(consumeButton);
      await tester.tap(consumeButton);
      await tester.pumpAndSettle();

      // Default 100% consumption is already selected.

      await tester.tap(find.byKey(const Key('consume_confirm_button')));
      await tester.pumpAndSettle();

      expect(mockRepo.saveItemCallCount, 1);
      expect(mockRepo.lastSavedItem?.status, ItemStatus.consumed);
      expect(mockRepo.lastSavedItem?.quantity, 0);
      final markedUsedEvent = await waitForTelemetryEvent(
        mockTelemetry.events,
        'item_marked_used',
        tester,
      );
      expect(markedUsedEvent['name'], 'item_marked_used');
      final mascotEvent = await waitForTelemetryEvent(
        mockTelemetry.events,
        'mascot_shown',
        tester,
      );
      final mascotProps = mascotEvent['properties'] as Map<String, dynamic>;
      expect(mascotProps['messageType'], anyOf('consumed', 'quickSave'));
    });

    testWidgets('adds reminder source when opened from reminder', (
      tester,
    ) async {
      final testItem = Item(
        id: 'item-3',
        name: 'Eggs',
        status: ItemStatus.available,
        category: ItemCategory.dairy,
        location: StorageLocation.fridge,
        quantity: 1,
        expiryDate: DateTime.now().add(const Duration(days: 2)),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      mockRepo.testItem = testItem;

      ReminderAttributionStore().setContext(
        ReminderAttribution(
          itemId: 'item-3',
          leadTimeDays: 3,
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
                      ItemDetailScreen(itemId: 'item-3'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final consumeButton = find.byKey(const Key('item_mark_consumed_button'));
      await tester.ensureVisible(consumeButton);
      await tester.tap(consumeButton);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('consume_confirm_button')));
      await tester.pumpAndSettle();

      final markedUsedEvent = await waitForTelemetryEvent(
        mockTelemetry.events,
        'item_marked_used',
        tester,
      );
      final markedUsedProps =
          markedUsedEvent['properties'] as Map<String, dynamic>;
      expect(markedUsedEvent['name'], 'item_marked_used');
      expect(markedUsedProps['source'], 'reminder');
      final mascotEvent = await waitForTelemetryEvent(
        mockTelemetry.events,
        'mascot_shown',
        tester,
      );
      final mascotProps = mascotEvent['properties'] as Map<String, dynamic>;
      expect(mascotProps['messageType'], anyOf('consumed', 'quickSave'));
    });
  });
}
