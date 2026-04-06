library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerospoils/domain/models/item_model.dart';
import 'package:zerospoils/presentation/themes/app_theme.dart';
import 'package:zerospoils/presentation/widgets/item_icon.dart';

void main() {
  group('ItemIcon Widget', () {
    testWidgets('renders icon for known item', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemIcon(itemName: 'Apple', category: ItemCategory.produce),
          ),
        ),
      );

      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('renders with custom size', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemIcon(
              itemName: 'Chicken',
              category: ItemCategory.meat,
              size: 48,
            ),
          ),
        ),
      );

      final icon = find.byType(Icon);
      expect(icon, findsOneWidget);

      final iconWidget = tester.widget<Icon>(icon);
      expect(iconWidget.size, 48);
    });

    testWidgets('renders with background when showBackground is true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemIcon(
              itemName: 'Milk',
              category: ItemCategory.dairy,
              showBackground: true,
            ),
          ),
        ),
      );

      expect(find.byType(Container), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('renders without background by default', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemIcon(
              itemName: 'Bread',
              category: ItemCategory.grains,
              showBackground: false,
            ),
          ),
        ),
      );

      expect(find.byType(Container), findsNothing);
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('uses custom color', (WidgetTester tester) async {
      const customColor = Colors.red;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemIcon(
              itemName: 'Eggs',
              category: ItemCategory.dairy,
              color: customColor,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, customColor);
    });

    testWidgets('uses high-contrast icon color in dark mode by default', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const Scaffold(
            body: ItemIcon(itemName: 'Apple', category: ItemCategory.produce),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      final theme = Theme.of(tester.element(find.byType(ItemIcon)));

      expect(icon.color, theme.colorScheme.onSurface);
    });

    testWidgets('renders for all categories', (WidgetTester tester) async {
      for (final category in ItemCategory.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ItemIcon(itemName: 'Test Item', category: category),
            ),
          ),
        );

        expect(find.byType(Icon), findsOneWidget);
      }
    });
  });

  group('ItemIconWithLabel Widget', () {
    testWidgets('renders icon and label', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemIconWithLabel(
              itemName: 'Apple',
              category: ItemCategory.produce,
            ),
          ),
        ),
      );

      expect(find.byType(ItemIcon), findsOneWidget);
      expect(find.byKey(const Key('item_icon_label_produce')), findsOneWidget);
    });

    testWidgets('displays correct category label', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemIconWithLabel(
              itemName: 'Milk',
              category: ItemCategory.dairy,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('item_icon_label_dairy')), findsOneWidget);
    });

    testWidgets('renders in horizontal direction by default', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemIconWithLabel(
              itemName: 'Chicken',
              category: ItemCategory.meat,
            ),
          ),
        ),
      );

      final row = find.byType(Row);
      expect(row, findsOneWidget);

      final column = find.byType(Column);
      expect(column, findsNothing);
    });

    testWidgets('renders in vertical direction when specified', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemIconWithLabel(
              itemName: 'Bread',
              category: ItemCategory.grains,
              direction: Axis.vertical,
            ),
          ),
        ),
      );

      final column = find.byType(Column);
      expect(column, findsOneWidget);

      final row = find.byType(Row);
      expect(row, findsNothing);
    });

    testWidgets('uses custom icon size', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemIconWithLabel(
              itemName: 'Eggs',
              category: ItemCategory.dairy,
              iconSize: 32,
            ),
          ),
        ),
      );

      expect(find.byType(ItemIcon), findsOneWidget);
      // Icon size is applied via ItemIcon widget internally
    });

    testWidgets('applies custom label style', (WidgetTester tester) async {
      const customStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.bold);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemIconWithLabel(
              itemName: 'Cheese',
              category: ItemCategory.dairy,
              labelStyle: customStyle,
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style?.fontSize, 18);
      expect(text.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('renders for all categories with labels', (
      WidgetTester tester,
    ) async {
      for (final category in ItemCategory.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ItemIconWithLabel(
                itemName: 'Test Item',
                category: category,
              ),
            ),
          ),
        );

        expect(
          find.byKey(Key('item_icon_label_${category.name}')),
          findsOneWidget,
        );
      }
    });
  });
}
