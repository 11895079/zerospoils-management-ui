import 'package:flutter_test/flutter_test.dart';
import 'package:zerospoils/core/utils/date_formatter.dart';

void main() {
  group('AppDateFormatter', () {
    final testDate = DateTime(2026, 2, 20);

    test('formatDate MM/DD/YYYY format', () {
      final result = AppDateFormatter.formatDate(testDate, 'MM/DD/YYYY');
      expect(result, '02/20/2026');
    });

    test('formatDate DD/MM/YYYY format', () {
      final result = AppDateFormatter.formatDate(testDate, 'DD/MM/YYYY');
      expect(result, '20/02/2026');
    });

    test('formatDate YYYY-MM-DD format', () {
      final result = AppDateFormatter.formatDate(testDate, 'YYYY-MM-DD');
      expect(result, '2026-02-20');
    });

    test('formatMonthDay returns standardized format', () {
      final result = AppDateFormatter.formatMonthDay(testDate, 'MM/DD/YYYY');
      expect(result, 'Feb 20');
    });

    test('formatDateWithYear returns standardized format', () {
      final result = AppDateFormatter.formatDateWithYear(
        testDate,
        'DD/MM/YYYY',
      );
      expect(result, '20 Feb 2026');
    });

    test('formatTime returns HH:mm format', () {
      final timeDate = DateTime(2026, 2, 20, 14, 30);
      final result = AppDateFormatter.formatTime(timeDate);
      expect(result, '14:30');
    });

    test('formatRelativeTime returns correct ago format', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final result = AppDateFormatter.formatRelativeTime(yesterday);
      expect(result, '1 day ago');
    });

    test('formatRelativeTime returns just now for recent dates', () {
      final now = DateTime.now();
      final recent = now.subtract(const Duration(seconds: 10));
      final result = AppDateFormatter.formatRelativeTime(recent);
      expect(result, 'just now');
    });
  });
}
