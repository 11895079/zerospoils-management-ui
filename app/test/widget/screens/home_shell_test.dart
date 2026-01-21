// Widget tests for HomeShell navigation
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerospoils/presentation/screens/home_shell.dart';

void main() {
  testWidgets('Tab navigation switches between screens', (
    WidgetTester tester,
  ) async {
    // Build the HomeShell widget
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HomeShell())),
    );

    await tester.pumpAndSettle();

    // Verify we start on Inventory tab
    expect(find.text('Inventory'), findsWidgets);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    // Tap on Expiring tab
    await tester.tap(find.text('Expiring'));
    await tester.pumpAndSettle();

    // Verify Expiring screen is shown (allow multiple matches for title + tab label)
    expect(find.text('Expiring Soon'), findsWidgets);
    expect(find.byType(FloatingActionButton), findsNothing);

    // Tap on Shopping tab
    await tester.tap(find.text('Shopping'));
    await tester.pumpAndSettle();

    // Verify Shopping List screen is shown
    expect(find.text('Shopping List'), findsWidgets);
    expect(find.byType(FloatingActionButton), findsNothing);

    // Tap on Settings tab
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    // Verify Settings screen is shown
    expect(find.text('Settings'), findsWidgets);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('Inventory screen displays Add Item FAB', (
    WidgetTester tester,
  ) async {
    // Build the HomeShell widget
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HomeShell())),
    );

    await tester.pumpAndSettle();

    // Verify Inventory screen (tab 0) is visible with FAB
    expect(find.text('Inventory'), findsWidgets);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('Add Item'), findsOneWidget);

    // Switch to Settings tab (tab 3)
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    // Verify Settings screen is shown without FAB
    expect(find.text('Settings'), findsWidgets);
    expect(find.byType(FloatingActionButton), findsNothing);

    // Switch back to Inventory tab (tab 0)
    await tester.tap(find.byIcon(Icons.inventory_2));
    await tester.pumpAndSettle();

    // Verify FAB is back
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('Add Item'), findsOneWidget);
  });
}
