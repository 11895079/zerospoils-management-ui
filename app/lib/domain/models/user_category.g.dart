// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_category.dart';

// ***************************************************************************
// TypeAdapterGenerator
// ***************************************************************************

class UserCategoryAdapter extends TypeAdapter<UserCategory> {
  @override
  final int typeId = 22;

  @override
  UserCategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserCategory(
      id: fields[0] as String,
      name: fields[1] as String,
      icon: fields[2] as String?,
      color: fields[3] as int?,
      createdAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, UserCategory obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.icon)
      ..writeByte(3)
      ..write(obj.color)
      ..writeByte(4)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
