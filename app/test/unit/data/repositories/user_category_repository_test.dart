import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:zerospoils/data/repositories/user_category_repository.dart';
import 'package:zerospoils/domain/models/user_category.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserCategoryRepository', () {
    late UserCategoryRepository repository;
    late Directory tempDir;

    setUpAll(() async {
      tempDir = Directory.systemTemp.createTempSync('user_category_test_');
      Hive.init(tempDir.path);

      if (!Hive.isAdapterRegistered(22)) {
        Hive.registerAdapter(UserCategoryAdapter());
      }
    });

    tearDownAll(() async {
      await Hive.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    setUp(() async {
      repository = UserCategoryRepository();
      await repository.init();
      await Hive.box<UserCategory>('user_categories').clear();
    });

    tearDown(() async {
      try {
        await Hive.box<UserCategory>('user_categories').clear();
      } catch (_) {}
    });

    test('upsert saves and getAll returns categories', () async {
      final category = UserCategory(
        id: 'cat-1',
        name: 'School Snacks',
        createdAt: DateTime.now(),
      );

      await repository.upsert(category);
      final categories = await repository.getAll();

      expect(categories.length, equals(1));
      expect(categories.first.name, equals('School Snacks'));
    });

    test('getById returns category', () async {
      final category = UserCategory(
        id: 'cat-2',
        name: 'Supplements',
        createdAt: DateTime.now(),
      );

      await repository.upsert(category);
      final result = await repository.getById('cat-2');

      expect(result, isNotNull);
      expect(result!.name, equals('Supplements'));
    });

    test('upsert updates existing category', () async {
      final category = UserCategory(
        id: 'cat-3',
        name: 'Snacks',
        createdAt: DateTime.now(),
      );

      await repository.upsert(category);
      await repository.upsert(category.copyWith(name: 'School Snacks'));

      final updated = await repository.getById('cat-3');
      expect(updated!.name, equals('School Snacks'));
    });

    test('delete removes category', () async {
      final category = UserCategory(
        id: 'cat-4',
        name: 'Ethnic Foods',
        createdAt: DateTime.now(),
      );

      await repository.upsert(category);
      await repository.delete('cat-4');

      final result = await repository.getById('cat-4');
      expect(result, isNull);
    });
  });
}
