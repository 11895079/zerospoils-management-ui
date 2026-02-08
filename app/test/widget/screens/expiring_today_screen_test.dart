import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zerospoils/data/repositories/item_repository_base.dart';
import 'package:zerospoils/domain/models/item_model.dart';
import 'package:zerospoils/presentation/di/repository_providers.dart';
import 'package:zerospoils/presentation/di/service_locator.dart'
    show TelemetryClient, telemetryClientProvider;
import 'package:zerospoils/presentation/screens/expiring_today_screen.dart';

class TestTelemetryClient extends TelemetryClient {
  final List<Map<String, dynamic>> recorded = [];

  @override
  void enqueue(Map<String, dynamic> event) {
    recorded.add(event);
  }
}

class MockItemRepository implements ItemRepositoryBase {
  MockItemRepository(this.items);

  List<Item> items;
  int initCallCount = 0;
  int getAllItemsCallCount = 0;

  @override
  Future<void> init() async {
    initCallCount++;
  }

  @override
  Future<List<Item>> getAllItems() async {
    getAllItemsCallCount++;
    return items;
  }

  @override
  Future<Item?> getItem(String id) async =>
      items.firstWhere((item) => item.id == id);

  @override
  Future<void> saveItem(Item item) async {
    items = [...items.where((existing) => existing.id != item.id), item];
  }

  @override
  Future<void> deleteItem(String id) async {
    items = items.where((item) => item.id != id).toList();
  }

  @override
  Future<void> clear() async {
    items = [];
  }

  @override
  Future<void> close() async {}
}

Item buildItem({
  required String id,
  DateTime? expiryDate,
  DateTime? createdAt,
}) {
  final now = DateTime.now();
  return Item(
    id: id,
    name: 'Item $id',
    category: ItemCategory.pantry,
    location: StorageLocation.pantry,
    expiryDate: expiryDate,
    createdAt: createdAt ?? now.subtract(const Duration(days: 1)),
    updatedAt: now,
  );
}

GoRouter buildRouter(Widget child) {
  return GoRouter(
    initialLocation: '/expiring',
    routes: [
      GoRoute(
        path: '/',
        name: 'inventory',
        builder: (context, state) =>
            const Scaffold(body: SizedBox(key: ValueKey('inventory_root'))),
      ),
      GoRoute(
        path: '/expiring',
        name: 'expiring',
        builder: (context, state) => child,
      ),
      GoRoute(
        path: '/item/:id',
        name: 'item-detail',
        builder: (context, state) => Scaffold(
          body: SizedBox(
            key: ValueKey('item_detail_${state.pathParameters['id']}'),
          ),
        ),
      ),
    ],
  );
}

