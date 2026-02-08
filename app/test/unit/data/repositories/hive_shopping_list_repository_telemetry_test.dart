import 'package:flutter_test/flutter_test.dart';
import 'package:hive_test/hive_test.dart';
import 'package:zerospoils/data/repositories/hive_shopping_list_repository.dart';
import 'package:zerospoils/domain/models/shopping_list_item.dart';

class TestTelemetryClient {
  final List<Map<String, dynamic>> events = [];

  void emit(String name, Map<String, dynamic> properties) {
    events.add({'name': name, 'properties': properties});
  }
}

void main() {
  group('HiveShoppingListRepository Telemetry', () {
    late HiveShoppingListRepository repository;
    late TestTelemetryClient telemetry;

    setUp(() async {
      await setUpTestHive();
      telemetry = TestTelemetryClient();
      repository = HiveShoppingListRepository();
      repository.setTelemetryCallback(telemetry.emit);
      await repository.init();
      await repository.clear();
    });

    test('emits shopping_list_item_added on save', () async {
      final item = ShoppingListItem(
        id: 's1',
        name: 'Milk',
        category: 'Dairy',
        quantity: 2,
        unit: 'L',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.saveShoppingListItem(item);

      final event = telemetry.events.firstWhere(
        (e) => e['name'] == 'shopping_list_item_added',
      );
      final properties = event['properties'] as Map<String, dynamic>;
      expect(properties['item_id'], 's1');
      expect(properties['source'], 'manual');
    });

    test('emits shopping_list_item_purchased with days_to_purchase', () async {
      final createdAt = DateTime.now().subtract(const Duration(days: 5));
      final item = ShoppingListItem(
        id: 's2',
        name: 'Bread',
        createdAt: createdAt,
        updatedAt: createdAt,
      );

      await repository.saveShoppingListItem(item);
      await repository.markAsPurchased(item.id);

      final event = telemetry.events.firstWhere(
        (e) => e['name'] == 'shopping_list_item_purchased',
      );
      final properties = event['properties'] as Map<String, dynamic>;
      expect(properties['item_id'], 's2');
      expect(properties['days_to_purchase'], isA<int>());
      expect(properties['days_to_purchase'], greaterThanOrEqualTo(5));
    });

    test('emits shopping_list_item_deleted on delete', () async {
      final now = DateTime.now();
      final item = ShoppingListItem(
        id: 's3',
        name: 'Apples',
        createdAt: now,
        updatedAt: now,
      );

      await repository.saveShoppingListItem(item);
      await repository.deleteItem(item.id);

      expect(
        telemetry.events.any((e) => e['name'] == 'shopping_list_item_deleted'),
        isTrue,
      );
    });
  });
}
