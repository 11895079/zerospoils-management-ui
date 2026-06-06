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

      expect(items.map((item) => (item.name, item.price)).toList(), [
        ('KS TOWEL', 24.99),
        ('KS ORG JUICE', 17.99),
      ]);
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

      expect(items.map((item) => (item.name, item.price)).toList(), [
        ('DRUMSTICKS', 18.19),
      ]);
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

    test('extracts summary amounts from tax, total, and savings lines', () {
      final parser = ReceiptParser();

      final detailed = parser.parseDetailedOcrLines(const [
        ReceiptOcrLine(
          text: 'SUBTOTAL 31.61',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 20, top: 500, right: 180, bottom: 520),
        ),
        ReceiptOcrLine(
          text: '4.49 HST (13.000)% 0.58',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 20, top: 530, right: 180, bottom: 550),
        ),
        ReceiptOcrLine(
          text: 'Saving 0.50',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 20, top: 560, right: 180, bottom: 580),
        ),
      ]);

      expect(detailed.totalAmount, 31.61);
      expect(detailed.taxAmount, 0.58);
      expect(detailed.savingsAmount, 0.50);
    });

    test('extracts tax, total, and savings amounts in parse result', () {
      const raw = '''
MILK 4.99
SAVINGS -1.25
HST 0.85
TOTAL 4.59
''';

      final parser = ReceiptParser();
      final result = parser.parseDetailed(raw);

      expect(result.items.length, 1);
      expect(result.taxAmount, closeTo(0.85, 0.001));
      expect(result.totalAmount, closeTo(4.59, 0.001));
      expect(result.savingsAmount, closeTo(1.25, 0.001));
    });

    test('stores extracted amount on classified excluded rows', () {
      const raw = '''
HST 1.10
TOTAL 9.99
SAVINGS -2.00
''';

      final parser = ReceiptParser();
      final result = parser.parseDetailed(raw);

      final taxRow = result.rows.firstWhere(
        (row) => row.classification == ReceiptRowClassification.tax,
      );
      final totalRow = result.rows.firstWhere(
        (row) => row.classification == ReceiptRowClassification.total,
      );
      final savingsRow = result.rows.firstWhere(
        (row) => row.classification == ReceiptRowClassification.savings,
      );

      expect(taxRow.extractedPrice, closeTo(1.10, 0.001));
      expect(totalRow.extractedPrice, closeTo(9.99, 0.001));
      expect(savingsRow.extractedPrice, closeTo(2.00, 0.001));
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

    test('prefers listed prices for promo-heavy multi-price rows', () {
      final parser = ReceiptParser();

      final items = parser.parseOcrLines(const [
        ReceiptOcrLine(
          text: 'CH PROTEIN BREAD MRJ',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 24, top: 160, right: 220, bottom: 186),
        ),
        ReceiptOcrLine(
          text: '6.98 1 @ \$3.49 ea 2/\$6.00',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 240, top: 192, right: 430, bottom: 218),
        ),
        ReceiptOcrLine(
          text: 'CH EVERYTHING BR MRJ',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 24, top: 240, right: 220, bottom: 266),
        ),
        ReceiptOcrLine(
          text: '3.49 ea or 2/\$6.00 6.00',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 240, top: 272, right: 460, bottom: 298),
        ),
      ]);

      expect(items.map((item) => (item.name, item.price)).toList(), [
        ('CH PROTEIN BREAD', 6.98),
        ('CH EVERYTHING BR', 3.49),
      ]);
    });

    test('uses pending product name for ea-or promo rows', () {
      final parser = ReceiptParser();

      final items = parser.parseOcrLines(const [
        ReceiptOcrLine(
          text: 'CH EVERYTHING BR MRJ',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 24, top: 200, right: 240, bottom: 226),
        ),
        ReceiptOcrLine(
          text: r'$3.49 ea or 2/$6.00',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 260, top: 232, right: 460, bottom: 258),
        ),
      ]);

      expect(items.map((item) => (item.name, item.price)).toList(), [
        ('CH EVERYTHING BR', 3.49),
      ]);
    });

    test('reconstructs quantity-coded promo companion item', () {
      final parser = ReceiptParser();

      final items = parser.parseOcrLines(const [
        ReceiptOcrLine(
          text: 'CH PROTEIN BREAD MRJ',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 24, top: 100, right: 260, bottom: 126),
        ),
        ReceiptOcrLine(
          text: '(2)06088500051',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 24, top: 130, right: 220, bottom: 156),
        ),
        ReceiptOcrLine(
          text: 'CH EVERYTHING BR MRJ',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 24, top: 180, right: 260, bottom: 206),
        ),
        ReceiptOcrLine(
          text: '(1)06088500048',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 24, top: 210, right: 220, bottom: 236),
        ),
        ReceiptOcrLine(
          text: r'$3.49 ea or 2/$6.00',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 260, top: 240, right: 460, bottom: 266),
        ),
      ]);

      expect(items.map((item) => (item.name, item.price)).toList(), [
        ('CH EVERYTHING BR', 3.49),
        ('CH PROTEIN BREAD', 6.98),
      ]);
    });

    test('merges price with nearby code and product name rows', () {
      final parser = ReceiptParser();

      final items = parser.parseOcrLines(const [
        ReceiptOcrLine(
          text: '10.99',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 360, top: 300, right: 430, bottom: 326),
        ),
        ReceiptOcrLine(
          text: '1MRJ',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 280, top: 302, right: 340, bottom: 328),
        ),
        ReceiptOcrLine(
          text: '06038315245',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 24, top: 304, right: 170, bottom: 330),
        ),
        ReceiptOcrLine(
          text: 'PC CHKN PRIGSE',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 180, top: 306, right: 275, bottom: 332),
        ),
      ]);

      expect(items.map((item) => (item.name, item.price)).toList(), [
        ('PC CHKN PRTGSE', 10.99),
      ]);
    });

    test('does not merge adjacent priced item rows', () {
      final parser = ReceiptParser();

      final items = parser.parseOcrLines(const [
        ReceiptOcrLine(
          text: 'H 13.99 2154720 MADEGOOD BIT',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 20, top: 100, right: 280, bottom: 126),
        ),
        ReceiptOcrLine(
          text: '27.18',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 300, top: 132, right: 360, bottom: 158),
        ),
        ReceiptOcrLine(
          text: '60163 BEEF RIBS',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 20, top: 144, right: 220, bottom: 170),
        ),
      ]);

      expect(items.map((item) => (item.name, item.price)).toList(), [
        ('MADEGOOD BIT', 13.99),
        ('BEEF RIBS', 27.18),
      ]);
    });

    test('prefers after-price coded description over pending name', () {
      final parser = ReceiptParser();

      final items = parser.parseOcrLines(const [
        ReceiptOcrLine(
          text: 'H 1708072 LYSOL WIPES',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 20, top: 100, right: 220, bottom: 126),
        ),
        ReceiptOcrLine(
          text: 'H 14.99 1579298 GROWERS ASST',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 20, top: 132, right: 320, bottom: 158),
        ),
      ]);

      expect(items.map((item) => (item.name, item.price)).toList(), [
        ('GROWERS ASST', 14.99),
      ]);
    });

    test('backfills coded descriptions from recent standalone prices', () {
      final parser = ReceiptParser();

      final items = parser.parseOcrLines(const [
        ReceiptOcrLine(
          text: '26.99',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 240, top: 80, right: 300, bottom: 106),
        ),
        ReceiptOcrLine(
          text: 'H 1424970 CASHMERE TP',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 20, top: 110, right: 250, bottom: 136),
        ),
        ReceiptOcrLine(
          text: '24.99',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 240, top: 140, right: 300, bottom: 166),
        ),
        ReceiptOcrLine(
          text: 'H 1708072 LYSOL WIPES',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 20, top: 170, right: 250, bottom: 196),
        ),
      ]);

      expect(items.map((item) => (item.name, item.price)).toList(), [
        ('CASHMERE TP', 26.99),
        ('LYSOL WIPES', 24.99),
      ]);
    });

    test('carries coded prices forward across shifted s1-style rows', () {
      final parser = ReceiptParser();

      final items = parser.parseOcrLines(const [
        ReceiptOcrLine(
          text: '2063709 TPD/55502 7.99',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 20, top: 100, right: 220, bottom: 126),
        ),
        ReceiptOcrLine(
          text: '27003 STRAWBERRIES 8.99',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 20, top: 130, right: 260, bottom: 156),
        ),
        ReceiptOcrLine(
          text: '1647794 CRMYDILLPCKL 6.99',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 20, top: 160, right: 260, bottom: 186),
        ),
        ReceiptOcrLine(
          text: '647229 WHITE BREAD',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 20, top: 190, right: 220, bottom: 216),
        ),
        ReceiptOcrLine(
          text: 'ECO FEE BAT 1.69',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 20, top: 220, right: 220, bottom: 246),
        ),
        ReceiptOcrLine(
          text: '30669 BANANAS 16.99',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 20, top: 250, right: 220, bottom: 276),
        ),
        ReceiptOcrLine(
          text: '259659 FLAKED WHITE 4.00-',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 20, top: 280, right: 250, bottom: 306),
        ),
      ]);

      expect(items.map((item) => (item.name, item.price)).toList(), [
        ('STRAWBERRIES', 7.99),
        ('CRMYDILLPCKL', 8.99),
        ('WHITE BREAD', 6.99),
        ('BANANAS', 1.69),
        ('FLAKED WHITE', 16.99),
      ]);
    });

    test('does not seed coded carry-forward from negative TPD rows', () {
      final parser = ReceiptParser();

      final items = parser.parseOcrLines(const [
        ReceiptOcrLine(
          text: '2063709 TPD/55502 5.00-',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 20, top: 100, right: 240, bottom: 126),
        ),
        ReceiptOcrLine(
          text: '27003 STRAWBERRIES 8.99',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 20, top: 130, right: 260, bottom: 156),
        ),
        ReceiptOcrLine(
          text: '647229 WHITE BREAD',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 20, top: 160, right: 220, bottom: 186),
        ),
      ]);

      expect(items.map((item) => (item.name, item.price)).toList(), [
        ('STRAWBERRIES', 8.99),
      ]);
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

    test('filters S3 promo-math, barcode, and modifier-code rows', () {
      final parser = ReceiptParser();

      final items = parser.parseOcrLines(const [
        ReceiptOcrLine(
          text: '22-DAIRY',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 40, top: 100, right: 180, bottom: 126),
        ),
        ReceiptOcrLine(
          text: 'OIKS PR DR MXD HMRJ',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 40, top: 130, right: 240, bottom: 156),
        ),
        ReceiptOcrLine(
          text: '(2)05680051051',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 40, top: 130, right: 240, bottom: 156),
        ),
        ReceiptOcrLine(
          text: '7.00',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 260, top: 138, right: 320, bottom: 166),
        ),
        ReceiptOcrLine(
          text: '2 ° \$3.50',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 40, top: 170, right: 180, bottom: 196),
        ),
        ReceiptOcrLine(
          text: 'DACT PR FB STR',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 40, top: 210, right: 220, bottom: 236),
        ),
        ReceiptOcrLine(
          text: '05680096051',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 40, top: 236, right: 220, bottom: 262),
        ),
        ReceiptOcrLine(
          text: 'MRJ',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 40, top: 264, right: 90, bottom: 290),
        ),
        ReceiptOcrLine(
          text: '6.29',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 260, top: 264, right: 320, bottom: 290),
        ),
        ReceiptOcrLine(
          text: 'VALIDATION',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 40, top: 320, right: 160, bottom: 346),
        ),
        ReceiptOcrLine(
          text: '73.00',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 260, top: 320, right: 320, bottom: 346),
        ),
      ]);

      expect(items.map((item) => (item.name, item.price)).toList(), [
        ('OIKS PR DR MXD', 7.00),
        ('DACT PR FB STR', 6.29),
      ]);
    });

    test('parses weighted product names and ignores postal code rows', () {
      final parser = ReceiptParser();

      final items = parser.parseOcrLines(const [
        ReceiptOcrLine(
          text: 'K1B 3L9',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 32, top: 100, right: 120, bottom: 124),
        ),
        ReceiptOcrLine(
          text: 'FRESH BEEF KG',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 32, top: 150, right: 180, bottom: 174),
        ),
        ReceiptOcrLine(
          text: '\$60.20',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 220, top: 150, right: 280, bottom: 174),
        ),
        ReceiptOcrLine(
          text: '1.290 kg @ \$4.99/kg',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 32, top: 200, right: 210, bottom: 224),
        ),
        ReceiptOcrLine(
          text: 'PLANTAIN KG',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 32, top: 228, right: 160, bottom: 252),
        ),
        ReceiptOcrLine(
          text: '\$6.44',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 220, top: 228, right: 280, bottom: 252),
        ),
        ReceiptOcrLine(
          text: '1 @ \$1.29 each (12/\$13.99)',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 32, top: 278, right: 260, bottom: 302),
        ),
      ]);

      expect(items.map((item) => (item.name, item.price)).toList(), [
        ('FRESH BEEF KG', 60.20),
        ('PLANTAIN KG', 6.44),
      ]);
    });

    test(
      'strips Costco-style leading codes and rejects merchant footer noise',
      () {
        final parser = ReceiptParser();

        final items = parser.parseOcrLines(const [
          ReceiptOcrLine(
            text: 'Gloucester BCTR #802 1900 Cyrville Road Gloucester',
            photoIndex: 0,
            box: ReceiptOcrBox(left: 20, top: 100, right: 280, bottom: 124),
          ),
          ReceiptOcrLine(
            text: 'H 1424970 CASHMERE TP',
            photoIndex: 0,
            box: ReceiptOcrBox(left: 20, top: 140, right: 220, bottom: 164),
          ),
          ReceiptOcrLine(
            text: '\$24.99',
            photoIndex: 0,
            box: ReceiptOcrBox(left: 260, top: 140, right: 320, bottom: 164),
          ),
          ReceiptOcrLine(
            text: 'H 9.99 5558566 ORG JUICE',
            photoIndex: 0,
            box: ReceiptOcrBox(left: 20, top: 180, right: 260, bottom: 204),
          ),
          ReceiptOcrLine(
            text: '\$11.99',
            photoIndex: 0,
            box: ReceiptOcrBox(left: 260, top: 180, right: 320, bottom: 204),
          ),
          ReceiptOcrLine(
            text: 'XXXXXXXXXXXX0727',
            photoIndex: 0,
            box: ReceiptOcrBox(left: 20, top: 220, right: 180, bottom: 244),
          ),
          ReceiptOcrLine(
            text: '\$19.50',
            photoIndex: 0,
            box: ReceiptOcrBox(left: 260, top: 220, right: 320, bottom: 244),
          ),
          ReceiptOcrLine(
            text: 'TOTAL NUMBER OF ITEMS SOLD =',
            photoIndex: 0,
            box: ReceiptOcrBox(left: 20, top: 260, right: 280, bottom: 284),
          ),
          ReceiptOcrLine(
            text: '\$19.50',
            photoIndex: 0,
            box: ReceiptOcrBox(left: 260, top: 260, right: 320, bottom: 284),
          ),
        ]);

        expect(items.map((item) => (item.name, item.price)).toList(), [
          ('CASHMERE TP', 24.99),
          ('ORG JUICE', 9.99),
        ]);
      },
    );

    test('normalizes S2 OCR-corrupted names and reconstructs STEWING BEEF', () {
      final parser = ReceiptParser();

      final items = parser.parseOcrLines(const [
        ReceiptOcrLine(
          text: '71408 P/BUTTER 2K0',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 240, top: 777, right: 700, bottom: 830),
        ),
        ReceiptOcrLine(
          text: '9.89',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 888, top: 786, right: 998, bottom: 846),
        ),
        ReceiptOcrLine(
          text: '10.79',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 869, top: 842, right: 998, bottom: 901),
        ),
        ReceiptOcrLine(
          text: '144480 PCTIVIA',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 239, top: 846, right: 612, bottom: 901),
        ),
        ReceiptOcrLine(
          text: 'BEEF',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 630, top: 897, right: 750, bottom: 947),
        ),
        ReceiptOcrLine(
          text: '54.93',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 869, top: 897, right: 998, bottom: 957),
        ),
        ReceiptOcrLine(
          text: '12316 STEWING',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 261, top: 903, right: 613, bottom: 957),
        ),
      ]);

      expect(items.map((item) => (item.name, item.price)).toList(), [
        ('P/BUTTER 2KG', 9.89),
        ('ACTIVIA', 10.79),
        ('STEWING BEEF', 54.93),
      ]);
    });

    test('normalizes easy S3 OCR names and rejects CADS footer artifact', () {
      final parser = ReceiptParser();

      final items = parser.parseOcrLines(const [
        ReceiptOcrLine(
          text: 'PC 27 GRK PCH/MA MRJ',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 40, top: 100, right: 220, bottom: 124),
        ),
        ReceiptOcrLine(
          text: '3.99',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 260, top: 100, right: 320, bottom: 124),
        ),
        ReceiptOcrLine(
          text: 'SQ SHRIMP 96-55',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 40, top: 150, right: 220, bottom: 174),
        ),
        ReceiptOcrLine(
          text: '8.99',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 260, top: 150, right: 320, bottom: 174),
        ),
        ReceiptOcrLine(
          text: 'CADS',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 40, top: 200, right: 120, bottom: 224),
        ),
        ReceiptOcrLine(
          text: '73.00',
          photoIndex: 0,
          box: ReceiptOcrBox(left: 260, top: 200, right: 320, bottom: 224),
        ),
      ]);

      expect(items.map((item) => (item.name, item.price)).toList(), [
        ('PC 2 GRK PCH/MA', 3.99),
        ('SQ SHRIMP 36 55', 8.99),
      ]);
    });
  });
}