void main() {
  group('ExpiringTodayScreen', () {
    testWidgets('renders empty state when no items exist', (
      WidgetTester tester,
    ) async {
      final repository = MockItemRepository([]);
      final telemetry = TestTelemetryClient();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            itemRepositoryProvider.overrideWithValue(repository),
            telemetryClientProvider.overrideWithValue(telemetry),
          ],
          child: MaterialApp.router(
            routerConfig: buildRouter(const ExpiringTodayScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('expiring_empty_state')),
        findsOneWidget,
      );
    });

    testWidgets('renders empty state when no items are expiring soon', (
      WidgetTester tester,
    ) async {
      final futureItem = buildItem(
        id: 'future-1',
        expiryDate: DateTime.now().add(const Duration(days: 30)),
      );
      final repository = MockItemRepository([futureItem]);
      final telemetry = TestTelemetryClient();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            itemRepositoryProvider.overrideWithValue(repository),
            telemetryClientProvider.overrideWithValue(telemetry),
          ],
          child: MaterialApp.router(
            routerConfig: buildRouter(const ExpiringTodayScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('expiring_empty_state')),
        findsOneWidget,
      );
    });

    testWidgets('renders buckets for today, this week, and expired', (
      WidgetTester tester,
    ) async {
      final now = DateTime.now();
      final items = [
        buildItem(id: 'today', expiryDate: now),
        buildItem(id: 'week', expiryDate: now.add(const Duration(days: 3))),
        buildItem(
          id: 'expired',
          expiryDate: now.subtract(const Duration(days: 1)),
        ),
      ];
      final repository = MockItemRepository(items);
      final telemetry = TestTelemetryClient();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            itemRepositoryProvider.overrideWithValue(repository),
            telemetryClientProvider.overrideWithValue(telemetry),
          ],
          child: MaterialApp.router(
            routerConfig: buildRouter(const ExpiringTodayScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('expiring_section_today')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('expiring_section_thisWeek')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('expiring_section_expired')),
        findsOneWidget,
      );
    });

    testWidgets('renders sections in expected order', (
      WidgetTester tester,
    ) async {
      final now = DateTime.now();
      final items = [
        buildItem(id: 'today', expiryDate: now),
        buildItem(id: 'week', expiryDate: now.add(const Duration(days: 3))),
        buildItem(
          id: 'expired',
          expiryDate: now.subtract(const Duration(days: 1)),
        ),
      ];
      final repository = MockItemRepository(items);
      final telemetry = TestTelemetryClient();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            itemRepositoryProvider.overrideWithValue(repository),
            telemetryClientProvider.overrideWithValue(telemetry),
          ],
          child: MaterialApp.router(
            routerConfig: buildRouter(const ExpiringTodayScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final todayDy = tester
          .getTopLeft(find.byKey(const ValueKey('expiring_section_today')))
          .dy;
      final weekDy = tester
          .getTopLeft(find.byKey(const ValueKey('expiring_section_thisWeek')))
          .dy;
      final expiredDy = tester
          .getTopLeft(find.byKey(const ValueKey('expiring_section_expired')))
          .dy;

      expect(todayDy, lessThan(weekDy));
      expect(weekDy, lessThan(expiredDy));
    });

    testWidgets('tapping item navigates to Item Detail', (
      WidgetTester tester,
    ) async {
      final now = DateTime.now();
      final items = [buildItem(id: 'tap-1', expiryDate: now)];
      final repository = MockItemRepository(items);
      final telemetry = TestTelemetryClient();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            itemRepositoryProvider.overrideWithValue(repository),
            telemetryClientProvider.overrideWithValue(telemetry),
          ],
          child: MaterialApp.router(
            routerConfig: buildRouter(const ExpiringTodayScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('expiring_item_tap-1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('item_detail_tap-1')), findsOneWidget);
    });

    testWidgets('emits telemetry on screen view and item tap', (
      WidgetTester tester,
    ) async {
      final now = DateTime.now();
      final items = [buildItem(id: 'telemetry-1', expiryDate: now)];
      final repository = MockItemRepository(items);
      final telemetry = TestTelemetryClient();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            itemRepositoryProvider.overrideWithValue(repository),
            telemetryClientProvider.overrideWithValue(telemetry),
          ],
          child: MaterialApp.router(
            routerConfig: buildRouter(const ExpiringTodayScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        telemetry.recorded.any(
          (event) =>
              event['name'] == 'screen_viewed' &&
              event['properties']?['screen_name'] == 'expiring_soon',
        ),
        isTrue,
      );

      await tester.tap(find.byKey(const ValueKey('expiring_item_telemetry-1')));
      await tester.pumpAndSettle();

      expect(
        telemetry.recorded.any(
          (event) => event['name'] == 'item_tapped_from_expiring_soon',
        ),
        isTrue,
      );
    });

    testWidgets('pull-to-refresh triggers repository reload', (
      WidgetTester tester,
    ) async {
      final now = DateTime.now();
      final items = [buildItem(id: 'refresh-1', expiryDate: now)];
      final repository = MockItemRepository(items);
      final telemetry = TestTelemetryClient();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            itemRepositoryProvider.overrideWithValue(repository),
            telemetryClientProvider.overrideWithValue(telemetry),
          ],
          child: MaterialApp.router(
            routerConfig: buildRouter(const ExpiringTodayScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final before = repository.getAllItemsCallCount;
      await tester.drag(
        find.byKey(const ValueKey('expiring_refresh_indicator')),
        const Offset(0, 300),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(repository.getAllItemsCallCount, greaterThan(before));
      expect(
        telemetry.recorded.any((event) => event['name'] == 'pull_to_refresh'),
        isTrue,
      );
    });

    testWidgets('empty state CTA navigates to inventory', (
      WidgetTester tester,
    ) async {
      final repository = MockItemRepository([]);
      final telemetry = TestTelemetryClient();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            itemRepositoryProvider.overrideWithValue(repository),
            telemetryClientProvider.overrideWithValue(telemetry),
          ],
          child: MaterialApp.router(
            routerConfig: buildRouter(const ExpiringTodayScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('expiring_review_inventory_button')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('inventory_root')), findsOneWidget);
    });
  });
}
