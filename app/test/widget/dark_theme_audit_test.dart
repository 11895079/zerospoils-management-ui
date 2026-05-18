import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerospoils/core/theme/app_colors.dart' as app_palette;
import 'package:zerospoils/data/repositories/hive_item_repository.dart';
import 'package:zerospoils/data/repositories/hive_shopping_list_repository.dart';
import 'package:zerospoils/domain/models/shopping_list_item.dart';
import 'package:zerospoils/domain/models/item_model.dart'
    show Item, ItemCategory, StorageLocation;
import 'package:zerospoils/presentation/di/repository_providers.dart';
import 'package:zerospoils/presentation/screens/home_shell.dart';
import 'package:zerospoils/presentation/themes/app_theme.dart';
import 'package:zerospoils/presentation/widgets/app_drawer.dart';
import 'package:zerospoils/presentation/widgets/category_chip.dart';
import 'package:zerospoils/presentation/widgets/item_card.dart';
import 'package:zerospoils/presentation/widgets/item_icon.dart';
import 'package:zerospoils/presentation/widgets/quantity_toggle.dart';

class MockItemRepository extends HiveItemRepository {
  bool _initialized = false;

  @override
  Future<void> init() async {
    _initialized = true;
  }

  @override
  Future<List<Item>> getAllItems() async {
    if (!_initialized) throw Exception('Repository not initialized');
    return const [];
  }
}

class MockShoppingListRepository extends HiveShoppingListRepository {
  bool _initialized = false;

  @override
  Future<void> init() async {
    _initialized = true;
  }

  @override
  Future<List<ShoppingListItem>> getAllItems() async {
    if (!_initialized) throw Exception('Repository not initialized');
    return const [];
  }
}

Widget buildDarkHarness(Widget child) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: ThemeMode.dark,
    home: child,
  );
}

