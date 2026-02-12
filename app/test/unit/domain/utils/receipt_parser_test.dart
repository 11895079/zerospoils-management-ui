import 'package:flutter_test/flutter_test.dart';
import 'package:zerospoils/domain/utils/receipt_parser.dart';

void main() {
  group('ReceiptParser', () {
    test('parses line items and ignores totals/taxes', () {
      const raw = '''
Milk 4.99
Apples 3.49
HST 0.85
Total 9.33
''';

      final parser = ReceiptParser();
      final items = parser.parse(raw);

      expect(items.length, 2);
      expect(items[0].name.toLowerCase(), 'milk');
      expect(items[0].price, 4.99);
      expect(items[1].name.toLowerCase(), 'apples');
      expect(items[1].price, 3.49);
    });

    test('handles currency symbols and extra spacing', () {
      const raw = 'Chicken Breast   \$11.20\nSubtotal 11.20';
      final parser = ReceiptParser();
      final items = parser.parse(raw);

      expect(items.length, 1);
      expect(items[0].name.toLowerCase(), 'chicken breast');
      expect(items[0].price, 11.20);
    });
  });
}
