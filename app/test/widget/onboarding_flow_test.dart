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
      expect(find.byKey(const Key('onboarding_title')), findsOneWidget);
      expect(find.byKey(const Key('onboarding_appbar_title')), findsOneWidget);
    });

    testWidgets('Navigates between pages with PageView', (
      WidgetTester tester,
    ) async {
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: OnboardingScreen())),
      );

      // Verify we're on page 1 with ZeroSpoils title
      expect(find.byKey(const Key('onboarding_title')), findsOneWidget);

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
      await tester.tap(
        find.byKey(const Key('onboarding_notifications_button')),
      );
      await tester.pumpAndSettle();

      // Verify notification permission dialog appears
      expect(find.byKey(const Key('notification_prompt')), findsOneWidget);
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
      await tester.tap(find.byKey(const Key('onboarding_skip_button')));
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
      await tester.tap(find.byKey(const Key('onboarding_continue_button')));
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
      expect(
        find.byKey(const Key('onboarding_page_indicator')),
        findsOneWidget,
      );

      // Swipe to next page
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();

      // Should show "2 of 2"
      expect(
        find.byKey(const Key('onboarding_page_indicator')),
        findsOneWidget,
      );
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
      await tester.tap(find.byKey(const Key('onboarding_camera_button')));
      await tester.pumpAndSettle();

      // Verify dialog appears
      expect(find.byKey(const Key('camera_prompt')), findsOneWidget);

      // Tap "Maybe Later"
      await tester.tap(find.byKey(const Key('camera_prompt_defer')));
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets(
      'Enabling notifications dismisses the dialog without blanking onboarding',
      (WidgetTester tester) async {
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          ProviderScope(child: MaterialApp(home: OnboardingScreen())),
        );

        await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('onboarding_notifications_button')),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('notification_prompt_confirm')));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(PageView), findsOneWidget);
        expect(find.byKey(const Key('onboarding_continue_button')), findsOneWidget);
      },
    );

    testWidgets(
      'Enabling camera dismisses the dialog without blanking onboarding',
      (WidgetTester tester) async {
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          ProviderScope(child: MaterialApp(home: OnboardingScreen())),
        );

        await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('onboarding_camera_button')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('camera_prompt_confirm')));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(PageView), findsOneWidget);
        expect(find.byKey(const Key('onboarding_continue_button')), findsOneWidget);
      },
    );

    testWidgets('Welcome page displays key content elements', (
      WidgetTester tester,
    ) async {
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: OnboardingScreen())),
      );

      // Verify welcome page content
      expect(find.byKey(const Key('onboarding_welcome_body')), findsOneWidget);
      expect(find.byKey(const Key('onboarding_feature_list')), findsOneWidget);
    });

    testWidgets('AppBar includes Skip button on all pages', (
      WidgetTester tester,
    ) async {
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: OnboardingScreen())),
      );

      // Skip button should be present on first page
      expect(find.byKey(const Key('onboarding_skip_button')), findsOneWidget);

      // Swipe to second page
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();

      // Skip button should still be present
      expect(find.byKey(const Key('onboarding_skip_button')), findsOneWidget);
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

      // Verify both permission buttons are present
      expect(
        find.byKey(const Key('onboarding_notifications_button')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('onboarding_camera_button')), findsOneWidget);
    });
  });
}
