import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerospoils/domain/models/receipt_batch.dart';
import 'package:zerospoils/presentation/screens/receipt_batch_capture_screen.dart';
import 'package:zerospoils/presentation/screens/receipt_batch_review_screen.dart';
import 'package:zerospoils/presentation/themes/app_theme.dart';
import 'package:zerospoils/presentation/widgets/item_entry_sheet.dart';

Widget buildDarkHarness(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: child,
    ),
  );
}

void main() {
  testWidgets('Receipt capture screen uses dark theme surfaces', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildDarkHarness(
        const ReceiptBatchCaptureScreen(source: ReceiptBatchSource.inventory),
      ),
    );
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    final theme = Theme.of(
      tester.element(find.byType(ReceiptBatchCaptureScreen)),
    );

    expect(scaffold.backgroundColor, theme.scaffoldBackgroundColor);
    expect(
      appBar.backgroundColor ?? theme.appBarTheme.backgroundColor,
      theme.appBarTheme.backgroundColor,
    );
  });

  testWidgets('Receipt review screen uses dark theme surfaces', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildDarkHarness(
        ReceiptBatchReviewScreen(
          source: ReceiptBatchSource.inventory,
          photoPaths: const ['receipt-1.jpg'],
          parsedItems: [ParsedReceiptItem(name: 'Milk', price: 4.99)],
          batchId: 'batch-1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    final card = tester.widget<Card>(find.byType(Card).first);
    final editIcon = tester.widget<Icon>(find.byIcon(Icons.edit));
    final theme = Theme.of(
      tester.element(find.byType(ReceiptBatchReviewScreen)),
    );

    expect(
      appBar.backgroundColor ?? theme.appBarTheme.backgroundColor,
      theme.appBarTheme.backgroundColor,
    );
    expect(
      card.color ?? theme.cardTheme.color ?? theme.cardColor,
      theme.cardTheme.color ?? theme.cardColor,
    );
    expect(editIcon.color, theme.colorScheme.onSurfaceVariant);
  });

  testWidgets('Item entry sheet uses dark theme secondary text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildDarkHarness(
        const Scaffold(
          body: ItemEntrySheet(
            requireExpiry: true,
            sourceLabel: 'Receipt import',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final sourceText = tester.widget<Text>(
      find.byKey(const Key('item_entry_source_label')),
    );
    final saveButton = tester.widget<ElevatedButton>(
      find.byKey(const Key('item_entry_save')),
    );
    final theme = Theme.of(tester.element(find.byType(ItemEntrySheet)));

    expect(sourceText.style?.color, theme.textTheme.bodySmall?.color);
    expect(
      saveButton.style?.backgroundColor?.resolve({}),
      theme.colorScheme.primary,
    );
  });

  testWidgets('Dark theme provides high-contrast default icons', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildDarkHarness(const Scaffold(body: Icon(Icons.search))),
    );
    await tester.pumpAndSettle();

    final theme = Theme.of(tester.element(find.byType(Scaffold)));
    expect(theme.iconTheme.color, theme.colorScheme.onSurface);
  });
}
