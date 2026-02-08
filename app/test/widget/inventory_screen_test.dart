import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerospoils/data/repositories/hive_item_repository.dart';
import 'package:zerospoils/domain/models/item_model.dart';
import 'package:zerospoils/presentation/di/repository_providers.dart';
import 'package:zerospoils/presentation/di/service_locator.dart'
    hide itemRepositoryProvider;
import 'package:zerospoils/presentation/screens/inventory_screen.dart';
import 'package:zerospoils/presentation/widgets/item_card.dart';

// Mock repositories and telemetry client for testing
class MockItemRepository extends HiveItemRepository {
  List<Item> items = [];

  Future<List<Item>> getItems() async => items;

  @override
  Future<void> init() async {}

  Future<void> addItem(Item item) async => items.add(item);

  Future<void> updateItem(Item item) async {
    final index = items.indexWhere((i) => i.id == item.id);
    if (index != -1) items[index] = item;
  }

  @override
  Future<void> deleteItem(String id) async =>
      items.removeWhere((item) => item.id == id);
}

class MockTelemetryClient extends TelemetryClient {
  @override
  void enqueue(Map<String, dynamic> event) {}

  void trackEvent(String eventName, {Map<String, dynamic>? properties}) {}

  void trackScreen(String screenName, {Map<String, dynamic>? properties}) {}
}

