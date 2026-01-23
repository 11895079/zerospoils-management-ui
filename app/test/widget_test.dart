// Basic widget test for ZeroSpoils app
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zerospoils/main.dart';
import 'package:zerospoils/domain/models/item_model.dart';
import 'package:zerospoils/data/repositories/hive_item_repository.dart';
import 'package:zerospoils/presentation/di/repository_providers.dart';

// Lightweight in-memory mock to avoid Hive I/O during widget tests
class MockItemRepository extends HiveItemRepository {
  bool _initialized = false;
  final Map<String, Item> _items = {};

  @override
  Future<void> init() async {
    _initialized = true;
  }

  @override
  Future<List<Item>> getAllItems() async {
    if (!_initialized) throw Exception('Repository not initialized');
    return _items.values.toList();
  }

  @override
  Future<Item?> getItem(String id) async {
    if (!_initialized) throw Exception('Repository not initialized');
    return _items[id];
  }

  @override
  Future<void> saveItem(Item item) async {
    if (!_initialized) throw Exception('Repository not initialized');
    _items[item.id] = item;
  }

  @override
  Future<void> deleteItem(String id) async {
    if (!_initialized) throw Exception('Repository not initialized');
    _items.remove(id);
  }
}

void main() {
  testWidgets('App launches and renders home screen', (
    WidgetTester tester,
  ) async {
    // Build our app with mock repository to avoid disk I/O
    final mockRepo = MockItemRepository();
    await mockRepo.init();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [hiveItemRepositoryProvider.overrideWithValue(mockRepo)],
        child: const ZeroSpoilsApp(),
      ),
    );

    // Wait for async initialization
    await tester.pumpAndSettle();

    // Verify that the bottom navigation bar is rendered
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    // Verify all 4 tab labels are present (using short labels from BottomNavigationBar)
    expect(find.text('Inventory'), findsWidgets);
    expect(find.text('Expiring'), findsWidgets);
    expect(find.text('Shopping'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);

    // Verify floating action button is present on inventory tab
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
