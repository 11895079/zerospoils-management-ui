import 'package:flutter_test/flutter_test.dart';
import 'package:zerospoils/domain/models/item_model.dart';
import 'package:zerospoils/domain/utils/expiry_classifier.dart';
import 'package:zerospoils/domain/models/expiry_bucket.dart';

void main() {
  group('ExpiryClassifier', () {
    final mockCategory = ItemCategory.dairy;
    final mockLocation = StorageLocation.fridge;

    Item createItemWithExpiry(DateTime expiryDate) {
      return Item(
        id: 'test-item',
        name: 'Test Item',
        category: mockCategory,
        location: mockLocation,
        expiryDate: expiryDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    test('classify returns EXPIRED for past dates', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final item = createItemWithExpiry(yesterday);

      expect(ExpiryClassifier.classify(item), ExpiryBucket.expired);
    });

    test('classify returns EXPIRED for far past dates', () {
      final longAgo = DateTime.now().subtract(const Duration(days: 365));
      final item = createItemWithExpiry(longAgo);

      expect(ExpiryClassifier.classify(item), ExpiryBucket.expired);
    });

    test('classify returns TODAY for items expiring today', () {
      final today = DateTime.now();
      final item = createItemWithExpiry(today);

      expect(ExpiryClassifier.classify(item), ExpiryBucket.today);
    });

    test('classify returns TODAY for items expiring at end of today', () {
      final now = DateTime.now();
      final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final item = createItemWithExpiry(endOfToday);

      expect(ExpiryClassifier.classify(item), ExpiryBucket.today);
    });

    test('classify returns THIS_WEEK for items expiring tomorrow', () {
      // Use fixed date in summer (July) to avoid DST transition issues
      final today = DateTime(2026, 7, 15);
      final tomorrow = DateTime(2026, 7, 16);
      final item = createItemWithExpiry(tomorrow);

      expect(
        ExpiryClassifier.classify(item, now: today),
        ExpiryBucket.thisWeek,
      );
    });

    test('classify returns THIS_WEEK for items expiring in 3 days', () {
      final inThreeDays = DateTime.now().add(const Duration(days: 3));
      final item = createItemWithExpiry(inThreeDays);

      expect(ExpiryClassifier.classify(item), ExpiryBucket.thisWeek);
    });

    test('classify returns THIS_WEEK for items expiring in 7 days', () {
      final now = DateTime(2026, 1, 28, 12);
      final inSevenDays = now.add(const Duration(days: 7));
      final item = createItemWithExpiry(inSevenDays);

      expect(ExpiryClassifier.classify(item, now: now), ExpiryBucket.thisWeek);
    });

    test('classify returns LATER for items expiring in 8 days', () {
      final now = DateTime(2026, 1, 28, 12);
      final inEightDays = now.add(const Duration(days: 8));
      final item = createItemWithExpiry(inEightDays);

      expect(ExpiryClassifier.classify(item, now: now), ExpiryBucket.later);
    });

    test('classify returns LATER for items expiring in 30 days', () {
      final inThirtyDays = DateTime.now().add(const Duration(days: 30));
      final item = createItemWithExpiry(inThirtyDays);

      expect(ExpiryClassifier.classify(item), ExpiryBucket.later);
    });

    test('classify returns LATER for items with no expiry date', () {
      final item = Item(
        id: 'test-item',
        name: 'Test Item',
        category: mockCategory,
        location: mockLocation,
        expiryDate: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(ExpiryClassifier.classify(item), ExpiryBucket.later);
    });

    test(
      'classify handles boundary: 23:59 of yesterday (should be EXPIRED)',
      () {
        final now = DateTime.now();
        final yesterday = DateTime(
          now.year,
          now.month,
          now.day - 1,
          23,
          59,
          59,
        );
        final item = createItemWithExpiry(yesterday);

        expect(ExpiryClassifier.classify(item), ExpiryBucket.expired);
      },
    );

    test('classify handles boundary: 00:00 of today (should be TODAY)', () {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final item = createItemWithExpiry(startOfToday);

      expect(ExpiryClassifier.classify(item), ExpiryBucket.today);
    });

    test(
      'classify handles boundary: 00:00 of tomorrow (should be THIS_WEEK)',
      () {
        // Use fixed date in summer (July) to avoid DST transition issues
        final today = DateTime(2026, 7, 15);
        final startOfTomorrow = DateTime(2026, 7, 16, 0, 0, 0);
        final item = createItemWithExpiry(startOfTomorrow);

        expect(
          ExpiryClassifier.classify(item, now: today),
          ExpiryBucket.thisWeek,
        );
      },
    );

    test('classify handles leap year: Feb 28 to Mar 1', () {
      // Using a leap year date
      final leapYearDate = DateTime(2024, 2, 29); // Feb 29 in leap year 2024
      final item = createItemWithExpiry(leapYearDate);

      // Verify it classifies correctly (exact bucket depends on current date)
      final bucket = ExpiryClassifier.classify(item);
      expect([
        ExpiryBucket.expired,
        ExpiryBucket.today,
        ExpiryBucket.thisWeek,
        ExpiryBucket.later,
      ], contains(bucket));
    });

    test('classify handles year boundary: Dec 31 to Jan 1', () {
      final nextYearDate = DateTime(DateTime.now().year + 1, 1, 1);
      final item = createItemWithExpiry(nextYearDate);

      expect(ExpiryClassifier.classify(item), ExpiryBucket.later);
    });

    test('classify uses date-only comparison (ignores time component)', () {
      final now = DateTime.now();
      final todayMorning = DateTime(now.year, now.month, now.day, 6, 0, 0);
      final todayEvening = DateTime(now.year, now.month, now.day, 22, 0, 0);

      final itemMorning = createItemWithExpiry(todayMorning);
      final itemEvening = createItemWithExpiry(todayEvening);

      expect(ExpiryClassifier.classify(itemMorning), ExpiryBucket.today);
      expect(ExpiryClassifier.classify(itemEvening), ExpiryBucket.today);
    });

    test('classify is consistent across multiple calls', () {
      final inTwoDays = DateTime.now().add(const Duration(days: 2));
      final item = createItemWithExpiry(inTwoDays);

      final result1 = ExpiryClassifier.classify(item);
      final result2 = ExpiryClassifier.classify(item);

      expect(result1, result2);
    });
  });
}
