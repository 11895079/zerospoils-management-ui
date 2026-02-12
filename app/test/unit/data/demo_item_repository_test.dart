import 'package:flutter_test/flutter_test.dart';
import 'package:zerospoils/data/repositories/demo_item_repository.dart';
import 'package:zerospoils/domain/models/item_model.dart';
import 'package:zerospoils/domain/utils/expiry_classifier.dart';

void main() {
  test('DemoItemRepository seeds items across expiry buckets', () async {
    final repo = DemoItemRepository();
    await repo.init();

    final items = await repo.getAllItems();
    expect(items.length, greaterThanOrEqualTo(7));

    final categories = items.map((item) => item.category).toSet();
    expect(categories.length, greaterThanOrEqualTo(4));

    final buckets = items
        .where((item) => item.status == ItemStatus.available)
        .map(ExpiryClassifier.classify)
        .toSet();

    expect(buckets, isNotEmpty);
  });
}
