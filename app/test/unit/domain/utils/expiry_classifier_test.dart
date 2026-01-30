import 'package:flutter_test/flutter_test.dart';
import 'package:zerospoils/domain/models/item_model.dart';
import 'package:zerospoils/domain/models/expiry_bucket.dart';
import 'package:zerospoils/domain/utils/expiry_classifier.dart';

void main() {
  group('ExpiryClassifier', () {
    final today = DateTime(2026, 1, 28);
    Item itemWithDate(DateTime? date) => Item(
      id: '1',
      name: 'Test',
      category: ItemCategory.dairy,
      location: StorageLocation.fridge,
      quantity: 1,
      unit: Unit.liter,
      expiryDate: date,
      createdAt: today,
      updatedAt: today,
    );

    test('Today bucket (expiry is today)', () {
      final item = itemWithDate(today);
      expect(ExpiryClassifier.classify(item, now: today), ExpiryBucket.today);
    });

    test('Boundary 24-hour threshold', () {
      final item = itemWithDate(DateTime(2026, 1, 28, 23, 59));
      expect(ExpiryClassifier.classify(item, now: today), ExpiryBucket.today);
    });

    test('This Week bucket (1-7 days)', () {
      final item = itemWithDate(today.add(Duration(days: 3)));
      expect(
        ExpiryClassifier.classify(item, now: today),
        ExpiryBucket.thisWeek,
      );
    });

    test('Expired bucket (past date)', () {
      final item = itemWithDate(today.subtract(Duration(days: 1)));
      expect(ExpiryClassifier.classify(item, now: today), ExpiryBucket.expired);
    });

    test('Later bucket (8+ days)', () {
      final item = itemWithDate(today.add(Duration(days: 8)));
      expect(ExpiryClassifier.classify(item, now: today), ExpiryBucket.later);
    });

    test('Null expiry date returns LATER', () {
      final item = itemWithDate(null);
      expect(ExpiryClassifier.classify(item, now: today), ExpiryBucket.later);
    });

    test('Timezone consistency', () {
      final item = itemWithDate(DateTime.utc(2026, 1, 28));
      expect(ExpiryClassifier.classify(item, now: today), ExpiryBucket.today);
    });

    test('Leap year handling', () {
      final leap = DateTime(2024, 2, 28);
      final item = itemWithDate(leap);
      expect(
        ExpiryClassifier.classify(item, now: DateTime(2024, 2, 28)),
        ExpiryBucket.today,
      );
      expect(
        ExpiryClassifier.classify(item, now: DateTime(2024, 3, 1)),
        ExpiryBucket.expired,
      );
    });

    test('Year boundary', () {
      final dec31 = DateTime(2025, 12, 31);
      final item = itemWithDate(dec31);
      expect(
        ExpiryClassifier.classify(item, now: DateTime(2025, 12, 31)),
        ExpiryBucket.today,
      );
      expect(
        ExpiryClassifier.classify(item, now: DateTime(2026, 1, 1)),
        ExpiryBucket.expired,
      );
    });

    test('Same-day edge case (expires at 00:00, check at 23:59)', () {
      final expiry = DateTime(2026, 1, 28, 0, 0);
      final item = itemWithDate(expiry);
      expect(
        ExpiryClassifier.classify(item, now: DateTime(2026, 1, 28, 23, 59)),
        ExpiryBucket.today,
      );
    });
  });
}
