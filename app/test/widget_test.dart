// Basic widget test for ZeroSpoils app
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zerospoils/main.dart';

void main() {
  testWidgets('App launches and renders home screen', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const ProviderScope(child: ZeroSpoilsApp()));

    // Wait for async initialization
    await tester.pumpAndSettle();

    // Verify that the bottom navigation bar is rendered
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    // Verify all 4 tab labels are present (using short labels from BottomNavigationBar)
    expect(find.text('Inventory'), findsWidgets);
    expect(find.text('Expiring'), findsWidgets);
    expect(find.text('Shopping'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);

    // Verify floating action button is present on inventory tab
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
