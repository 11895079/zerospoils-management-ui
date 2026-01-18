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

  testWidgets('Add item modal opens and closes', (WidgetTester tester) async {
    // Build the HomeShell widget
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HomeShell())),
    );

    await tester.pumpAndSettle();

    // Verify modal is not visible initially
    expect(find.text('Add Item'), findsNothing);

    // Tap the FAB to open modal
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Verify modal opened with correct text
    expect(find.text('Add Item'), findsOneWidget);
    expect(find.text('Item Name'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);

    // Tap Cancel to close modal
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Verify modal closed
    expect(find.text('Add Item'), findsNothing);
  });
}
