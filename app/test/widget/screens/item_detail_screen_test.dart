// Widget test for ItemDetailScreen
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerospoils/presentation/screens/item_detail_screen.dart';
import 'package:zerospoils/domain/models/item_model.dart';
import 'package:zerospoils/data/repositories/hive_item_repository.dart';
import 'package:zerospoils/presentation/di/service_locator.dart'
    hide itemRepositoryProvider;
import 'package:zerospoils/presentation/di/repository_providers.dart';

/// Mock implementations
class MockItemRepository extends HiveItemRepository {
  final Map<String, Item> _items = {};
  bool _shouldThrowError = false;

  void setShouldThrowError(bool value) {
    _shouldThrowError = value;
  }

  void addMockItem(Item item) {
    _items[item.id] = item;
  }

  @override
  Future<void> init() async {
    // No-op for mock
  }

  @override
  Future<Item?> getItem(String id) async {
    if (_shouldThrowError) {
      throw Exception('Mock error');
    }
    return _items[id];
  }

  @override
  Future<void> saveItem(Item item) async {
    if (_shouldThrowError) {
      throw Exception('Mock error');
    }
    _items[item.id] = item;
  }
}

class MockTelemetryClient extends TelemetryClient {
  final List<Map<String, dynamic>> _events = [];

  @override
  List<Map<String, dynamic>> get events => _events;

  @override
  void enqueue(Map<String, dynamic> event) {
    _events.add(event);
  }
}

