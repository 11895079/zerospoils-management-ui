import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerospoils/presentation/themes/app_theme.dart';
import 'package:zerospoils/presentation/screens/onboarding_screen.dart';

const openOnboardingButtonKey = Key('open_onboarding_button');

class _TestNavigatorObserver extends NavigatorObserver {
  int popCount = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    popCount++;
    super.didPop(route, previousRoute);
  }
}

Future<void> _goToPermissionsPage(WidgetTester tester) async {
  final target = find.byKey(const Key('onboarding_notifications_button'));
  for (var i = 0; i < 8; i++) {
    if (target.evaluate().isNotEmpty) {
      return;
    }
    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
  }

  throw StateError('Could not reach permissions page');
}

Future<void> _revealContinueButton(WidgetTester tester) async {
  final continueFinder = find.byKey(const Key('onboarding_continue_button'));
  for (var i = 0; i < 6; i++) {
    if (continueFinder.evaluate().isNotEmpty) {
      return;
    }
    await tester.drag(
      find.byKey(const Key('onboarding_notifications_button')),
      const Offset(0, -240),
    );
    await tester.pumpAndSettle();
  }
}

void main() {
  Future<void> goToWorkflowPage(WidgetTester tester) async {
    final target = find.byKey(
      const Key('onboarding_open_shared_guidance_button'),
    );
    for (var i = 0; i < 6; i++) {
      if (target.evaluate().isNotEmpty) {
        return;
      }
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();
    }

    throw StateError('Could not reach workflow page');
  }

  group('OnboardingScreen', () {
    setUpAll(() {
      SharedPreferences.setMockInitialValues({});
    });

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    ThemeData noSplashTheme([Brightness brightness = Brightness.light]) {
      return ThemeData(
        brightness: brightness,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
      );
    }

    testWidgets('Emits onboarding_started event on first load', (
      WidgetTester tester,
    ) async {
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(theme: noSplashTheme(), home: OnboardingScreen()),
        ),
      );

      // Verify welcome screen is shown
      expect(find.byKey(const Key('onboarding_title')), findsOneWidget);
      expect(find.byKey(const Key('onboarding_appbar_title')), findsOneWidget);
    });

    testWidgets('Uses dark theme colors in dark mode', (
      WidgetTester tester,
    ) async {
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: const OnboardingScreen(),
          ),
        ),
      );

      final theme = Theme.of(tester.element(find.byType(OnboardingScreen)));
      final title = tester.widget<Text>(
        find.byKey(const Key('onboarding_title')),
      );
      final skipButton = tester.widget<TextButton>(
        find.byKey(const Key('onboarding_skip_button')),
      );

      expect(theme.brightness, Brightness.dark);
      expect(title.style?.color, theme.textTheme.headlineLarge?.color);
      expect(
        skipButton.style?.foregroundColor?.resolve({}),
        theme.appBarTheme.foregroundColor,
      );
    });

    testWidgets('Navigates between pages with PageView', (
      WidgetTester tester,
    ) async {
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(theme: noSplashTheme(), home: OnboardingScreen()),
        ),
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
        ProviderScope(
          child: MaterialApp(theme: noSplashTheme(), home: OnboardingScreen()),
        ),
      );

      // Navigate to permissions page (page 6 of 6)
      await _goToPermissionsPage(tester);

      // Tap notification permission button
      tester
          .widget<ElevatedButton>(
            find.byKey(const Key('onboarding_notifications_button')),
          )
          .onPressed!();
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
          child: MaterialApp(
            theme: noSplashTheme(),
            home: Scaffold(body: OnboardingScreen()),
          ),
        ),
      );

      // Tap skip button
      tester
          .widget<TextButton>(find.byKey(const Key('onboarding_skip_button')))
          .onPressed!();
      await tester.pumpAndSettle();

      // Verify that onboarding screen persists onboarding_complete flag
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_complete'), true);
    });

    testWidgets('Workflow page opens shared Zesto guidance screen', (
      WidgetTester tester,
    ) async {
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(theme: noSplashTheme(), home: OnboardingScreen()),
        ),
      );

      await goToWorkflowPage(tester);

      tester
          .widget<OutlinedButton>(
            find.byKey(const Key('onboarding_open_shared_guidance_button')),
          )
          .onPressed!();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('screen_zesto_guidance')), findsOneWidget);
      expect(find.byKey(const Key('zesto_guidance_character')), findsOneWidget);

      final acknowledgeButton = find.byKey(
        const Key('zesto_section_viewed_add_what_came_home'),
      );
      expect(acknowledgeButton, findsOneWidget);

      tester.widget<ButtonStyleButton>(acknowledgeButton).onPressed!();
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('zesto_section_ack_icon_add_what_came_home')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('zesto_section_ack_message_add_what_came_home')),
        findsOneWidget,
      );
    });

    testWidgets(
      'Zesto companion appears across onboarding pages with contextual icons',
      (WidgetTester tester) async {
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: noSplashTheme(),
              home: OnboardingScreen(),
            ),
          ),
        );

        await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('onboarding_companion_problem')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('onboarding_problem_title')),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.qr_code_scanner), findsWidgets);

        await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
        await tester.pumpAndSettle();
        await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('onboarding_companion_workflow')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('onboarding_workflow_title')),
          findsOneWidget,
        );

        await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
        await tester.pumpAndSettle();
        await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('onboarding_companion_permissions')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('onboarding_permissions_title')),
          findsOneWidget,
        );
      },
    );

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
      await _revealContinueButton(tester);
      tester
          .widget<OutlinedButton>(
            find.byKey(const Key('onboarding_continue_button')),
          )
          .onPressed!();
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
            theme: noSplashTheme(),
            navigatorObservers: [observer],
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    key: openOnboardingButtonKey,
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

      await tester.tap(find.byKey(openOnboardingButtonKey));
      await tester.pumpAndSettle();

      tester
          .widget<TextButton>(find.byKey(const Key('onboarding_skip_button')))
          .onPressed!();
      await tester.pumpAndSettle();

      expect(observer.popCount, greaterThanOrEqualTo(1));
      expect(find.byKey(openOnboardingButtonKey), findsOneWidget);

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
            theme: noSplashTheme(),
            navigatorObservers: [observer],
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    key: openOnboardingButtonKey,
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

      await tester.tap(find.byKey(openOnboardingButtonKey));
      await tester.pumpAndSettle();

      await _goToPermissionsPage(tester);
      await _revealContinueButton(tester);
      tester
          .widget<OutlinedButton>(
            find.byKey(const Key('onboarding_continue_button')),
          )
          .onPressed!();
      await tester.pumpAndSettle();

      expect(observer.popCount, greaterThanOrEqualTo(1));
      expect(find.byKey(openOnboardingButtonKey), findsOneWidget);

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
      await _revealContinueButton(tester);

      tester
          .widget<OutlinedButton>(
            find.byKey(const Key('onboarding_continue_button')),
          )
          .onPressed!();
      await tester.pumpAndSettle();

      expect(find.text('home-screen-marker'), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_complete'), true);
    });

    testWidgets(
      'Skip dismisses onboarding when opened from nested navigator with GoRouter present',
      (WidgetTester tester) async {
        addTearDown(() => tester.view.resetPhysicalSize());

        const openNestedOnboardingKey = Key('open_nested_onboarding_button');
        final testRouter = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    key: openNestedOnboardingKey,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const OnboardingScreen(),
                        ),
                      );
                    },
                    child: const Text('Open nested onboarding'),
                  ),
                ),
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(child: MaterialApp.router(routerConfig: testRouter)),
        );
        await tester.pumpAndSettle();

        tester
            .widget<ElevatedButton>(find.byKey(openNestedOnboardingKey))
            .onPressed!();
        await tester.pumpAndSettle();

        tester
            .widget<TextButton>(find.byKey(const Key('onboarding_skip_button')))
            .onPressed!();
        await tester.pumpAndSettle();

        expect(find.byKey(openNestedOnboardingKey), findsOneWidget);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('onboarding_complete'), true);
      },
    );

    testWidgets(
      'Continue dismisses onboarding when opened from nested navigator with GoRouter present',
      (WidgetTester tester) async {
        addTearDown(() => tester.view.resetPhysicalSize());

        const openNestedOnboardingKey = Key('open_nested_onboarding_button');
        final testRouter = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    key: openNestedOnboardingKey,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const OnboardingScreen(),
                        ),
                      );
                    },
                    child: const Text('Open nested onboarding'),
                  ),
                ),
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(child: MaterialApp.router(routerConfig: testRouter)),
        );
        await tester.pumpAndSettle();

        tester
            .widget<ElevatedButton>(find.byKey(openNestedOnboardingKey))
            .onPressed!();
        await tester.pumpAndSettle();

        await _goToPermissionsPage(tester);
        await _revealContinueButton(tester);
        tester
            .widget<OutlinedButton>(
              find.byKey(const Key('onboarding_continue_button')),
            )
            .onPressed!();
        await tester.pumpAndSettle();

        expect(find.byKey(openNestedOnboardingKey), findsOneWidget);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('onboarding_complete'), true);
      },
    );

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
      tester
          .widget<ElevatedButton>(
            find.byKey(const Key('onboarding_camera_button')),
          )
          .onPressed!();
      await tester.pumpAndSettle();

      // Verify dialog appears
      expect(find.byKey(const Key('camera_prompt')), findsOneWidget);

      // Tap "Maybe Later"
      tester
          .widget<TextButton>(find.byKey(const Key('camera_prompt_defer')))
          .onPressed!();
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets(
      'Enabling notifications dismisses the dialog without blanking onboarding',
      (WidgetTester tester) async {
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: noSplashTheme(),
              home: OnboardingScreen(),
            ),
          ),
        );

        await _goToPermissionsPage(tester);

        tester
            .widget<ElevatedButton>(
              find.byKey(const Key('onboarding_notifications_button')),
            )
            .onPressed!();
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('notification_prompt_confirm')));
        await tester.pumpAndSettle();
        await _revealContinueButton(tester);

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
          ProviderScope(
            child: MaterialApp(
              theme: noSplashTheme(),
              home: OnboardingScreen(),
            ),
          ),
        );

        await _goToPermissionsPage(tester);

        tester
            .widget<ElevatedButton>(
              find.byKey(const Key('onboarding_camera_button')),
            )
            .onPressed!();
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('camera_prompt_confirm')));
        await tester.pumpAndSettle();
        await _revealContinueButton(tester);

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

      tester.widget<FilterChip>(jollofChipFinder).onSelected!(true);
      await tester.pumpAndSettle();

      chip = tester.widget<FilterChip>(jollofChipFinder);
      expect(chip.selected, isTrue);

      tester.widget<FilterChip>(jollofChipFinder).onSelected!(false);
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

      tester
          .widget<FilterChip>(
            find.byKey(const Key('onboarding_preset_chip_jollof_rice')),
          )
          .onSelected!(true);
      await tester.pumpAndSettle();
      tester
          .widget<FilterChip>(
            find.byKey(const Key('onboarding_preset_chip_curry')),
          )
          .onSelected!(true);
      await tester.pumpAndSettle();

      await _revealContinueButton(tester);
      tester
          .widget<OutlinedButton>(
            find.byKey(const Key('onboarding_continue_button')),
          )
          .onPressed!();
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

        // Initially, notification button should show the notifications icon.
        final notificationButton = find.byKey(
          const Key('onboarding_notifications_button'),
        );
        expect(notificationButton, findsOneWidget);
        expect(
          find.descendant(
            of: notificationButton,
            matching: find.byIcon(Icons.notifications),
          ),
          findsOneWidget,
        );
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

      // Initially, camera button should show the camera icon.
      final cameraButton = find.byKey(const Key('onboarding_camera_button'));
      expect(cameraButton, findsOneWidget);
      expect(
        find.descendant(
          of: cameraButton,
          matching: find.byIcon(Icons.camera_alt),
        ),
        findsOneWidget,
      );
    });
  });
}
