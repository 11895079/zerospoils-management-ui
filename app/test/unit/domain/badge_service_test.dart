import 'package:flutter_test/flutter_test.dart';
import 'package:zerospoils/domain/models/item_model.dart';
import 'package:zerospoils/domain/repositories/badge_service.dart';

void main() {
  group('BadgeService.checkNoWasteWeekBadge', () {
    final service = BadgeService();

    Item buildItem({
      required String id,
      required ItemStatus status,
      required DateTime createdAt,
      required DateTime updatedAt,
    }) {
      return Item(
        id: id,
        name: 'Item $id',
        category: ItemCategory.other,
        location: StorageLocation.pantry,
        status: status,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    }

    test(
      'returns true when no waste in last 7 days and history covers window',
      () async {
        final now = DateTime.now();
        final items = <Item>[
          buildItem(
            id: '1',
            status: ItemStatus.available,
            createdAt: now.subtract(const Duration(days: 10)),
            updatedAt: now.subtract(const Duration(days: 1)),
          ),
          buildItem(
            id: '2',
            status: ItemStatus.consumed,
            createdAt: now.subtract(const Duration(days: 8)),
            updatedAt: now.subtract(const Duration(days: 2)),
          ),
        ];

        final wastedItems = <Item>[];

        final earned = await service.checkNoWasteWeekBadge(items, wastedItems);

        expect(earned, isTrue);
      },
    );

    test('returns false when waste exists inside 7-day window', () async {
      final now = DateTime.now();
      final items = <Item>[
        buildItem(
          id: '1',
          status: ItemStatus.available,
          createdAt: now.subtract(const Duration(days: 10)),
          updatedAt: now,
        ),
      ];
      final wastedItems = <Item>[
        buildItem(
          id: 'w1',
          status: ItemStatus.wasted,
          createdAt: now.subtract(const Duration(days: 5)),
          updatedAt: now.subtract(const Duration(days: 3)),
        ),
      ];

      final earned = await service.checkNoWasteWeekBadge(items, wastedItems);

      expect(earned, isFalse);
    });

    test('returns false when history is shorter than 7 days', () async {
      final now = DateTime.now();
      final items = <Item>[
        buildItem(
          id: '1',
          status: ItemStatus.available,
          createdAt: now.subtract(const Duration(days: 3)),
          updatedAt: now,
        ),
      ];

      final earned = await service.checkNoWasteWeekBadge(items, const <Item>[]);

      expect(earned, isFalse);
    });

    test('returns false when there are no tracked items', () async {
      final earned = await service.checkNoWasteWeekBadge(
        const <Item>[],
        const <Item>[],
      );

      expect(earned, isFalse);
    });
  });
}
