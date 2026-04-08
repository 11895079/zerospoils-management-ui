import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:zerospoils/core/feature_flags/feature_flag_key.dart';
import 'package:zerospoils/core/feature_flags/feature_flags_provider.dart';
import 'package:zerospoils/core/ocr/expiry_date_ocr_service.dart';
import 'package:zerospoils/domain/models/user_category.dart';
import 'package:zerospoils/domain/utils/expiry_date_parser.dart';
import 'package:zerospoils/presentation/di/repository_providers.dart';
import 'package:zerospoils/presentation/ocr/expiry_ocr_capture_launcher.dart';
import 'package:zerospoils/presentation/screens/item_form_screen.dart';

class FakeExpiryOcrCaptureLauncher {
  FakeExpiryOcrCaptureLauncher(this.result);

  final ExpiryDateOcrScanResult result;
  int callCount = 0;
  String? lastPreferredDateFormat;

  Future<ExpiryDateOcrScanResult> call({
    required BuildContext context,
    required String preferredDateFormat,
  }) async {
    callCount++;
    lastPreferredDateFormat = preferredDateFormat;
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
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    try {
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
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets(
    'expiry OCR button shows when feature flag resolves true on mobile',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              isFlagEnabledProvider(
                FeatureFlagKey.expiryDateOcr,
              ).overrideWith((ref) async => true),
            ],
            child: const MaterialApp(home: ItemFormScreen()),
          ),
        );

        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('expiry_date_scan_button')),
          findsOneWidget,
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets('expiry OCR button stays hidden while flag is loading', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final completer = Completer<bool>();

    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isFlagEnabledProvider(
              FeatureFlagKey.expiryDateOcr,
            ).overrideWith((ref) => completer.future),
          ],
          child: const MaterialApp(home: ItemFormScreen()),
        ),
      );

      await tester.pump();
      expect(find.byKey(const Key('expiry_date_scan_button')), findsNothing);

      completer.complete(true);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('expiry_date_scan_button')), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('guidance dialog opens and OCR result pre-fills expiry date', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeLauncher = FakeExpiryOcrCaptureLauncher(
      ExpiryDateOcrScanResult.success(
        ExpiryDateParseResult(
          date: DateTime(2026, 1, 15),
          format: 'MM/DD/YYYY',
        ),
      ),
    );

    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isFlagEnabledProvider(
              FeatureFlagKey.expiryDateOcr,
            ).overrideWith((ref) async => true),
            dateFormatPreferenceProvider.overrideWith(
              (ref) async => 'DD/MM/YYYY',
            ),
            expiryOcrCaptureLauncherProvider.overrideWithValue(
              fakeLauncher.call,
            ),
          ],
          child: const MaterialApp(home: ItemFormScreen()),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('expiry_date_scan_button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('expiry_ocr_guidance_dialog')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('expiry_ocr_guidance_continue')));
      await tester.pumpAndSettle();

      expect(fakeLauncher.callCount, 1);
      expect(fakeLauncher.lastPreferredDateFormat, 'DD/MM/YYYY');
      final expiryText = tester.widget<Text>(
        find.byKey(const Key('item_form_expiry_date_value')),
      );
      expect(expiryText.data, 'Expires: 2026-01-15');
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
