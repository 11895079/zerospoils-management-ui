library;

import 'package:hive/hive.dart';
import '../../domain/models/user_category.dart';

class UserCategoryRepository {
  static const String _boxName = 'user_categories';
  final HiveInterface _hive;

  UserCategoryRepository({HiveInterface? hive}) : _hive = hive ?? Hive;

  Future<void> init() async {
    if (!_hive.isBoxOpen(_boxName)) {
      await _hive.openBox<UserCategory>(_boxName);
    }
  }

  Box<UserCategory> _box() => _hive.box<UserCategory>(_boxName);

  Future<List<UserCategory>> getAll() async {
    await init();
    return _box().values.toList();
  }

  Future<void> upsert(UserCategory category) async {
    await init();
    await _box().put(category.id, category);
  }

  Future<void> delete(String id) async {
    await init();
    await _box().delete(id);
  }

  Future<UserCategory?> getById(String id) async {
    await init();
    return _box().get(id);
  }
}
