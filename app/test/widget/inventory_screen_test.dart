import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerospoils/core/feature_flags/feature_flag_key.dart';
import 'package:zerospoils/core/feature_flags/feature_flags_provider.dart';
import 'package:zerospoils/data/repositories/user_category_repository.dart';
import 'package:zerospoils/data/repositories/hive_item_repository.dart';
import 'package:zerospoils/domain/models/item_model.dart';
import 'package:zerospoils/domain/models/user_category.dart';
import 'package:zerospoils/presentation/di/repository_providers.dart';
import 'package:zerospoils/presentation/di/service_locator.dart'
    hide itemRepositoryProvider;
import 'package:zerospoils/presentation/screens/inventory_screen.dart';
import 'package:zerospoils/presentation/screens/item_form_screen.dart';
import 'package:zerospoils/presentation/themes/app_theme.dart';
import 'package:zerospoils/presentation/widgets/item_card.dart';
import 'package:zerospoils/presentation/widgets/item_icon.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  void enqueue(Map<String, dynamic> event) {
    events.add(event);
  }
}

class FakeUserCategoryRepository extends UserCategoryRepository {
  final List<UserCategory> categories;

  FakeUserCategoryRepository({this.categories = const []});

  @override
  Future<void> init() async {}

  @override
  Future<List<UserCategory>> getAll() async =>
      List<UserCategory>.from(categories);
}

