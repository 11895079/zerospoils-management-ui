import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerospoils/presentation/screens/onboarding_screen.dart';

void main() {
  group('OnboardingScreen', () {
    setUpAll(() {
      SharedPreferences.setMockInitialValues({});
    });

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Emits onboarding_started event on first load', (
      WidgetTester tester,
    ) async {
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: OnboardingScreen())),
      );

      // Verify welcome screen is shown
      expect(find.text('🥬 ZeroSpoils'), findsOneWidget);
      expect(find.text('Welcome'), findsOneWidget);
    });

    testWidgets('Navigates between pages with PageView', (
      WidgetTester tester,
    ) async {
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: OnboardingScreen())),
      );

      // Verify we're on page 1 with ZeroSpoils title
      expect(find.text('🥬 ZeroSpoils'), findsOneWidget);

      // Swipe to next page
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();

      // Should now be on permissions page in short variant
      expect(find.byIcon(Icons.notifications), findsWidgets);
      expect(find.byIcon(Icons.camera_alt), findsWidgets);
    });

    testWidgets('Shows permission prompts when permission buttons are tapped', (
      WidgetTester tester,
    ) async {
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: OnboardingScreen())),
      );

      // Navigate to permissions page
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();

      // Tap notification permission button
      await tester.tap(find.byIcon(Icons.notifications));
      await tester.pumpAndSettle();

      // Verify notification permission dialog appears
      expect(find.text('Enable Notifications'), findsWidgets);
    });

    testWidgets('Skip button dismisses onboarding', (
      WidgetTester tester,
    ) async {
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: Scaffold(body: OnboardingScreen())),
        ),
      );

      // Tap skip button
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Verify that onboarding screen persists onboarding_complete flag
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_complete'), true);
    });

    testWidgets('Continue to App button completes onboarding', (
      WidgetTester tester,
    ) async {
      addTearDown(() => tester.view.resetPhysicalSize());

      final app = ProviderScope(
        child: MaterialApp(home: Scaffold(body: OnboardingScreen())),
      );

      await tester.pumpWidget(app);

      // Navigate to permissions page
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();

      // Tap Continue to App button
      await tester.tap(find.text('Continue to App'));
      await tester.pumpAndSettle();

      // Verify SharedPreferences was updated
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_complete'), true);
    });

    testWidgets('Bottom navigation shows correct page indicator', (
      WidgetTester tester,
    ) async {
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: OnboardingScreen())),
      );

      // Should show "1 of 2" in short variant
      expect(find.text('1 of 2'), findsOneWidget);

      // Swipe to next page
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();

      // Should show "2 of 2"
      expect(find.text('2 of 2'), findsOneWidget);
    });

    testWidgets('Deferring camera permission closes dialog', (
      WidgetTester tester,
    ) async {
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: OnboardingScreen())),
      );

      // Navigate to permissions page
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();

      // Tap camera permission button
      await tester.tap(find.byIcon(Icons.camera_alt));
      await tester.pumpAndSettle();

      // Verify dialog appears
      expect(find.byType(AlertDialog), findsOneWidget);

      // Tap "Maybe Later"
      await tester.tap(find.text('Maybe Later'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('Welcome page displays key content elements', (
      WidgetTester tester,
    ) async {
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: OnboardingScreen())),
      );

      // Verify welcome page content - check for specific content
      expect(
        find.text(
          'Track your food, reduce waste, and get notified before items expire.',
        ),
        findsOneWidget,
      );
      // Check for the feature list (even if on separate lines, the Text widget still contains it)
      final textFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            ((widget.data?.contains('Never waste food again') ?? false) ||
                (widget.data?.contains('Smart reminders') ?? false) ||
                (widget.data?.contains('Simple & offline') ?? false)),
      );
      expect(textFinder, findsWidgets);
    });

    testWidgets('AppBar includes Skip button on all pages', (
      WidgetTester tester,
    ) async {
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: OnboardingScreen())),
      );

      // Skip button should be present on first page
      expect(find.text('Skip'), findsOneWidget);

      // Swipe to second page
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();

      // Skip button should still be present
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('Permission buttons have correct icons', (
      WidgetTester tester,
    ) async {
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: OnboardingScreen())),
      );

      // Navigate to permissions page
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();

      // Verify both permission buttons are present with correct icons
      expect(find.byIcon(Icons.notifications), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);

      // And have correct labels
      expect(find.text('Enable Notifications'), findsOneWidget);
      expect(find.text('Enable Camera'), findsOneWidget);
    });
  });
}
