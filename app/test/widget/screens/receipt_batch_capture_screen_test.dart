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

  testWidgets('goods photo section shows when flag is enabled', (tester) async {
    await pumpCaptureScreen(tester, batchPhotoEnabled: true);

    expect(
      find.byKey(const Key('receipt_batch_receipt_section')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('receipt_batch_goods_section')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('receipt_batch_add_goods_photo')),
      findsOneWidget,
    );
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
}
