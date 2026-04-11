import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerospoils/domain/models/receipt_line_item.dart';
import 'package:zerospoils/presentation/screens/receipt_live_scan_screen.dart';
import 'package:zerospoils/presentation/themes/app_theme.dart';

void main() {
  testWidgets('live receipt scan screen renders AR overlay boxes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const ReceiptLiveScanScreen(
          skipCameraInitialization: true,
          debugImageSize: Size(320, 640),
          debugOverlayItems: [
            ReceiptLineItem(
              name: 'PREMIUM BANANA',
              price: 2.07,
              ocrBox: ReceiptOcrBox(
                left: 24,
                top: 160,
                right: 300,
                bottom: 214,
              ),
            ),
            ReceiptLineItem(
              name: '12 GRAIN BREAD',
              price: 4.19,
              ocrBox: ReceiptOcrBox(
                left: 20,
                top: 300,
                right: 280,
                bottom: 352,
              ),
            ),
          ],
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('receipt_live_scan_overlay')), findsOneWidget);
    expect(find.byKey(const Key('receipt_live_overlay_box_0')), findsOneWidget);
    expect(find.byKey(const Key('receipt_live_overlay_box_1')), findsOneWidget);
    expect(find.text('PREMIUM BANANA'), findsOneWidget);
    expect(find.text('12 GRAIN BREAD'), findsOneWidget);
  });
}