void main() {
  group('ItemDetailScreen', () {
    late MockItemRepository mockRepository;
    late MockTelemetryClient mockTelemetry;

    setUp(() {
      mockRepository = MockItemRepository();
      mockTelemetry = MockTelemetryClient();
    });

    Widget createTestWidget(String itemId) {
      return ProviderScope(
        overrides: [
          itemRepositoryProvider.overrideWithValue(mockRepository),
          telemetryClientProvider.overrideWithValue(mockTelemetry),
        ],
        child: MaterialApp(home: ItemDetailScreen(itemId: itemId)),
      );
    }

    testWidgets('shows loading indicator while fetching item', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget('item-1'));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays item details when loaded', (
      WidgetTester tester,
    ) async {
      final testItem = Item(
        id: 'item-1',
        name: 'Test Apple',
        category: ItemCategory.produce,
        type: ItemType.raw,
        location: StorageLocation.fridge,
        quantity: 5,
        unit: Unit.count,
        expiryDate: DateTime(2026, 2, 1),
        purchasePrice: 3.99,
        status: ItemStatus.available,
        createdAt: DateTime(2026, 1, 20),
        updatedAt: DateTime(2026, 1, 20),
      );
      mockRepository.addMockItem(testItem);

      await tester.pumpWidget(createTestWidget('item-1'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('item_detail_name')), findsOneWidget);
      expect(find.byKey(const Key('item_detail_category')), findsOneWidget);
      expect(find.byKey(const Key('item_detail_location')), findsOneWidget);
      expect(find.byKey(const Key('item_detail_quantity')), findsOneWidget);
      expect(find.byKey(const Key('item_detail_added')), findsOneWidget);
    });

    testWidgets('shows "Item not found" when item does not exist', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget('nonexistent'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('item_detail_not_found')), findsOneWidget);
      expect(find.byKey(const Key('item_detail_go_back')), findsOneWidget);
    });

    testWidgets('shows error message when loading fails', (
      WidgetTester tester,
    ) async {
      mockRepository.setShouldThrowError(true);

      await tester.pumpWidget(createTestWidget('item-1'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('item_detail_error_message')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('item_detail_retry_button')), findsOneWidget);
    });

    testWidgets('shows mark used and mark wasted buttons for available items', (
      WidgetTester tester,
    ) async {
      final testItem = Item(
        id: 'item-1',
        name: 'Test Item',
        category: ItemCategory.produce,
        location: StorageLocation.fridge,
        status: ItemStatus.available,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockRepository.addMockItem(testItem);

      await tester.pumpWidget(createTestWidget('item-1'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('item_edit_button')), findsOneWidget);
      expect(
        find.byKey(const Key('item_mark_consumed_button')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('item_mark_wasted_button')), findsOneWidget);
    });

    testWidgets('does not show action buttons for consumed items', (
      WidgetTester tester,
    ) async {
      final testItem = Item(
        id: 'item-1',
        name: 'Test Item',
        category: ItemCategory.produce,
        location: StorageLocation.fridge,
        status: ItemStatus.consumed,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockRepository.addMockItem(testItem);

      await tester.pumpWidget(createTestWidget('item-1'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('item_mark_consumed_button')), findsNothing);
      expect(find.byKey(const Key('item_mark_wasted_button')), findsNothing);
    });

    testWidgets('mark used dialog shows confirmation', (
      WidgetTester tester,
    ) async {
      final testItem = Item(
        id: 'item-1',
        name: 'Test Apple',
        category: ItemCategory.produce,
        location: StorageLocation.fridge,
        status: ItemStatus.available,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockRepository.addMockItem(testItem);

      await tester.pumpWidget(createTestWidget('item-1'));
      await tester.pumpAndSettle();

      // Scroll to make button visible
      await tester.dragUntilVisible(
        find.byKey(const Key('item_mark_consumed_button')),
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('item_mark_consumed_button')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byKey(const Key('consume_percentage_value')), findsOneWidget);
      expect(
        find.byKey(const Key('consume_percentage_slider')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('consume_cancel_button')), findsOneWidget);
      expect(find.byKey(const Key('consume_confirm_button')), findsOneWidget);
    });

    testWidgets('mark used updates item status and emits telemetry', (
      WidgetTester tester,
    ) async {
      final testItem = Item(
        id: 'item-1',
        name: 'Test Apple',
        category: ItemCategory.produce,
        location: StorageLocation.fridge,
        status: ItemStatus.available,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockRepository.addMockItem(testItem);

      await tester.pumpWidget(createTestWidget('item-1'));
      await tester.pumpAndSettle();

      // Scroll to make button visible
      await tester.dragUntilVisible(
        find.byKey(const Key('item_mark_consumed_button')),
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();

      // Tap mark used button
      await tester.tap(find.byKey(const Key('item_mark_consumed_button')));
      await tester.pumpAndSettle();

      // Confirm dialog
      await tester.tap(find.byKey(const Key('consume_confirm_button')));
      await tester.pumpAndSettle();

      // Verify item updated
      final updatedItem = await mockRepository.getItem('item-1');
      expect(updatedItem?.status, ItemStatus.consumed);

      // Verify telemetry
      final telemetryEvents = mockTelemetry.events;
      expect(
        telemetryEvents.any((e) => e['name'] == 'item_marked_used'),
        isTrue,
      );
    });

    testWidgets('mark wasted shows waste reason selection', (
      WidgetTester tester,
    ) async {
      final testItem = Item(
        id: 'item-1',
        name: 'Test Apple',
        category: ItemCategory.produce,
        location: StorageLocation.fridge,
        status: ItemStatus.available,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockRepository.addMockItem(testItem);

      await tester.pumpWidget(createTestWidget('item-1'));
      await tester.pumpAndSettle();

      // Scroll to make button visible
      await tester.dragUntilVisible(
        find.byKey(const Key('item_mark_wasted_button')),
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('item_mark_wasted_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('waste_dialog')), findsOneWidget);
      expect(find.byKey(const Key('waste_reason_spoiled')), findsOneWidget);
      expect(find.byKey(const Key('waste_reason_forgotten')), findsOneWidget);
      expect(find.byKey(const Key('waste_reason_expired')), findsOneWidget);
      expect(find.byKey(const Key('waste_reason_damaged')), findsOneWidget);
    });

    testWidgets('mark wasted updates item with reason and emits telemetry', (
      WidgetTester tester,
    ) async {
      final testItem = Item(
        id: 'item-1',
        name: 'Test Apple',
        category: ItemCategory.produce,
        location: StorageLocation.fridge,
        status: ItemStatus.available,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockRepository.addMockItem(testItem);

      await tester.pumpWidget(createTestWidget('item-1'));
      await tester.pumpAndSettle();

      // Scroll to make button visible
      await tester.dragUntilVisible(
        find.byKey(const Key('item_mark_wasted_button')),
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();

      // Tap mark wasted button
      await tester.tap(find.byKey(const Key('item_mark_wasted_button')));
      await tester.pumpAndSettle();

      // Select spoiled reason
      await tester.tap(find.byKey(const Key('waste_reason_spoiled')));
      await tester.pumpAndSettle();

      // Confirm dialog
      await tester.tap(find.byKey(const Key('waste_confirm_button')));
      await tester.pumpAndSettle();

      // Verify item updated with waste reason
      final updatedItem = await mockRepository.getItem('item-1');
      expect(updatedItem?.status, ItemStatus.wasted);
      expect(updatedItem?.wasteReason, WasteReason.spoiled);

      // Verify telemetry
      final telemetryEvents = mockTelemetry.events;
      final wasteEvent = telemetryEvents.firstWhere(
        (e) => e['name'] == 'item_marked_wasted',
      );
      expect(wasteEvent['properties']['waste_reason'], 'spoiled');
    });

    testWidgets('tracks screen_viewed telemetry on init', (
      WidgetTester tester,
    ) async {
      final testItem = Item(
        id: 'item-1',
        name: 'Test Item',
        category: ItemCategory.produce,
        location: StorageLocation.fridge,
        status: ItemStatus.available,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockRepository.addMockItem(testItem);

      await tester.pumpWidget(createTestWidget('item-1'));
      await tester.pumpAndSettle();

      final screenViewEvents = mockTelemetry.events
          .where((e) => e['name'] == 'screen_viewed')
          .toList();
      expect(screenViewEvents.length, 1);
      expect(
        screenViewEvents.first['properties']['screen_name'],
        'item_detail',
      );
      expect(screenViewEvents.first['properties']['item_id'], 'item-1');
    });

    testWidgets('highlights expiring soon items', (WidgetTester tester) async {
      final testItem = Item(
        id: 'item-1',
        name: 'Test Item',
        category: ItemCategory.produce,
        location: StorageLocation.fridge,
        expiryDate: DateTime.now().add(const Duration(days: 2)), // Expires soon
        status: ItemStatus.available,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockRepository.addMockItem(testItem);

      await tester.pumpWidget(createTestWidget('item-1'));
      await tester.pumpAndSettle();

      // Check for expiry date label and status showing days left
      expect(find.byKey(const Key('item_detail_expiry')), findsOneWidget);
      expect(find.byKey(const Key('item_detail_status')), findsOneWidget);
    });
  });
}
