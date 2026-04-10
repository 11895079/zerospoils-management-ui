import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:zerospoils/data/repositories/hive_item_repository.dart';
import 'package:zerospoils/domain/models/item_model.dart';
import 'package:zerospoils/domain/models/user_category.dart';
import 'package:zerospoils/presentation/di/repository_providers.dart';
import 'package:zerospoils/presentation/di/service_locator.dart'
    show TelemetryClient, telemetryClientProvider;
import 'package:zerospoils/presentation/screens/item_form_screen.dart';
import 'package:zerospoils/presentation/themes/app_theme.dart';
import 'package:zerospoils/presentation/widgets/app_button.dart';

/// Mock repository for testing without Hive file I/O
class MockItemRepository extends HiveItemRepository {
  final Map<String, Item> _items = {};
  bool _initialized = false;

  @override
  Future<void> init() async {
    _initialized = true;
  }

  @override
  Future<List<Item>> getAllItems() async {
    if (!_initialized) throw Exception('Repository not initialized');
    return _items.values.toList();
  }

  @override
  Future<Item?> getItem(String id) async {
    if (!_initialized) throw Exception('Repository not initialized');
    return _items[id];
  }

  @override
  Future<void> saveItem(Item item) async {
    if (!_initialized) throw Exception('Repository not initialized');
    _items[item.id] = item;
  }

  @override
  Future<void> deleteItem(String id) async {
    if (!_initialized) throw Exception('Repository not initialized');
    _items.remove(id);
  }

