// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EventAdapter extends TypeAdapter<Event> {
  @override
  final int typeId = 20;

  @override
  Event read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Event(
      id: fields[0] as String,
      eventType: fields[2] as EventType,
      timestamp: fields[3] as DateTime,
      metadataJson: fields[4] as String,
      itemId: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Event obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.itemId)
      ..writeByte(2)
      ..write(obj.eventType)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.metadataJson);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EventTypeAdapter extends TypeAdapter<EventType> {
  @override
  final int typeId = 21;

  @override
  EventType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return EventType.itemCreated;
      case 1:
        return EventType.itemConsumed;
      case 2:
        return EventType.itemWasted;
      case 3:
        return EventType.itemEdited;
      case 4:
        return EventType.itemDeleted;
      case 5:
        return EventType.appInstalled;
      default:
        return EventType.itemCreated;
    }
  }

  @override
  void write(BinaryWriter writer, EventType obj) {
    switch (obj) {
      case EventType.itemCreated:
        writer.writeByte(0);
        break;
      case EventType.itemConsumed:
        writer.writeByte(1);
        break;
      case EventType.itemWasted:
        writer.writeByte(2);
        break;
      case EventType.itemEdited:
        writer.writeByte(3);
        break;
      case EventType.itemDeleted:
        writer.writeByte(4);
        break;
      case EventType.appInstalled:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
