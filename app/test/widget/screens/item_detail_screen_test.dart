// Widget test for ItemDetailScreen
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerospoils/presentation/screens/item_detail_screen.dart';
import 'package:zerospoils/domain/models/item_model.dart';
import 'package:zerospoils/domain/models/receipt_batch.dart';
import 'package:zerospoils/data/repositories/hive_item_repository.dart';
import 'package:zerospoils/data/repositories/receipt_batch_repository.dart';
import 'package:zerospoils/presentation/di/service_locator.dart'
    hide itemRepositoryProvider;
import 'package:zerospoils/presentation/di/repository_providers.dart';
import 'package:zerospoils/presentation/themes/app_theme.dart';
import 'package:zerospoils/presentation/widgets/item_icon.dart';

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

class MockReceiptBatchRepository implements ReceiptBatchRepository {
  final Map<String, ReceiptBatch> _batches = {};

  void addBatch(ReceiptBatch batch) {
    _batches[batch.id] = batch;
  }

  @override
  Future<void> init() async {}

  @override
  Future<List<ReceiptBatch>> getAllBatches() async => _batches.values.toList();

  @override
  Future<ReceiptBatch?> getBatch(String id) async => _batches[id];

  @override
  Future<void> saveBatch(ReceiptBatch batch) async {
    _batches[batch.id] = batch;
  }
}

void main() {
  group('ItemDetailScreen', () {
    late MockItemRepository mockRepository;
    late MockTelemetryClient mockTelemetry;
    late MockReceiptBatchRepository mockReceiptBatchRepository;

    setUp(() {
      mockRepository = MockItemRepository();
      mockTelemetry = MockTelemetryClient();
      mockReceiptBatchRepository = MockReceiptBatchRepository();
    });

    Widget createThemedTestWidget(
      String itemId, {
      ThemeMode themeMode = ThemeMode.light,
    }) {
      return ProviderScope(
        overrides: [
          itemRepositoryProvider.overrideWithValue(mockRepository),
          receiptBatchRepositoryProvider.overrideWithValue(
            mockReceiptBatchRepository,
          ),
          telemetryClientProvider.overrideWithValue(mockTelemetry),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: ItemDetailScreen(itemId: itemId),
        ),
      );
    }

    Widget createTestWidget(String itemId) {
      return createThemedTestWidget(itemId);
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

    testWidgets('shows linked shopping batch details for linked items', (
      WidgetTester tester,
    ) async {
      final testItem = Item(
        id: 'item-1',
        name: 'Linked Yogurt',
        category: ItemCategory.dairy,
        location: StorageLocation.fridge,
        status: ItemStatus.available,
        receiptBatchId: 'batch-123',
        createdAt: DateTime(2026, 1, 20),
        updatedAt: DateTime(2026, 1, 20),
      );
      mockRepository.addMockItem(testItem);
      mockReceiptBatchRepository.addBatch(
        ReceiptBatch(
          id: 'batch-123',
          createdAt: DateTime(2026, 1, 19),
          storeName: 'No Frills',
          source: ReceiptBatchSource.shoppingList,
          items: const [],
        ),
      );

      await tester.pumpWidget(createTestWidget('item-1'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('item_detail_batch')), findsOneWidget);
      expect(find.textContaining('No Frills'), findsOneWidget);
      expect(find.byKey(const Key('item_detail_open_batch_button')), findsOneWidget);
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

    testWidgets('uses dark theme surfaces in dark mode', (
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

      await tester.pumpWidget(
        createThemedTestWidget('item-1', themeMode: ThemeMode.dark),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      final detailCard = tester.widget<Card>(find.byType(Card).first);
      final theme = Theme.of(tester.element(find.byType(ItemDetailScreen)));

      expect(scaffold.backgroundColor, theme.scaffoldBackgroundColor);
      expect(
        appBar.backgroundColor ?? theme.appBarTheme.backgroundColor,
        theme.appBarTheme.backgroundColor,
      );
      expect(
        detailCard.color ?? theme.cardTheme.color ?? theme.cardColor,
        theme.cardTheme.color ?? theme.cardColor,
      );

      final itemIcon = tester.widget<Icon>(
        find.descendant(of: find.byType(ItemIcon), matching: find.byType(Icon)),
      );

      expect(itemIcon.color, theme.colorScheme.onSurface);
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

    testWidgets('shows brand row when item has a brand', (
      WidgetTester tester,
    ) async {
      final testItem = Item(
        id: 'item-brand',
        name: 'Organic Milk',
        category: ItemCategory.dairy,
        location: StorageLocation.fridge,
        status: ItemStatus.available,
        brand: 'Organic Valley',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockRepository.addMockItem(testItem);

      await tester.pumpWidget(createTestWidget('item-brand'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('item_detail_brand')), findsOneWidget);
      expect(find.byKey(const Key('item_detail_brand_value')), findsOneWidget);
      expect(find.text('Organic Valley'), findsWidgets);
    });

    testWidgets('hides brand row when item has no brand', (
      WidgetTester tester,
    ) async {
      final testItem = Item(
        id: 'item-nobrand',
        name: 'Generic Milk',
        category: ItemCategory.dairy,
        location: StorageLocation.fridge,
        status: ItemStatus.available,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockRepository.addMockItem(testItem);

      await tester.pumpWidget(createTestWidget('item-nobrand'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('item_detail_brand')), findsNothing);
      expect(find.byKey(const Key('item_detail_brand_value')), findsOneWidget);
      final brandValueText = tester.widget<Text>(
        find.byKey(const Key('item_detail_brand_value')),
      );
      expect(brandValueText.data, '—');
    });
  });
}
