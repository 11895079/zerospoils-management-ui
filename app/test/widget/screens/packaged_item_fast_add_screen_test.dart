// Widget tests for PackagedItemFastAddScreen
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zerospoils/presentation/screens/packaged_item_fast_add_screen.dart';
import 'package:zerospoils/presentation/themes/app_theme.dart';

Widget _wrapWithApp(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PackagedItemFastAddScreen — stage navigation', () {
    testWidgets('opens on barcode scanning stage and shows step label', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapWithApp(const PackagedItemFastAddScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fast_add_stage_label')), findsOneWidget);
      expect(find.byKey(const Key('fast_add_status_card')), findsOneWidget);
      expect(
        find.byKey(const Key('fast_add_no_barcode_button')),
        findsOneWidget,
      );
    });

    testWidgets('Skip Barcode button advances to expiry capture stage', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapWithApp(const PackagedItemFastAddScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('fast_add_skip_barcode')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('fast_add_expiry_status_card')),
        findsOneWidget,
      );
    });

    testWidgets('No Barcode button advances to expiry capture stage', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapWithApp(const PackagedItemFastAddScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('fast_add_no_barcode_button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('fast_add_expiry_status_card')),
        findsOneWidget,
      );
    });

    testWidgets('Scan Package Label advances to package label stage', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapWithApp(const PackagedItemFastAddScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('fast_add_package_label_button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('fast_add_package_label_card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('fast_add_package_name_field')),
        findsOneWidget,
      );
    });

    testWidgets('Cancel button pops the route from the initial barcode stage', (
      tester,
    ) async {
      bool popped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ProviderScope(
            child: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.of(context)
                        .push<PackagedItemFastAddResult>(
                          MaterialPageRoute(
                            builder: (_) => const PackagedItemFastAddScreen(),
                          ),
                        );
                    if (result != null && !result.isSuccess) {
                      popped = true;
                    }
                  },
                  key: const Key('open_fast_add_button'),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('open_fast_add_button')));
      await tester.pumpAndSettle();

      // Tap Cancel on barcode screen
      await tester.tap(find.byKey(const Key('fast_add_initial_cancel_button')));
      await tester.pumpAndSettle();

      expect(popped, isTrue);
    });
  });

  group('PackagedItemFastAddScreen — barcode miss flow', () {
    testWidgets(
      'barcode miss stage shows product-not-found card and name field',
      (tester) async {
        await tester.pumpWidget(
          _wrapWithApp(const PackagedItemFastAddScreen()),
        );
        await tester.pumpAndSettle();

        // Skip barcode → expiry, then navigate to confirm with empty name
        await tester.tap(find.byKey(const Key('fast_add_skip_barcode')));
        await tester.pumpAndSettle();

        // Skip expiry
        await tester.tap(find.byKey(const Key('fast_add_skip_expiry_button')));
        await tester.pumpAndSettle();

        // Should be on confirm stage with empty name
        expect(find.byKey(const Key('fast_add_stage_label')), findsOneWidget);
        expect(
          find.byKey(const Key('fast_add_confirm_name_field')),
          findsOneWidget,
        );
      },
    );

    testWidgets('save button disabled when name is empty', (tester) async {
      await tester.pumpWidget(_wrapWithApp(const PackagedItemFastAddScreen()));
      await tester.pumpAndSettle();

      // Navigate to confirm without entering a name
      await tester.tap(find.byKey(const Key('fast_add_skip_barcode')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('fast_add_skip_expiry_button')));
      await tester.pumpAndSettle();

      final saveButton = tester.widget<FilledButton>(
        find.byKey(const Key('fast_add_save_button')),
      );
      expect(saveButton.onPressed, isNull);
    });
  });

  group('PackagedItemFastAddScreen — confirm stage', () {
    testWidgets('category dropdown shows all categories', (tester) async {
      await tester.pumpWidget(_wrapWithApp(const PackagedItemFastAddScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('fast_add_skip_barcode')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('fast_add_skip_expiry_button')));
      await tester.pumpAndSettle();

      // Open dropdown
      await tester.tap(find.byKey(const Key('fast_add_category_dropdown')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('fast_add_category_dropdown')),
        findsOneWidget,
      );
    });

    testWidgets('Add Expiry Date button returns to expiry capture', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapWithApp(const PackagedItemFastAddScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('fast_add_skip_barcode')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('fast_add_skip_expiry_button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('fast_add_add_expiry_button')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('fast_add_add_expiry_button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('fast_add_expiry_status_card')),
        findsOneWidget,
      );
    });
  });

  group('PackagedItemFastAddScreen — package label extraction', () {
    testWidgets(
      'extracting package label text prefills name and locks expiry',
      (tester) async {
        await tester.pumpWidget(
          _wrapWithApp(const PackagedItemFastAddScreen()),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('fast_add_package_label_button')),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('fast_add_package_label_text_field')),
          'ATLANTIC SALMON FILLET\n'
          '0.742 KG @ 24.99/KG\n'
          'TOTAL 18.54\n'
          'BEST BEFORE 04/24/2026',
        );
        await tester.tap(
          find.byKey(const Key('fast_add_package_extract_button')),
        );
        await tester.pumpAndSettle();

        final nameField = tester.widget<TextField>(
          find.byKey(const Key('fast_add_package_name_field')),
        );
        expect(nameField.controller?.text, 'Atlantic Salmon Fillet');
        expect(
          find.byKey(const Key('fast_add_package_extracted_summary')),
          findsOneWidget,
        );

        final continueButton = find.byKey(
          const Key('fast_add_package_label_continue'),
        );
        await tester.ensureVisible(continueButton);
        await tester.tap(continueButton);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('fast_add_expiry_locked_card')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('fast_add_locked_expiry_label')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'keeps existing manual name when extracted label name conflicts',
      (tester) async {
        await tester.pumpWidget(
          _wrapWithApp(const PackagedItemFastAddScreen()),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('fast_add_package_label_button')),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('fast_add_package_name_field')),
          'Rotisserie Chicken',
        );
        await tester.enterText(
          find.byKey(const Key('fast_add_package_label_text_field')),
          'ATLANTIC SALMON FILLET\n'
          '0.742 KG @ 24.99/KG\n'
          'TOTAL 18.54\n'
          'BEST BEFORE 04/24/2026',
        );

        await tester.tap(
          find.byKey(const Key('fast_add_package_extract_button')),
        );
        await tester.pumpAndSettle();

        final nameField = tester.widget<TextField>(
          find.byKey(const Key('fast_add_package_name_field')),
        );
        expect(nameField.controller?.text, 'Rotisserie Chicken');
      },
    );

    testWidgets(
      'saving after extraction returns detected price and weight values',
      (tester) async {
        PackagedItemFastAddResult? savedResult;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    key: const Key('open_fast_add_for_save_test'),
                    onPressed: () async {
                      savedResult = await Navigator.of(context)
                          .push<PackagedItemFastAddResult>(
                            MaterialPageRoute(
                              builder: (_) => const PackagedItemFastAddScreen(),
                            ),
                          );
                    },
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.byKey(const Key('open_fast_add_for_save_test')));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('fast_add_package_label_button')),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('fast_add_package_label_text_field')),
          'ATLANTIC SALMON FILLET\n'
          '0.742 KG @ 24.99/KG\n'
          'TOTAL 18.54\n'
          'BEST BEFORE 04/24/2026',
        );
        await tester.tap(
          find.byKey(const Key('fast_add_package_extract_button')),
        );
        await tester.pumpAndSettle();

        final continueButton = find.byKey(
          const Key('fast_add_package_label_continue'),
        );
        await tester.ensureVisible(continueButton);
        await tester.tap(continueButton);
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('fast_add_expiry_locked_continue')),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('fast_add_save_button')));
        await tester.pumpAndSettle();

        expect(savedResult, isNotNull);
        expect(savedResult!.isSuccess, isTrue);
        expect(savedResult!.purchasePrice, closeTo(18.54, 0.001));
        expect(savedResult!.packageWeightValue, closeTo(0.742, 0.0001));
      },
    );
  });
}
