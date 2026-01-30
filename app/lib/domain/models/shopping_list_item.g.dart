// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_list_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShoppingListItemAdapter extends TypeAdapter<ShoppingListItem> {
  @override
  final int typeId = 20;

  @override
  ShoppingListItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ShoppingListItem(
      id: fields[0] as String,
      name: fields[1] as String,
      category: fields[2] as String?,
      quantity: fields[3] as int,
      unit: fields[4] as String?,
      estimatedCost: fields[5] as double?,
      isPurchased: fields[6] as bool,
      purchasedAt: fields[7] as DateTime?,
      notes: fields[8] as String?,
      createdAt: fields[9] as DateTime,
      updatedAt: fields[10] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ShoppingListItem obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.unit)
      ..writeByte(5)
      ..write(obj.estimatedCost)
      ..writeByte(6)
      ..write(obj.isPurchased)
      ..writeByte(7)
      ..write(obj.purchasedAt)
      ..writeByte(8)
      ..write(obj.notes)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShoppingListItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
