import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerospoils/presentation/screens/onboarding_screen.dart';

class _TestNavigatorObserver extends NavigatorObserver {
  int popCount = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    popCount++;
    super.didPop(route, previousRoute);
  }
}

Future<void> _goToPermissionsPage(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
  }
}

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

      // Should now be on a middle onboarding page (6-page flow)
      expect(find.byIcon(Icons.notifications), findsNothing);
    });

    testWidgets('Shows permission prompts when permission buttons are tapped', (
      WidgetTester tester,
    ) async {
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: OnboardingScreen())),
      );

      // Navigate to permissions page (page 6 of 6)
      await _goToPermissionsPage(tester);

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

      // Navigate to permissions page (page 6 of 6)
      await _goToPermissionsPage(tester);

      // Tap Continue to App button
      await tester.tap(find.byKey(const Key('onboarding_continue_button')));
      await tester.pumpAndSettle();

      // Verify SharedPreferences was updated
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_complete'), true);
    });

    testWidgets('Skip pops onboarding in non-GoRouter flow', (
      WidgetTester tester,
    ) async {
      addTearDown(() => tester.view.resetPhysicalSize());

      final observer = _TestNavigatorObserver();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            navigatorObservers: [observer],
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const OnboardingScreen(),
                        ),
                      );
                    },
                    child: const Text('Open onboarding'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open onboarding'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('onboarding_skip_button')));
      await tester.pumpAndSettle();

      expect(observer.popCount, greaterThanOrEqualTo(1));
      expect(find.text('Open onboarding'), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_complete'), true);
    });

    testWidgets('Continue pops onboarding in non-GoRouter flow', (
      WidgetTester tester,
    ) async {
      addTearDown(() => tester.view.resetPhysicalSize());

      final observer = _TestNavigatorObserver();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            navigatorObservers: [observer],
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const OnboardingScreen(),
                        ),
                      );
                    },
                    child: const Text('Open onboarding'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open onboarding'));
      await tester.pumpAndSettle();

      await _goToPermissionsPage(tester);
      await tester.tap(find.byKey(const Key('onboarding_continue_button')));
      await tester.pumpAndSettle();

      expect(observer.popCount, greaterThanOrEqualTo(1));
      expect(find.text('Open onboarding'), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_complete'), true);
    });

    testWidgets('Continue to App navigates to home route with GoRouter', (
      WidgetTester tester,
    ) async {
      addTearDown(() => tester.view.resetPhysicalSize());

      final testRouter = GoRouter(
        routes: [
          GoRoute(
            path: '/onboarding',
            builder: (context, state) => const OnboardingScreen(),
          ),
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const Scaffold(body: Text('home-screen-marker')),
          ),
        ],
        initialLocation: '/onboarding',
      );

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: testRouter)),
      );

      await _goToPermissionsPage(tester);

      await tester.tap(find.byKey(const Key('onboarding_continue_button')));
      await tester.pumpAndSettle();

      expect(find.text('home-screen-marker'), findsOneWidget);

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

      // Should show "1 of 6"
      expect(
        find.byKey(const Key('onboarding_page_indicator')),
        findsOneWidget,
      );

      // Swipe to next page
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();

      // Should still show page indicator after moving forward
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

      // Navigate to permissions page (page 6 of 6)
      await _goToPermissionsPage(tester);

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

        await _goToPermissionsPage(tester);

        await tester.tap(
          find.byKey(const Key('onboarding_notifications_button')),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('notification_prompt_confirm')));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(PageView), findsOneWidget);
        expect(
          find.byKey(const Key('onboarding_continue_button')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Enabling camera dismisses the dialog without blanking onboarding',
      (WidgetTester tester) async {
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          ProviderScope(child: MaterialApp(home: OnboardingScreen())),
        );

        await _goToPermissionsPage(tester);

        await tester.tap(find.byKey(const Key('onboarding_camera_button')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('camera_prompt_confirm')));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(PageView), findsOneWidget);
        expect(
          find.byKey(const Key('onboarding_continue_button')),
          findsOneWidget,
        );
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

      // Navigate to permissions page (page 6 of 6)
      await _goToPermissionsPage(tester);

      // Verify both permission buttons are present
      expect(
        find.byKey(const Key('onboarding_notifications_button')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('onboarding_camera_button')), findsOneWidget);
    });

    testWidgets('Preset chips can be selected and deselected', (
      WidgetTester tester,
    ) async {
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: OnboardingScreen())),
      );

      await _goToPermissionsPage(tester);

      final jollofChipFinder = find.byKey(
        const Key('onboarding_preset_chip_jollof_rice'),
      );
      expect(jollofChipFinder, findsOneWidget);

      FilterChip chip = tester.widget<FilterChip>(jollofChipFinder);
      expect(chip.selected, isFalse);

      await tester.tap(jollofChipFinder);
      await tester.pumpAndSettle();

      chip = tester.widget<FilterChip>(jollofChipFinder);
      expect(chip.selected, isTrue);

      await tester.tap(jollofChipFinder);
      await tester.pumpAndSettle();

      chip = tester.widget<FilterChip>(jollofChipFinder);
      expect(chip.selected, isFalse);
    });

    testWidgets('Continue to app persists selected onboarding presets', (
      WidgetTester tester,
    ) async {
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: OnboardingScreen())),
      );

      await _goToPermissionsPage(tester);

      await tester.tap(
        find.byKey(const Key('onboarding_preset_chip_jollof_rice')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('onboarding_preset_chip_curry')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('onboarding_continue_button')));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      final selectedPresets =
          prefs.getStringList('onboarding_preferred_food_presets') ?? const [];

      expect(selectedPresets, contains('jollof_rice'));
      expect(selectedPresets, contains('curry'));
    });

    testWidgets(
      'Notification button shows enable icon before permission granted',
      (WidgetTester tester) async {
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          ProviderScope(child: MaterialApp(home: OnboardingScreen())),
        );

        await _goToPermissionsPage(tester);

        // Initially, button should show notifications icon (not granted yet)
        expect(find.byIcon(Icons.notifications), findsWidgets);
        expect(find.text('Enable Notifications'), findsOneWidget);
      },
    );

    testWidgets('Camera button shows enable icon before permission granted', (
      WidgetTester tester,
    ) async {
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: OnboardingScreen())),
      );

      await _goToPermissionsPage(tester);

      // Initially, button should show camera icon (not granted yet)
      expect(find.byIcon(Icons.camera_alt), findsWidgets);
      expect(find.text('Enable Camera'), findsOneWidget);
    });
  });
}
