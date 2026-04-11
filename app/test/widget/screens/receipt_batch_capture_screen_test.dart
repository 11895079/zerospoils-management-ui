import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
    expect(find.text('Batch details'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
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

    expect(
      find.byKey(const Key('receipt_batch_live_scan_button')),
      findsOneWidget,
    );
  });
}