void main() {
  late MockItemRepository mockRepository;

  setUp(() {
    mockRepository = MockItemRepository();
  });

  Future<void> pumpInventoryScreen(
    WidgetTester tester, {
    InventoryFilterState? filterState,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemRepositoryProvider.overrideWithValue(mockRepository),
          itemsFutureProvider.overrideWith((ref) async {
            // Bypass Hive init - return mock items directly
            return mockRepository.items;
          }),
          if (filterState != null)
            inventoryFilterProvider.overrideWith((ref) => filterState),
          telemetryClientProvider.overrideWithValue(MockTelemetryClient()),
        ],
        child: const MaterialApp(home: InventoryScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders empty state when no items', (tester) async {
    mockRepository.items = [];

    await pumpInventoryScreen(tester);

    expect(find.textContaining('Your inventory is empty'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('displays list of items', (tester) async {
    final now = DateTime.now();
    mockRepository.items = [
      Item(
        id: '1',
        name: 'Milk',
        category: ItemCategory.dairy,
        location: StorageLocation.fridge,
        status: ItemStatus.available,
        expiryDate: now.add(const Duration(days: 5)),
        createdAt: now,
        updatedAt: now,
      ),
      Item(
        id: '2',
        name: 'Chicken',
        category: ItemCategory.meat,
        location: StorageLocation.freezer,
        status: ItemStatus.available,
        expiryDate: now.add(const Duration(days: 10)),
        createdAt: now,
        updatedAt: now,
      ),
    ];

    await pumpInventoryScreen(tester);

    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Chicken'), findsOneWidget);
  });

  testWidgets('search filters items by name', (tester) async {
    final now = DateTime.now();
    mockRepository.items = [
      Item(
        id: '1',
        name: 'Milk',
        category: ItemCategory.dairy,
        location: StorageLocation.fridge,
        status: ItemStatus.available,
        createdAt: now,
        updatedAt: now,
      ),
      Item(
        id: '2',
        name: 'Chicken',
        category: ItemCategory.meat,
        location: StorageLocation.freezer,
        status: ItemStatus.available,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    await pumpInventoryScreen(tester);

    // Initially both items visible in ItemCards
    expect(
      find.byWidgetPredicate(
        (widget) => widget is ItemCard && widget.item.name == 'Milk',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget is ItemCard && widget.item.name == 'Chicken',
      ),
      findsOneWidget,
    );

    // Search for "Milk"
    await tester.enterText(find.byType(TextField), 'Milk');
    await tester.pump();

    // Only Milk ItemCard should be visible (Chicken card filtered out)
    expect(
      find.byWidgetPredicate(
        (widget) => widget is ItemCard && widget.item.name == 'Milk',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget is ItemCard && widget.item.name == 'Chicken',
      ),
      findsNothing,
    );
  });

  testWidgets('category filter works', (tester) async {
    final now = DateTime.now();
    mockRepository.items = [
      Item(
        id: '1',
        name: 'Milk',
        category: ItemCategory.dairy,
        location: StorageLocation.fridge,
        status: ItemStatus.available,
        createdAt: now,
        updatedAt: now,
      ),
      Item(
        id: '2',
        name: 'Chicken',
        category: ItemCategory.meat,
        location: StorageLocation.freezer,
        status: ItemStatus.available,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    await pumpInventoryScreen(tester);

    // Initially both items visible
    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Chicken'), findsOneWidget);

    // Open filter dialog
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    // Select Dairy category and apply
    await tester.tap(find.text('Dairy'));
    await tester.pumpAndSettle();
    final applyButton = find.text('Apply');
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    // Only Milk should be visible
    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Chicken'), findsNothing);
  });

  testWidgets('location filter dialog works', (tester) async {
    final now = DateTime.now();
    mockRepository.items = [
      Item(
        id: '1',
        name: 'Milk',
        category: ItemCategory.dairy,
        location: StorageLocation.fridge,
        status: ItemStatus.available,
        createdAt: now,
        updatedAt: now,
      ),
      Item(
        id: '2',
        name: 'Ice Cream',
        category: ItemCategory.dairy,
        location: StorageLocation.freezer,
        status: ItemStatus.available,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    await pumpInventoryScreen(tester);

    // Open filter dialog
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    expect(find.text('Filters'), findsOneWidget);
    expect(find.textContaining('Location'), findsOneWidget);

    // Select Fridge location
    await tester.tap(find.text('Fridge'));
    await tester.pumpAndSettle();

    // Apply filters
    final applyButton = find.text('Apply');
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    // Only Milk should be visible
    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Ice Cream'), findsNothing);
  });

  testWidgets('expiring soon filter works', (tester) async {
    final now = DateTime.now();
    mockRepository.items = [
      Item(
        id: '1',
        name: 'Milk',
        category: ItemCategory.dairy,
        location: StorageLocation.fridge,
        status: ItemStatus.available,
        expiryDate: now.add(const Duration(days: 2)), // Expiring soon
        createdAt: now,
        updatedAt: now,
      ),
      Item(
        id: '2',
        name: 'Cheese',
        category: ItemCategory.dairy,
        location: StorageLocation.fridge,
        status: ItemStatus.available,
        expiryDate: now.add(const Duration(days: 10)), // Not expiring soon
        createdAt: now,
        updatedAt: now,
      ),
    ];

    await pumpInventoryScreen(tester);

    // Initially both items visible
    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Cheese'), findsOneWidget);

    // Open filter dialog
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    // Enable expiring soon filter
    await tester.tap(find.byKey(const Key('inventory_filter_expiring_soon')));
    await tester.pumpAndSettle();

    // Apply filters
    final applyButton = find.text('Apply');
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    // Only Milk should be visible
    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Cheese'), findsNothing);
  });

  testWidgets('prepared filter works', (tester) async {
    final now = DateTime.now();
    mockRepository.items = [
      Item(
        id: '1',
        name: 'Salad',
        category: ItemCategory.produce,
        type: ItemType.prepared,
        preparedDate: now,
        location: StorageLocation.fridge,
        status: ItemStatus.available,
        createdAt: now,
        updatedAt: now,
      ),
      Item(
        id: '2',
        name: 'Milk',
        category: ItemCategory.dairy,
        type: ItemType.raw,
        location: StorageLocation.fridge,
        status: ItemStatus.available,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    await pumpInventoryScreen(tester);

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('inventory_filter_prepared_only')));
    await tester.pumpAndSettle();

    final applyButton = find.text('Apply');
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) => widget is ItemCard && widget.item.id == '1',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget is ItemCard && widget.item.id == '2',
      ),
      findsNothing,
    );
  });

  testWidgets('created date range filter works', (tester) async {
    final now = DateTime(2026, 2, 7);
    mockRepository.items = [
      Item(
        id: '1',
        name: 'Old Item',
        category: ItemCategory.pantry,
        location: StorageLocation.pantry,
        status: ItemStatus.available,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: now,
      ),
      Item(
        id: '2',
        name: 'New Item',
        category: ItemCategory.dairy,
        location: StorageLocation.fridge,
        status: ItemStatus.available,
        createdAt: DateTime(2026, 2, 1),
        updatedAt: now,
      ),
    ];

    await pumpInventoryScreen(
      tester,
      filterState: InventoryFilterState(createdAfter: DateTime(2026, 1, 15)),
    );

    expect(
      find.byWidgetPredicate(
        (widget) => widget is ItemCard && widget.item.id == '2',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget is ItemCard && widget.item.id == '1',
      ),
      findsNothing,
    );
  });

  testWidgets('FAB is present', (tester) async {
    mockRepository.items = [];

    await pumpInventoryScreen(tester);

    // Verify FAB exists (navigation requires GoRouter context, tested in integration tests)
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