void main() {
  late MockItemRepository mockItemRepository;
  late MockShoppingListRepository mockShoppingListRepository;

  setUp(() async {
    mockItemRepository = MockItemRepository();
    mockShoppingListRepository = MockShoppingListRepository();
    await mockItemRepository.init();
    await mockShoppingListRepository.init();
  });

  testWidgets('HomeShell uses dark bottom navigation colors', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemRepositoryProvider.overrideWithValue(mockItemRepository),
          shoppingListRepositoryProvider.overrideWithValue(
            mockShoppingListRepository,
          ),
        ],
        child: buildDarkHarness(const HomeShell()),
      ),
    );
    await tester.pumpAndSettle();

    final bottomNav = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    final theme = Theme.of(tester.element(find.byType(HomeShell)));

    expect(
      bottomNav.backgroundColor,
      theme.bottomNavigationBarTheme.backgroundColor,
    );
  });

  testWidgets('AppDrawer uses dark theme colors for default icons', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemRepositoryProvider.overrideWithValue(mockItemRepository),
          shoppingListRepositoryProvider.overrideWithValue(
            mockShoppingListRepository,
          ),
        ],
        child: buildDarkHarness(const Scaffold(body: AppDrawer())),
      ),
    );
    await tester.pumpAndSettle();

    final settingsTile = find.byKey(const Key('drawer_settings_item'));
    final settingsIcon = tester.widget<Icon>(
      find.descendant(of: settingsTile, matching: find.byIcon(Icons.settings)),
    );
    final theme = Theme.of(tester.element(find.byType(AppDrawer)));

    expect(settingsIcon.color, theme.colorScheme.onSurface);
  });

  testWidgets('ItemCard uses dark theme colors for available items', (
    WidgetTester tester,
  ) async {
    final item = Item(
      id: 'item-1',
      name: 'Milk',
      category: ItemCategory.dairy,
      location: StorageLocation.fridge,
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
    );

    await tester.pumpWidget(
      buildDarkHarness(
        Scaffold(
          body: ItemCard(item: item, onQuantityChanged: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final title = tester.widget<Text>(
      find
          .descendant(of: find.byType(ItemCard), matching: find.byType(Text))
          .first,
    );
    final itemIcon = tester.widget<Icon>(
      find.descendant(of: find.byType(ItemIcon), matching: find.byType(Icon)),
    );
    final theme = Theme.of(tester.element(find.byType(ItemCard)));

    expect(title.style?.color, theme.textTheme.titleMedium?.color);
    expect(itemIcon.color, theme.colorScheme.onSurface);
  });

  testWidgets('QuantityToggle uses dark theme colors when enabled', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildDarkHarness(
        Scaffold(
          body: QuantityToggle(quantity: 1, isEnabled: true, onConfirm: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final quantityToggleFinder = find.byType(QuantityToggle);
    final quantityContainerFinder = find.descendant(
      of: quantityToggleFinder,
      matching: find.byWidgetPredicate(
        (widget) => widget is Container && widget.decoration is BoxDecoration,
      ),
    );
    final quantityTextFinder = find.descendant(
      of: quantityContainerFinder.first,
      matching: find.byType(Text),
    );
    final quantityText = tester.widget<Text>(quantityTextFinder.first);
    final quantityContainer = tester.widget<Container>(
      quantityContainerFinder.first,
    );
    final decoration = quantityContainer.decoration as BoxDecoration;
    final iconButtons = tester
        .widgetList<IconButton>(find.byType(IconButton))
        .toList();
    final theme = Theme.of(tester.element(quantityToggleFinder));

    expect(decoration.color, theme.colorScheme.surface);
    expect(quantityText.style?.color, theme.textTheme.bodyLarge?.color);
    expect(iconButtons[0].color, theme.colorScheme.onSurface);
    expect(iconButtons[1].color, theme.colorScheme.onSurface);
  });

  testWidgets('CategoryChip uses dark theme text for unselected state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildDarkHarness(const Scaffold(body: CategoryChip(label: 'Produce'))),
    );
    await tester.pumpAndSettle();

    final label = tester.widget<Text>(
      find.descendant(
        of: find.byType(CategoryChip),
        matching: find.byType(Text),
      ),
    );
    final theme = Theme.of(tester.element(find.byType(CategoryChip)));

    expect(label.style?.color, theme.textTheme.labelLarge?.color);
  });

  group('M4/296 dark token wiring', () {
    testWidgets('dark text styles resolve to shared dark palette tokens', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildDarkHarness(
          const Scaffold(
            body: Text('Dark text sample', key: Key('dark_text_sample')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final theme = Theme.of(tester.element(find.byKey(const Key('dark_text_sample'))));

      expect(theme.textTheme.bodyMedium?.color, app_palette.AppColors.textPrimaryDark);
      expect(theme.textTheme.bodySmall?.color, app_palette.AppColors.textSecondaryDark);
      expect(theme.textTheme.labelSmall?.color, app_palette.AppColors.textTertiaryDark);
    });

    testWidgets('dark input decoration uses dark surfaces and borders', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildDarkHarness(
          const Scaffold(
            body: TextField(
              key: Key('dark_text_field'),
              decoration: InputDecoration(labelText: 'Name'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final theme = Theme.of(tester.element(find.byKey(const Key('dark_text_field'))));

      expect(theme.inputDecorationTheme.fillColor, app_palette.AppColors.backgroundSecondaryDark);
      expect(
        theme.inputDecorationTheme.enabledBorder?.borderSide.color,
        app_palette.AppColors.borderDark,
      );
      expect(theme.inputDecorationTheme.labelStyle?.color, app_palette.AppColors.textSecondaryDark);
    });

    testWidgets('dark scaffold, card, and divider use shared surface tokens', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildDarkHarness(
          const Scaffold(
            body: Card(child: SizedBox(height: 20, width: 20)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final theme = Theme.of(tester.element(find.byType(Card)));

      expect(theme.scaffoldBackgroundColor, app_palette.AppColors.backgroundDark);
      expect(theme.cardColor, app_palette.AppColors.cardBackgroundDark);
      expect(theme.dividerColor, app_palette.AppColors.borderDark);
    });

    testWidgets('dark bottom navigation uses shared surface and text tokens', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildDarkHarness(
          Scaffold(
            bottomNavigationBar: BottomNavigationBar(
              items: [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final theme = Theme.of(tester.element(find.byType(BottomNavigationBar)));

      expect(
        theme.bottomNavigationBarTheme.backgroundColor,
        app_palette.AppColors.backgroundSecondaryDark,
      );
      expect(
        theme.bottomNavigationBarTheme.unselectedItemColor,
        app_palette.AppColors.textTertiaryDark,
      );
    });
  });
}