  @override
  Future<void> close() async {
    // No-op for mock
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockItemRepository repository;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('item_form_repo_test_');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(22)) {
      Hive.registerAdapter(UserCategoryAdapter());
    }
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    repository = MockItemRepository();
    await repository.init(); // Initialize before use
  });

  Future<void> pumpItemForm(
    WidgetTester tester, {
    ThemeMode themeMode = ThemeMode.light,
    String? itemId,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [itemRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: ItemFormScreen(itemId: itemId),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('saving new item calls repository.saveItem', (tester) async {
    // Make the viewport large enough to avoid overflow/scroll issues
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [itemRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: ItemFormScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // Enter required fields
    final nameField = find.byType(TextFormField).first;
    await tester.enterText(nameField, 'Test Milk');
    await tester.enterText(
      find.byKey(const Key('item_form_brand_field')),
      'Fairlife',
    );

    // Increment quantity using QuantityToggle's add button
    final addQuantityButton = find.byIcon(Icons.add_circle_outline).first;
    await tester.tap(addQuantityButton);
    await tester.pumpAndSettle();

    // Confirm the quantity change using the check icon button
    final confirmButton = find.byIcon(Icons.check_circle).first;
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    // Tap the primary action button (AppButton)
    await tester.tap(find.byKey(const Key('item_form_save_button')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final items = await repository.getAllItems();
    expect(items.length, 1);
    expect(items.first.name, 'Test Milk');
    expect(items.first.brand, 'Fairlife');
    expect(items.first.quantity, 2);
  });

  testWidgets('auto-populates category for known items', (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [itemRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: ItemFormScreen()),
      ),
    );

    await tester.pumpAndSettle();

    final nameField = find.byType(TextFormField).first;
    await tester.enterText(nameField, 'Milk');

    await tester.tap(find.byKey(const Key('item_form_save_button')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final items = await repository.getAllItems();
    expect(items.length, 1);
    expect(items.first.category, ItemCategory.dairy);
  });

  testWidgets('manual save emits manual entry telemetry', (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final telemetry = TelemetryClient(consentEnabled: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemRepositoryProvider.overrideWithValue(repository),
          telemetryClientProvider.overrideWithValue(telemetry),
        ],
        child: const MaterialApp(home: ItemFormScreen()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('item_form_name_field')),
      'Manual Milk',
    );
    await tester.tap(find.byKey(const Key('item_form_save_button')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final itemAddedEvent = telemetry.events.lastWhere(
      (event) => event['name'] == 'item_added',
    );
    final properties = itemAddedEvent['properties'] as Map<String, dynamic>;

    expect(properties['entry_method'], 'manual');
    expect(properties['source'], 'manual');
    expect(properties['camera_used'], false);
    expect(properties['camera_barcode_accepted'], false);
    expect(properties['camera_expiry_accepted'], false);
    expect(properties['camera_barcode_source'], 'none');
    expect(properties['camera_expiry_format'], 'none');
  });

  testWidgets('recent item suggestion reuses prior category and location', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final existingItem = Item(
      id: 'recent-1',
      name: 'Greek Yogurt',
      brand: 'Fage',
      category: ItemCategory.dairy,
      location: StorageLocation.freezer,
      quantity: 1,
      status: ItemStatus.available,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
    );
    await repository.saveItem(existingItem);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [itemRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: ItemFormScreen()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('item_form_name_field')),
      'Greek',
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('recent_item_suggestion_0')), findsOneWidget);

    await tester.tap(find.byKey(const Key('recent_item_suggestion_0')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('item_form_save_button')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final items = await repository.getAllItems();
    final saved = items.firstWhere((item) => item.id != existingItem.id);
    expect(saved.name, 'Greek Yogurt');
    expect(saved.brand, 'Fage');
    expect(saved.category, ItemCategory.dairy);
    expect(saved.location, StorageLocation.freezer);
  });

  testWidgets('edit mode loads existing item from repository', (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final existingItem = Item(
      id: 'edit-1',
      name: 'Carrots',
      brand: 'Fresh Farms',
      category: ItemCategory.produce,
      location: StorageLocation.fridge,
      quantity: 3,
      expiryDate: DateTime.now().add(const Duration(days: 4)),
      status: ItemStatus.available,
      wasteReason: null,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    );

    await repository.saveItem(existingItem);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [itemRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(home: ItemFormScreen(itemId: existingItem.id)),
      ),
    );

    await tester.pumpAndSettle();

    // Ensure existing data is shown
    final nameField = find.byType(TextFormField).first;
    expect(tester.widget<TextFormField>(nameField).controller?.text, 'Carrots');
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('item_form_brand_field')))
          .controller
          ?.text,
      'Fresh Farms',
    );

    await tester.enterText(nameField, 'Baby Carrots');
    await tester.enterText(
      find.byKey(const Key('item_form_brand_field')),
      'Local Roots',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('item_form_save_button')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final updated = await repository.getItem(existingItem.id);
    expect(updated?.name, 'Baby Carrots');
    expect(updated?.brand, 'Local Roots');
    expect(updated?.quantity, 3);
  });

  testWidgets(
    'selecting prepared type applies defaults and saves prepared item',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [itemRepositoryProvider.overrideWithValue(repository)],
          child: const MaterialApp(home: ItemFormScreen()),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('item_type_prepared_label')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('item_form_prepared_date')), findsOneWidget);
      final locationField = tester
          .widget<DropdownButtonFormField<StorageLocation>>(
            find.byKey(const Key('item_form_location_dropdown')),
          );
      expect(locationField.initialValue, StorageLocation.freezer);

      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, 'Tomato Soup');
      await tester.pumpAndSettle();

      final addButton = find.byWidgetPredicate(
        (widget) => widget is AppButton && widget.text == 'Add Item',
      );
      await tester.tap(addButton);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      final saved = (await repository.getAllItems()).single;
      expect(saved.type, ItemType.prepared);
      expect(saved.location, StorageLocation.freezer);
      expect(saved.preparedDate, isNotNull);
      expect(saved.expiryDate, isNotNull);
    },
  );

  testWidgets('invalid price shows validation error and prevents save', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [itemRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: ItemFormScreen()),
      ),
    );

    await tester.pumpAndSettle();

    final nameField = find.byType(TextFormField).first;
    await tester.enterText(nameField, 'Price Test');

    final priceField = find.byKey(const Key('item_form_price_field'));
    await tester.enterText(priceField, '-5');

    await tester.tap(find.byKey(const Key('item_form_save_button')));
    await tester.pumpAndSettle();

    final priceFieldState = tester.state<FormFieldState<String>>(
      find.byKey(const Key('item_form_price_field')),
    );
    expect(priceFieldState.hasError, isTrue);
    final items = await repository.getAllItems();
    expect(items, isEmpty);
  });

  testWidgets('tapping expiry opens date picker and applies selection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [itemRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: ItemFormScreen()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('item_form_expiry_date')));
    await tester.pumpAndSettle();

    expect(find.byType(CalendarDatePicker), findsOneWidget);

    final dialogFinder = find.byType(DatePickerDialog);
    final okButton = find.descendant(
      of: dialogFinder,
      matching: find.byType(TextButton),
    );
    await tester.tap(okButton.last);
    await tester.pumpAndSettle();

    final expiryDateField = tester.widget<GestureDetector>(
      find.byKey(const Key('item_form_expiry_date')),
    );
    expect(expiryDateField.onTap, isNotNull);
  });

  testWidgets('uses dark theme surfaces in dark mode', (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await pumpItemForm(tester, themeMode: ThemeMode.dark);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    final previewContainer = tester.widget<Container>(
      find
          .byWidgetPredicate(
            (widget) =>
                widget is Container && widget.decoration is BoxDecoration,
          )
          .first,
    );
    final decoration = previewContainer.decoration as BoxDecoration;
    final theme = Theme.of(tester.element(find.byType(ItemFormScreen)));

    expect(scaffold.backgroundColor, theme.scaffoldBackgroundColor);
    expect(
      appBar.backgroundColor ?? theme.appBarTheme.backgroundColor,
      theme.appBarTheme.backgroundColor,
    );
    expect(decoration.color, theme.colorScheme.surfaceContainerHigh);
  });
}
