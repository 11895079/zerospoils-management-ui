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

    test('strips leading item codes and rejects payment/footer noise', () {
      const raw = '''
580517 **KS TOWEL** 24.99
1417235 KS ORG JUICE 17.99
CMN-DONATION 2.00
01 APPROVED - THANK YOU 027
AMOUNT: \$358.41
CHANGE 0.00
''';

      final parser = ReceiptParser();
      final items = parser.parse(raw);

      expect(
        items.map((item) => (item.name, item.price)).toList(),
        [('KS TOWEL', 24.99), ('KS ORG JUICE', 17.99)],
      );
    });

    test('ignores split-tender status blocks while keeping sale items', () {
      final parser = ReceiptParser();

      final items = parser.parseOcrLines(const [
        ReceiptOcrLine(
          text: '457 HOMO MILK',
          box: ReceiptOcrBox(left: 24, top: 120, right: 180, bottom: 144),
        ),
        ReceiptOcrLine(
          text: '7.09',
          box: ReceiptOcrBox(left: 244, top: 120, right: 292, bottom: 144),
        ),
        ReceiptOcrLine(
          text: 'TRANSACTION NOT COMPLETED',
          box: ReceiptOcrBox(left: 24, top: 300, right: 240, bottom: 324),
        ),
        ReceiptOcrLine(
          text: 'AMOUNT: \$160.32',
          box: ReceiptOcrBox(left: 24, top: 328, right: 180, bottom: 352),
        ),
        ReceiptOcrLine(
          text: '01 APPROVED - THANK YOU 027',
          box: ReceiptOcrBox(left: 24, top: 356, right: 260, bottom: 380),
        ),
        ReceiptOcrLine(
          text: 'CHANGE',
          box: ReceiptOcrBox(left: 24, top: 384, right: 120, bottom: 408),
        ),
        ReceiptOcrLine(
          text: '0.00',
          box: ReceiptOcrBox(left: 244, top: 384, right: 292, bottom: 408),
        ),
      ]);

      expect(items.map((item) => (item.name, item.price)).toList(), [
        ('HOMO MILK', 7.09),
      ]);
    });

    test('ignores separate TPD discount rows and masked tender rows', () {
      const raw = '''
55502 DRUMSTICKS 18.19
2063709 TPD/55502 5.00-
XXXXXXXXXXXX0727 ACCT: MASTERCARD 358.41
''';

      final parser = ReceiptParser();
      final items = parser.parse(raw);

      expect(
        items.map((item) => (item.name, item.price)).toList(),
        [('DRUMSTICKS', 18.19)],
      );
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

    test('reconstructs split-column OCR rows from a receipt screenshot', () {
      final parser = ReceiptParser();

      final lines = const [
        ReceiptOcrLine(
          text: 'GROCERY',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 10, top: 80, right: 90, bottom: 100),
        ),
        ReceiptOcrLine(
          text: 'EXCEL WHITE GUM',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 20, top: 112, right: 180, bottom: 132),
        ),
        ReceiptOcrLine(
          text: 'H',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 210, top: 112, right: 220, bottom: 132),
        ),
        ReceiptOcrLine(
          text: '4.49',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 250, top: 112, right: 290, bottom: 132),
        ),
        ReceiptOcrLine(
          text: 'Saving 0.50',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 30, top: 140, right: 120, bottom: 160),
        ),
        ReceiptOcrLine(
          text: 'PRODUCE',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 10, top: 176, right: 90, bottom: 196),
        ),
        ReceiptOcrLine(
          text: 'PREMIUM BANANA',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 20, top: 204, right: 180, bottom: 224),
        ),
        ReceiptOcrLine(
          text: '1.360 kg @ \$1.52/kg',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 35, top: 230, right: 200, bottom: 250),
        ),
        ReceiptOcrLine(
          text: '2.07',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 250, top: 230, right: 290, bottom: 250),
        ),
        ReceiptOcrLine(
          text: 'DAIRY',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 10, top: 260, right: 60, bottom: 280),
        ),
        ReceiptOcrLine(
          text: 'BURNBR.OMG3 LARG',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 20, top: 288, right: 180, bottom: 308),
        ),
        ReceiptOcrLine(
          text: '7.99',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 250, top: 288, right: 290, bottom: 308),
        ),
        ReceiptOcrLine(
          text: 'BEATR.CHOCOLATE',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 20, top: 334, right: 180, bottom: 354),
        ),
        ReceiptOcrLine(
          text: '7.49',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 250, top: 334, right: 290, bottom: 354),
        ),
        ReceiptOcrLine(
          text: 'COMM. BAKERY',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 10, top: 364, right: 110, bottom: 384),
        ),
        ReceiptOcrLine(
          text: '(2)THIN SL.WHITE SA',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 20, top: 392, right: 180, bottom: 412),
        ),
        ReceiptOcrLine(
          text: '2 @ \$2.69',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 35, top: 420, right: 120, bottom: 440),
        ),
        ReceiptOcrLine(
          text: '5.38',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 250, top: 420, right: 290, bottom: 440),
        ),
        ReceiptOcrLine(
          text: '12 GRAIN BREAD',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 20, top: 470, right: 160, bottom: 490),
        ),
        ReceiptOcrLine(
          text: '4.19',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 250, top: 470, right: 290, bottom: 490),
        ),
        ReceiptOcrLine(
          text: 'SUBTOTAL',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 10, top: 500, right: 90, bottom: 520),
        ),
        ReceiptOcrLine(
          text: '31.61',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 250, top: 500, right: 290, bottom: 520),
        ),
        ReceiptOcrLine(
          text: '4.49 HST (13.000)%',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 20, top: 530, right: 180, bottom: 550),
        ),
        ReceiptOcrLine(
          text: '0.58',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 250, top: 530, right: 290, bottom: 550),
        ),
        ReceiptOcrLine(
          text: 'CREDIT CR',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 20, top: 590, right: 110, bottom: 610),
        ),
        ReceiptOcrLine(
          text: '32.19',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 250, top: 590, right: 290, bottom: 610),
        ),
      ];

      final items = parser.parseOcrLines(lines);

      expect(items.map((item) => (item.name, item.price)).toList(), [
        ('EXCEL WHITE GUM', 4.49),
        ('PREMIUM BANANA', 2.07),
        ('BURNBR.OMG3 LARG', 7.99),
        ('BEATR.CHOCOLATE', 7.49),
        ('(2)THIN SL.WHITE SA', 5.38),
        ('12 GRAIN BREAD', 4.19),
      ]);

      final detailed = parser.parseDetailedOcrLines(lines);
      expect(
        detailed.acceptedRows
            .map((row) => (row.extractedName, row.extractedPrice))
            .toList(),
        [
          ('EXCEL WHITE GUM', 4.49),
          ('PREMIUM BANANA', 2.07),
          ('BURNBR.OMG3 LARG', 7.99),
          ('BEATR.CHOCOLATE', 7.49),
          ('(2)THIN SL.WHITE SA', 5.38),
          ('12 GRAIN BREAD', 4.19),
        ],
      );

      expect(
        detailed.rejectedRows
            .where(
              (row) => row.classification != ReceiptRowClassification.unknown,
            )
            .map((row) => (row.text, row.classification))
            .toList(),
        containsAll([
          ('GROCERY', ReceiptRowClassification.department),
          ('Saving 0.50', ReceiptRowClassification.savings),
          ('PRODUCE', ReceiptRowClassification.department),
          ('DAIRY', ReceiptRowClassification.department),
          ('COMM. BAKERY', ReceiptRowClassification.department),
          ('SUBTOTAL 31.61', ReceiptRowClassification.total),
          ('4.49 HST (13.000)% 0.58', ReceiptRowClassification.tax),
          ('CREDIT CR 32.19', ReceiptRowClassification.payment),
        ]),
      );
    });
  });
}
