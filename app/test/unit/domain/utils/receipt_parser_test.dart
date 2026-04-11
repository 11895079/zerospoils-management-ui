import 'package:flutter_test/flutter_test.dart';
import 'package:zerospoils/domain/models/receipt_line_item.dart';
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

    test('ignores savings and tax lines while keeping sale items', () {
      const raw = '''
GROCERY
EXCEL WHITE GUM H 4.49
Saving 0.50
POINTS 25
PRODUCE
PREMIUM BANANA
1.360 kg @ \$1.52/kg 2.07
DAIRY
BURNBR.OMG3 LARG 7.99
Saving 0.60
BEATR.CHOCOLATE 7.49
COMM. BAKERY
(2)THIN SL.WHITE SA
2 @ \$2.69 5.38
Saving 2.00
12 GRAIN BREAD 4.19
4.49 HST (13.000)% 0.58
TOTAL 32.19
''';

      final parser = ReceiptParser();
      final items = parser.parse(raw);

      expect(items.length, 6);
      expect(items[0].name, 'EXCEL WHITE GUM');
      expect(items[0].price, 4.49);
      expect(items[1].name, 'PREMIUM BANANA');
      expect(items[1].price, 2.07);
      expect(items[2].name, 'BURNBR.OMG3 LARG');
      expect(items[2].price, 7.99);
      expect(items[3].name, 'BEATR.CHOCOLATE');
      expect(items[3].price, 7.49);
      expect(items[4].name, '(2)THIN SL.WHITE SA');
      expect(items[4].price, 5.38);
      expect(items[5].name, '12 GRAIN BREAD');
      expect(items[5].price, 4.19);
    });

    test('uses the previous description line for weighted produce entries', () {
      const raw = '''
PRODUCE
PREMIUM BANANA
1.360 kg @ \$1.52/kg 2.07
''';

      final parser = ReceiptParser();
      final items = parser.parse(raw);

      expect(items.length, 1);
      expect(items.single.name, 'PREMIUM BANANA');
      expect(items.single.price, 2.07);
    });

    test('parses structured OCR lines with bounding boxes and photo index', () {
      final parser = ReceiptParser();

      final items = parser.parseOcrLines(const [
        ReceiptOcrLine(
          text: 'PREMIUM BANANA',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 24, top: 160, right: 220, bottom: 186),
        ),
        ReceiptOcrLine(
          text: '1.360 kg @ \$1.52/kg 2.07',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 40, top: 190, right: 300, bottom: 214),
        ),
        ReceiptOcrLine(
          text: '4.49 HST (13.000)% 0.58',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 24, top: 420, right: 300, bottom: 446),
        ),
      ]);

      expect(items, hasLength(1));
      expect(items.single.name, 'PREMIUM BANANA');
      expect(items.single.price, 2.07);
      expect(items.single.photoIndex, 0);
      expect(
        items.single.ocrBox,
        const ReceiptOcrBox(left: 24, top: 160, right: 300, bottom: 214),
      );
    });

    test(
      'keeps multiline bakery entries and excludes savings rows in structured OCR',
      () {
        final parser = ReceiptParser();

        final items = parser.parseOcrLines(const [
          ReceiptOcrLine(
            text: '(2)THIN SL.WHITE SA',
            photoIndex: 1,
            box: ReceiptOcrBox(left: 20, top: 300, right: 220, bottom: 326),
          ),
          ReceiptOcrLine(
            text: '2 @ \$2.69 5.38',
            photoIndex: 1,
            box: ReceiptOcrBox(left: 28, top: 332, right: 200, bottom: 356),
          ),
          ReceiptOcrLine(
            text: 'Saving 2.00',
            photoIndex: 1,
            box: ReceiptOcrBox(left: 36, top: 362, right: 140, bottom: 386),
          ),
        ]);

        expect(items, hasLength(1));
        expect(items.single.name, '(2)THIN SL.WHITE SA');
        expect(items.single.price, 5.38);
        expect(items.single.photoIndex, 1);
      },
    );
  });
}
