// Widget test for ItemDetailScreen
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerospoils/presentation/screens/item_detail_screen.dart';

void main() {
  testWidgets('ItemDetailScreen renders with item ID', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ItemDetailScreen(itemId: '42')),
    );

    await tester.pumpAndSettle();

    expect(find.text('Item Details'), findsOneWidget);
    expect(find.text('Item ID: 42'), findsOneWidget);
  });
}
