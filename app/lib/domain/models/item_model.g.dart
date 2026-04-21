// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ItemAdapter extends TypeAdapter<Item> {
  @override
  final int typeId = 0;

  @override
  Item read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Item(
      id: fields[0] as String,
      name: fields[1] as String,
      brand: fields[17] as String?,
      receiptBatchId: fields[18] as String?,
      receiptBatchItemId: fields[19] as String?,
      category: fields[2] as ItemCategory,
      type: fields[3] as ItemType,
      preparedDate: fields[4] as DateTime?,
      location: fields[5] as StorageLocation,
      quantity: fields[6] as int,
      unit: fields[7] as Unit,
      expiryDate: fields[8] as DateTime?,
      purchasePrice: fields[9] as double?,
      status: fields[10] as ItemStatus,
      wasteReason: fields[11] as WasteReason?,
      customCategoryId: fields[15] as String?,
      customCategoryName: fields[16] as String?,
      createdAt: fields[12] as DateTime,
      updatedAt: fields[13] as DateTime,
      wastePercentage: fields[14] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Item obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(17)
      ..write(obj.brand)
      ..writeByte(18)
      ..write(obj.receiptBatchId)
      ..writeByte(19)
      ..write(obj.receiptBatchItemId)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.preparedDate)
      ..writeByte(5)
      ..write(obj.location)
      ..writeByte(6)
      ..write(obj.quantity)
      ..writeByte(7)
      ..write(obj.unit)
      ..writeByte(8)
      ..write(obj.expiryDate)
      ..writeByte(9)
      ..write(obj.purchasePrice)
      ..writeByte(10)
      ..write(obj.status)
      ..writeByte(11)
      ..write(obj.wasteReason)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.updatedAt)
      ..writeByte(14)
      ..write(obj.wastePercentage)
      ..writeByte(15)
      ..write(obj.customCategoryId)
      ..writeByte(16)
      ..write(obj.customCategoryName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
