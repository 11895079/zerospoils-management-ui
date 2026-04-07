import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:zerospoils/core/feature_flags/feature_flag_key.dart';
import 'package:zerospoils/core/feature_flags/feature_flags_provider.dart';
import 'package:zerospoils/core/ocr/expiry_date_ocr_service.dart';
import 'package:zerospoils/domain/models/user_category.dart';
import 'package:zerospoils/domain/utils/expiry_date_parser.dart';
import 'package:zerospoils/presentation/screens/item_form_screen.dart';

class FakeExpiryDateOcrService implements ExpiryDateOcrService {
  FakeExpiryDateOcrService(this.result);

  final ExpiryDateOcrScanResult result;
  int callCount = 0;

  @override
  Future<ExpiryDateOcrScanResult> scanExpiryDate() async {
    callCount++;
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('item_form_test_');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(22)) {
      Hive.registerAdapter(UserCategoryAdapter());
    }
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('expiry OCR button hides when feature flag is disabled', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isFlagEnabledProvider(
            FeatureFlagKey.expiryDateOcr,
          ).overrideWith((ref) async => false),
        ],
        child: const MaterialApp(home: ItemFormScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('expiry_date_scan_button')), findsNothing);
  });

  testWidgets(
    'expiry OCR button shows by default on supported mobile platforms',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: ItemFormScreen())),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('expiry_date_scan_button')), findsOneWidget);
    },
  );

  testWidgets('guidance dialog opens and OCR result pre-fills expiry date', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeService = FakeExpiryDateOcrService(
      ExpiryDateOcrScanResult.success(
        ExpiryDateParseResult(
          date: DateTime(2026, 1, 15),
          format: 'MM/DD/YYYY',
        ),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expiryDateOcrServiceProvider.overrideWithValue(fakeService),
        ],
        child: const MaterialApp(home: ItemFormScreen()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('expiry_date_scan_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('expiry_ocr_guidance_dialog')), findsOneWidget);

    await tester.tap(find.byKey(const Key('expiry_ocr_guidance_continue')));
    await tester.pumpAndSettle();

    expect(fakeService.callCount, 1);
    expect(find.text('Expires: 2026-01-15'), findsOneWidget);
  });
}
