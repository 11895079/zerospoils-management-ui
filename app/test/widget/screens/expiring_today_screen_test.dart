import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerospoils/presentation/screens/expiring_today_screen.dart';

void main() {
  group('ExpiringTodayScreen', () {
    testWidgets('renders without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: ExpiringTodayScreen())),
      );
      expect(find.byType(ExpiringTodayScreen), findsOneWidget);
    });

    testWidgets('displays screen content', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: ExpiringTodayScreen())),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));
      // Verify screen rendered successfully
      expect(find.byType(ExpiringTodayScreen), findsOneWidget);
    });
  });
}
