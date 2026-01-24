library;

import 'package:hive/hive.dart';
import 'package:zerospoils/domain/models/item_model.dart';

/// Hive adapter for ItemCategory enum
class ItemCategoryAdapter extends TypeAdapter<ItemCategory> {
  @override
  final int typeId = 0;

  @override
  ItemCategory read(BinaryReader reader) {
    final value = reader.readString();
    return ItemCategory.fromString(value);
  }

  @override
  void write(BinaryWriter writer, ItemCategory obj) {
    writer.writeString(obj.name);
  }
}
