import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerospoils/presentation/screens/developer_settings_screen.dart';

void main() {
  group('DeveloperSettingsScreen', () {
    testWidgets('renders without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: Scaffold(body: DeveloperSettingsScreen())),
        ),
      );

      // Just verify it builds, don't wait for async loading
      await tester.pump();
      expect(find.text('Developer Settings'), findsOneWidget);
    });

    testWidgets('displays title', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: Scaffold(body: DeveloperSettingsScreen())),
        ),
      );

      await tester.pump();
      expect(find.text('Developer Settings'), findsOneWidget);
    });

    testWidgets('shows loading indicator initially', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: Scaffold(body: DeveloperSettingsScreen())),
        ),
      );

      await tester.pump();
      // Should show loading spinner while providers resolve
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