void main() {
  late MockItemRepository mockRepository;
  late FakeUserCategoryRepository fakeUserCategoryRepository;
  Item buildTestItem() {
    final now = DateTime.now();
    return Item(
      id: 'test-item',
      name: 'Apples',
      category: ItemCategory.produce,
      location: StorageLocation.pantry,
      status: ItemStatus.available,
      createdAt: now,
      updatedAt: now,
    );
  }

  setUp(() {
    mockRepository = MockItemRepository();
    fakeUserCategoryRepository = FakeUserCategoryRepository();
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpInventoryScreen(
    WidgetTester tester, {
    InventoryFilterState? filterState,
    ThemeMode themeMode = ThemeMode.light,
    List<Override> overrides = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemRepositoryProvider.overrideWithValue(mockRepository),
          itemsFutureProvider.overrideWith((ref) async {
            // Bypass Hive init - return mock items directly
            return mockRepository.items;
          }),
          userCategoryRepositoryProvider.overrideWithValue(
            fakeUserCategoryRepository,
          ),
          if (filterState != null)
            inventoryFilterProvider.overrideWith((ref) => filterState),
          telemetryClientProvider.overrideWithValue(MockTelemetryClient()),
          ...overrides,
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: const InventoryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders empty state when no items', (tester) async {
    mockRepository.items = [];

    await pumpInventoryScreen(tester);

    expect(find.byKey(const Key('inventory_empty_state')), findsOneWidget);
    expect(find.byKey(const Key('inventory_add_fab')), findsOneWidget);
  });

  testWidgets('uses dark theme surfaces in dark mode', (tester) async {
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
    ];

    await pumpInventoryScreen(tester, themeMode: ThemeMode.dark);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    final theme = Theme.of(tester.element(find.byType(InventoryScreen)));

    expect(scaffold.backgroundColor, theme.scaffoldBackgroundColor);
    expect(
      appBar.backgroundColor ?? theme.appBarTheme.backgroundColor,
      theme.appBarTheme.backgroundColor,
    );
  });

  testWidgets('uses high-contrast item icons in dark mode', (tester) async {
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
    ];

    await pumpInventoryScreen(tester, themeMode: ThemeMode.dark);

    final itemIcon = tester.widget<Icon>(
      find.descendant(
        of: find.byType(ItemIcon).first,
        matching: find.byType(Icon),
      ),
    );
    final theme = Theme.of(tester.element(find.byType(InventoryScreen)));

    expect(itemIcon.color, theme.colorScheme.onSurface);
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

    expect(find.byKey(const Key('inventory_item_card_1')), findsOneWidget);
    expect(find.byKey(const Key('inventory_item_card_2')), findsOneWidget);
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

  testWidgets('defaults to list view mode', (tester) async {
    mockRepository.items = [buildTestItem()];

    await pumpInventoryScreen(tester);

    expect(find.byKey(const Key('inventory_view_mode_list')), findsOneWidget);
  });

  testWidgets('toggles to grid and table view modes', (tester) async {
    mockRepository.items = [buildTestItem()];

    await pumpInventoryScreen(tester);

    await tester.tap(find.byKey(const Key('inventory_view_mode_grid_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('inventory_view_mode_grid')), findsOneWidget);

    await tester.tap(find.byKey(const Key('inventory_view_mode_table_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('inventory_view_mode_table')), findsOneWidget);
  });

  testWidgets('emits telemetry when view mode changes', (tester) async {
    final telemetry = MockTelemetryClient();
    final now = DateTime.now();
    mockRepository.items = [
      Item(
        id: '1',
        name: 'Milk',
        category: ItemCategory.dairy,
        location: StorageLocation.fridge,
        status: ItemStatus.available,
        expiryDate: now.add(const Duration(days: 4)),
        createdAt: now,
        updatedAt: now,
      ),
      Item(
        id: '2',
        name: 'Chicken',
        category: ItemCategory.meat,
        location: StorageLocation.freezer,
        status: ItemStatus.available,
        expiryDate: now.add(const Duration(days: 2)),
        createdAt: now,
        updatedAt: now,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemRepositoryProvider.overrideWithValue(mockRepository),
          itemsFutureProvider.overrideWith((ref) async {
            return mockRepository.items;
          }),
          telemetryClientProvider.overrideWithValue(telemetry),
        ],
        child: const MaterialApp(home: InventoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('inventory_view_mode_grid_button')));
    await tester.pumpAndSettle();

    expect(telemetry.events, isNotEmpty);
    final event = telemetry.events.last;
    expect(event['name'], 'inventory_view_mode_changed');
    final properties = event['properties'] as Map<String, dynamic>;
    expect(properties['from'], 'list');
    expect(properties['to'], 'grid');
    expect(properties['filters_applied'], 0);
    expect(properties['sort_key'], isNotNull);
    expect(properties['result_count'], 2);
  });

  testWidgets('table header sorting toggles and persists across modes', (
    tester,
  ) async {
    final now = DateTime.now();
    mockRepository.items = [
      Item(
        id: '1',
        name: 'Bananas',
        category: ItemCategory.produce,
        location: StorageLocation.pantry,
        status: ItemStatus.available,
        createdAt: now,
        updatedAt: now,
      ),
      Item(
        id: '2',
        name: 'Apples',
        category: ItemCategory.produce,
        location: StorageLocation.fridge,
        status: ItemStatus.available,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    await pumpInventoryScreen(tester);

    await tester.tap(find.byKey(const Key('inventory_view_mode_table_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('inventory_table_header_name')));
    await tester.pumpAndSettle();

    var table = tester.widget<DataTable>(find.byType(DataTable));
    expect(table.sortColumnIndex, 0);
    expect(table.sortAscending, true);
    var firstCell = table.rows.first.cells.first.child as Text;
    expect(firstCell.data, 'Apples');

    await tester.tap(find.byKey(const Key('inventory_table_header_name')));
    await tester.pumpAndSettle();

    table = tester.widget<DataTable>(find.byType(DataTable));
    expect(table.sortColumnIndex, 0);
    expect(table.sortAscending, false);
    firstCell = table.rows.first.cells.first.child as Text;
    expect(firstCell.data, 'Bananas');

    await tester.tap(find.byKey(const Key('inventory_view_mode_grid_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('inventory_view_mode_table_button')));
    await tester.pumpAndSettle();

    table = tester.widget<DataTable>(find.byType(DataTable));
    expect(table.sortColumnIndex, 0);
    expect(table.sortAscending, false);
  });

  testWidgets('persists view mode across restarts', (tester) async {
    SharedPreferences.setMockInitialValues({'inventory_view_mode': 'grid'});
    mockRepository.items = [buildTestItem()];

    await pumpInventoryScreen(tester);

    expect(find.byKey(const Key('inventory_view_mode_grid')), findsOneWidget);
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
    expect(find.byKey(const Key('inventory_item_card_1')), findsOneWidget);
    expect(find.byKey(const Key('inventory_item_card_2')), findsOneWidget);

    // Open filter dialog
    await tester.tap(find.byKey(const Key('inventory_filter_button')));
    await tester.pumpAndSettle();

    // Select Dairy category and apply
    await tester.tap(find.byKey(const Key('inventory_filter_category_dairy')));
    await tester.pumpAndSettle();
    final applyButton = find.byKey(const Key('inventory_filter_apply'));
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    // Only Milk should be visible
    expect(find.byKey(const Key('inventory_item_card_1')), findsOneWidget);
    expect(find.byKey(const Key('inventory_item_card_2')), findsNothing);
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
    await tester.tap(find.byKey(const Key('inventory_filter_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('inventory_filter_apply')), findsOneWidget);

    // Select Fridge location
    await tester.tap(find.byKey(const Key('inventory_filter_location_fridge')));
    await tester.pumpAndSettle();

    // Apply filters
    final applyButton = find.byKey(const Key('inventory_filter_apply'));
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    // Only Milk should be visible
    expect(find.byKey(const Key('inventory_item_card_1')), findsOneWidget);
    expect(find.byKey(const Key('inventory_item_card_2')), findsNothing);
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
    expect(find.byKey(const Key('inventory_item_card_1')), findsOneWidget);
    expect(find.byKey(const Key('inventory_item_card_2')), findsOneWidget);

    // Open filter dialog
    await tester.tap(find.byKey(const Key('inventory_filter_button')));
    await tester.pumpAndSettle();

    // Enable expiring soon filter
    await tester.tap(find.byKey(const Key('inventory_filter_expiring_soon')));
    await tester.pumpAndSettle();

    // Apply filters
    final applyButton = find.byKey(const Key('inventory_filter_apply'));
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    // Only Milk should be visible
    expect(find.byKey(const Key('inventory_item_card_1')), findsOneWidget);
    expect(find.byKey(const Key('inventory_item_card_2')), findsNothing);
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

    await tester.tap(find.byKey(const Key('inventory_filter_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('inventory_filter_prepared_only')));
    await tester.pumpAndSettle();

    final applyButton = find.byKey(const Key('inventory_filter_apply'));
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('inventory_item_card_1')), findsOneWidget);
    expect(find.byKey(const Key('inventory_item_card_2')), findsNothing);
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

    // Verify add FAB exists (navigation requires GoRouter context, tested in integration tests)
    expect(find.byKey(const Key('inventory_add_fab')), findsOneWidget);
  });

  testWidgets('FAB opens item form directly', (tester) async {
    mockRepository.items = [];

    await pumpInventoryScreen(tester);

    await tester.tap(find.byKey(const Key('inventory_add_fab')));
    await tester.pumpAndSettle();

    expect(find.byType(ItemFormScreen), findsOneWidget);
  });

  testWidgets('FAB opens item form directly on mobile', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    mockRepository.items = [];

    try {
      await pumpInventoryScreen(
        tester,
        overrides: [
          isFlagEnabledProvider(
            FeatureFlagKey.expiryDateOcr,
          ).overrideWith((ref) async => true),
        ],
      );

      await tester.tap(find.byKey(const Key('inventory_add_fab')));
      await tester.pumpAndSettle();

      expect(find.byType(ItemFormScreen), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets(
    'receipt batch button is shown when receipt batch capture flag is enabled',
    (tester) async {
      mockRepository.items = [buildTestItem()];

      await pumpInventoryScreen(
        tester,
        overrides: [
          isFlagEnabledProvider(
            FeatureFlagKey.receiptBatchCapture,
          ).overrideWith((ref) async => true),
          isFlagEnabledProvider(
            FeatureFlagKey.batchPhotoCapture,
          ).overrideWith((ref) async => false),
        ],
      );

      expect(
        find.byKey(const Key('inventory_receipt_batch_button')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'receipt batch button is hidden when receipt batch capture flag is disabled even if batch photo capture is enabled',
    (tester) async {
      mockRepository.items = [buildTestItem()];

      await pumpInventoryScreen(
        tester,
        overrides: [
          isFlagEnabledProvider(
            FeatureFlagKey.receiptBatchCapture,
          ).overrideWith((ref) async => false),
          isFlagEnabledProvider(
            FeatureFlagKey.batchPhotoCapture,
          ).overrideWith((ref) async => true),
        ],
      );

      expect(
        find.byKey(const Key('inventory_receipt_batch_button')),
        findsNothing,
      );
    },
  );
}
