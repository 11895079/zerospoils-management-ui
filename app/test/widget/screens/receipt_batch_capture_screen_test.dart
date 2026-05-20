import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerospoils/core/feature_flags/feature_flag_key.dart';
import 'package:zerospoils/core/feature_flags/feature_flags_provider.dart';
import 'package:zerospoils/domain/models/receipt_batch.dart';
import 'package:zerospoils/presentation/screens/receipt_batch_capture_screen.dart';
import 'package:zerospoils/presentation/themes/app_theme.dart';

void main() {
  Future<void> pumpCaptureScreen(
    WidgetTester tester, {
    required bool batchPhotoEnabled,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isFlagEnabledProvider(
            FeatureFlagKey.receiptOcr,
          ).overrideWith((ref) async => true),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: ReceiptBatchCaptureScreen(
            source: ReceiptBatchSource.inventory,
            debugShowGoodsPhotosOverride: batchPhotoEnabled,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();
  }

  Future<void> pumpCaptureScreenWithFlags(
    WidgetTester tester, {
    required bool receiptOcrEnabled,
    required bool batchPhotoEnabled,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isFlagEnabledProvider(
            FeatureFlagKey.receiptOcr,
          ).overrideWith((ref) async => receiptOcrEnabled),
          isFlagEnabledProvider(
            FeatureFlagKey.batchPhotoCapture,
          ).overrideWith((ref) async => batchPhotoEnabled),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const ReceiptBatchCaptureScreen(
            source: ReceiptBatchSource.inventory,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();
  }

  testWidgets('goods photo section stays hidden when flag is disabled', (
    tester,
  ) async {
    await pumpCaptureScreen(tester, batchPhotoEnabled: false);

    expect(
      find.byKey(const Key('receipt_batch_receipt_section')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('receipt_batch_goods_section')), findsNothing);
    expect(
      find.byKey(const Key('receipt_batch_add_goods_photo')),
      findsNothing,
    );
  });

  testWidgets('capture screen renders when goods photo path is enabled', (
    tester,
  ) async {
    await pumpCaptureScreen(tester, batchPhotoEnabled: true);

    expect(
      find.byKey(const Key('receipt_batch_receipt_section')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('receipt_batch_details_heading')),
      findsOneWidget,
    );
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('batch section headings use dark theme text colors', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isFlagEnabledProvider(
            FeatureFlagKey.receiptOcr,
          ).overrideWith((ref) async => true),
          isFlagEnabledProvider(
            FeatureFlagKey.batchPhotoCapture,
          ).overrideWith((ref) async => true),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const ReceiptBatchCaptureScreen(
            source: ReceiptBatchSource.inventory,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    final heading = tester.widget<Text>(
      find.byKey(const Key('receipt_batch_details_heading')),
    );
    final theme = Theme.of(
      tester.element(find.byType(ReceiptBatchCaptureScreen)),
    );

    expect(heading.style?.color, theme.textTheme.headlineMedium?.color);
  });

  testWidgets('batch metadata fields are visible', (tester) async {
    await pumpCaptureScreen(tester, batchPhotoEnabled: false);

    expect(
      find.byKey(const Key('receipt_batch_store_name_field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('receipt_batch_purchase_date_field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('receipt_batch_total_amount_field')),
      findsOneWidget,
    );
  });

  testWidgets('live receipt scan button is visible on capture screen', (
    tester,
  ) async {
    await pumpCaptureScreen(tester, batchPhotoEnabled: false);

    await tester.scrollUntilVisible(
      find.byKey(const Key('receipt_batch_live_scan_button')),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(
      find.byKey(const Key('receipt_batch_live_scan_button')),
      findsOneWidget,
    );
  });

  testWidgets('live receipt scan button is hidden on desktop platforms', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    await pumpCaptureScreen(tester, batchPhotoEnabled: false);

    expect(
      find.byKey(const Key('receipt_batch_live_scan_button')),
      findsNothing,
    );

    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('review button stays disabled when receipt OCR flag is off', (
    tester,
  ) async {
    await pumpCaptureScreenWithFlags(
      tester,
      receiptOcrEnabled: false,
      batchPhotoEnabled: false,
    );

    expect(
      find.byKey(const Key('receipt_batch_ocr_disabled_notice')),
      findsOneWidget,
    );

    final reviewButton = tester.widget<ElevatedButton>(
      find.byKey(const Key('receipt_batch_review_button')),
    );
    expect(reviewButton.onPressed, isNull);
  });

  testWidgets('debug goods-photo override still respects receipt OCR flag', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isFlagEnabledProvider(
            FeatureFlagKey.receiptOcr,
          ).overrideWith((ref) async => false),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const ReceiptBatchCaptureScreen(
            source: ReceiptBatchSource.inventory,
            debugShowGoodsPhotosOverride: true,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('receipt_batch_ocr_disabled_notice')),
      findsOneWidget,
    );

    final reviewButton = tester.widget<ElevatedButton>(
      find.byKey(const Key('receipt_batch_review_button')),
    );
    expect(reviewButton.onPressed, isNull);
  });

  testWidgets('batch photo flag error does not force OCR gating off', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isFlagEnabledProvider(
            FeatureFlagKey.batchPhotoCapture,
          ).overrideWith((ref) async => throw Exception('failed to load')),
          isFlagEnabledProvider(
            FeatureFlagKey.receiptOcr,
          ).overrideWith((ref) async => true),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const ReceiptBatchCaptureScreen(
            source: ReceiptBatchSource.inventory,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('receipt_batch_ocr_disabled_notice')),
      findsNothing,
    );

    final reviewButton = tester.widget<ElevatedButton>(
      find.byKey(const Key('receipt_batch_review_button')),
    );
    expect(reviewButton.onPressed, isNotNull);
  });
}
