library;

/// Hive type adapters for Item model enums
/// Required for Hive to serialize/deserialize our domain models

import 'package:hive/hive.dart';
import '../../domain/models/item_model.dart';

// ItemCategory adapter (type ID: 1)
class ItemCategoryAdapter extends TypeAdapter<ItemCategory> {
  @override
  final int typeId = 1;

  @override
  ItemCategory read(BinaryReader reader) {
    final index = reader.readByte();
    return ItemCategory.values[index];
  }

  @override
  void write(BinaryWriter writer, ItemCategory obj) {
    writer.writeByte(obj.index);
  }
}

// StorageLocation adapter (type ID: 2)
class StorageLocationAdapter extends TypeAdapter<StorageLocation> {
  @override
  final int typeId = 2;

  @override
  StorageLocation read(BinaryReader reader) {
    final index = reader.readByte();
    return StorageLocation.values[index];
  }

  @override
  void write(BinaryWriter writer, StorageLocation obj) {
    writer.writeByte(obj.index);
  }
}

// ItemStatus adapter (type ID: 3)
class ItemStatusAdapter extends TypeAdapter<ItemStatus> {
  @override
  final int typeId = 3;

  @override
  ItemStatus read(BinaryReader reader) {
    final index = reader.readByte();
    return ItemStatus.values[index];
  }

  @override
  void write(BinaryWriter writer, ItemStatus obj) {
    writer.writeByte(obj.index);
  }
}

// WasteReason adapter (type ID: 4)
class WasteReasonAdapter extends TypeAdapter<WasteReason> {
  @override
  final int typeId = 4;

  @override
  WasteReason read(BinaryReader reader) {
    final index = reader.readByte();
    return WasteReason.values[index];
  }

  @override
  void write(BinaryWriter writer, WasteReason obj) {
    writer.writeByte(obj.index);
  }
}

// Item adapter (type ID: 0)
class ItemAdapter extends TypeAdapter<Item> {
  @override
  final int typeId = 0;

  @override
  Item read(BinaryReader reader) {
    return Item(
      id: reader.readString(),
      name: reader.readString(),
      category: ItemCategory.values[reader.readByte()],
      location: StorageLocation.values[reader.readByte()],
      quantity: reader.readInt(),
      expiryDate: reader.read() as DateTime?,
      purchasePrice: reader.read() as double?,
      status: ItemStatus.values[reader.readByte()],
      wasteReason: reader.readBool()
          ? WasteReason.values[reader.readByte()]
          : null,
      createdAt: reader.read() as DateTime,
      updatedAt: reader.read() as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Item obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeByte(obj.category.index);
    writer.writeByte(obj.location.index);
    writer.writeInt(obj.quantity);
    writer.write(obj.expiryDate);
    writer.write(obj.purchasePrice);
    writer.writeByte(obj.status.index);
    writer.writeBool(obj.wasteReason != null);
    if (obj.wasteReason != null) {
      writer.writeByte(obj.wasteReason!.index);
    }
    writer.write(obj.createdAt);
    writer.write(obj.updatedAt);
  }
}
