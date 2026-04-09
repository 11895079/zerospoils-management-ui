import 'package:flutter_test/flutter_test.dart';
import 'package:zerospoils/domain/utils/expiry_date_parser.dart';

import '../../../fixtures/ocr/expiry_ocr_text_fixtures.dart';

void main() {
  group('ExpiryDateParser', () {
    const parser = ExpiryDateParser();
    final now = DateTime(2026, 1, 1);

    test('parses ISO format YYYY-MM-DD', () {
      final result = parser.parse('EXP 2026-12-05', now: now);
      expect(result, isNotNull);
      expect(result!.date, DateTime(2026, 12, 5));
      expect(result.format, 'YYYY-MM-DD');
    });

    test('parses MM/DD/YYYY format', () {
      final result = parser.parse('Best By 01/15/2026', now: now);
      expect(result, isNotNull);
      expect(result!.date, DateTime(2026, 1, 15));
    });

    test('parses DD/MM/YY format', () {
      final result = parser.parse('EXP 15-01-26', now: now);
      expect(result, isNotNull);
      expect(result!.date, DateTime(2026, 1, 15));
    });

    test('prefers MM/DD/YYYY for ambiguous slash dates by default', () {
      final result = parser.parse('EXP 03/04/2026', now: now);

      expect(result, isNotNull);
      expect(result!.date, DateTime(2026, 3, 4));
      expect(result.format, 'MM/DD/YYYY');
    });

    test('prefers configured DD/MM/YYYY for ambiguous slash dates', () {
      final result = parser.parse(
        'EXP 03/04/2026',
        now: now,
        preferredDateFormat: 'DD/MM/YYYY',
      );

      expect(result, isNotNull);
      expect(result!.date, DateTime(2026, 4, 3));
      expect(result.format, 'DD/MM/YYYY');
    });

    test('parses month name format', () {
      final result = parser.parse('Use By Jan 15 2026', now: now);
      expect(result, isNotNull);
      expect(result!.date, DateTime(2026, 1, 15));
    });

    test('prefers expiry-labelled dates over manufacture dates', () {
      final result = parser.parse('MFG 01/10/2026\nEXP 03/18/2026', now: now);

      expect(result, isNotNull);
      expect(result!.date, DateTime(2026, 3, 18));
    });

    test('parses BB/MA-labelled Canadian dates', () {
      final result = parser.parse(
        'BB/MA 21/04/2026',
        now: now,
        preferredDateFormat: 'DD/MM/YYYY',
      );

      expect(result, isNotNull);
      expect(result!.date, DateTime(2026, 4, 21));
      expect(result.format, 'DD/MM/YYYY');
    });

    test('prefers BB/MA-labelled date over packed date', () {
      final result = parser.parse(
        'PKD 01/04/2026\nBB/MA 21/04/2026',
        now: now,
        preferredDateFormat: 'DD/MM/YYYY',
      );

      expect(result, isNotNull);
      expect(result!.date, DateTime(2026, 4, 21));
    });

    test('parses realistic Canadian BB/MA OCR block', () {
      final result = parser.parse(
        ExpiryOcrTextFixtures.canadianBbMaWithPackedDate,
        now: now,
        preferredDateFormat: 'DD/MM/YYYY',
      );

      expect(result, isNotNull);
      expect(result!.date, DateTime(2026, 4, 21));
      expect(result.format, 'DD/MM/YYYY');
    });

    test('parses stamped BB/MA dotted date layout', () {
      final result = parser.parse(
        ExpiryOcrTextFixtures.stampedBbMaDotted,
        now: now,
        preferredDateFormat: 'DD/MM/YYYY',
      );

      expect(result, isNotNull);
      expect(result!.date, DateTime(2026, 4, 21));
    });

    test('parses French meilleur avant label', () {
      final result = parser.parse(
        ExpiryOcrTextFixtures.frenchBestBefore,
        now: now,
        preferredDateFormat: 'DD/MM/YYYY',
      );

      expect(result, isNotNull);
      expect(result!.date, DateTime(2026, 4, 21));
    });

    test('parses Canadian BB/MA month-code format from package stamp', () {
      final result = parser.parse(
        ExpiryOcrTextFixtures.canadianMonthCodeBestBefore,
        now: now,
        preferredDateFormat: 'DD/MM/YYYY',
      );

      expect(result, isNotNull);
      expect(result!.date, DateTime(2027, 11, 20));
    });

    test('parses multilingual embossed best-before date on following line', () {
      final result = parser.parse(
        ExpiryOcrTextFixtures.multilingualEmbossedBestBefore,
        now: now,
        preferredDateFormat: 'DD/MM/YYYY',
      );

      expect(result, isNotNull);
      expect(result!.date, DateTime(2028, 10, 28));
      expect(result.format, 'DD MM YYYY');
    });

    test('parses multilingual embossed date with OCR-confused digits', () {
      final result = parser.parse(
        ExpiryOcrTextFixtures.multilingualEmbossedBestBeforeOcrConfused,
        now: now,
        preferredDateFormat: 'DD/MM/YYYY',
      );

      expect(result, isNotNull);
      expect(result!.date, DateTime(2028, 10, 28));
      expect(result.format, 'DD MM YYYY');
    });

    test('prefers BB/MA month-code date over packed month-code date', () {
      final result = parser.parse(
        ExpiryOcrTextFixtures.canadianMonthCodePackedAndBestBefore,
        now: now,
        preferredDateFormat: 'DD/MM/YYYY',
      );

      expect(result, isNotNull);
      expect(result!.date, DateTime(2027, 11, 20));
    });

    test('parses dotted expiry labels from package prints', () {
      final result = parser.parse(
        'MFG:11.11.25.BND.00871125\nEXP:11.11.27',
        now: now,
        preferredDateFormat: 'DD/MM/YYYY',
      );

      expect(result, isNotNull);
      expect(result!.date, DateTime(2027, 11, 11));
    });

    test('rejects far future dates', () {
      final result = parser.parse('Best By 12/31/2030', now: now);
      expect(result, isNull);
    });

    test('rejects empty input', () {
      final result = parser.parse('   ', now: now);
      expect(result, isNull);
    });
  });
}
