import 'package:flutter_test/flutter_test.dart';
import 'package:zerospoils/domain/utils/expiry_date_parser.dart';

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
