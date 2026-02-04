// Event model for audit log persistence (M2/102)
import 'package:hive/hive.dart';
import 'dart:convert';

part 'event.g.dart';

@HiveType(typeId: 20)
class Event extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String? itemId;
  @HiveField(2)
  final EventType eventType;
  @HiveField(3)
  final DateTime timestamp;
  @HiveField(4)
  final String metadataJson;

  Event({
    required this.id,
    required this.eventType,
    required this.timestamp,
    required this.metadataJson,
    this.itemId,
  });

  Map<String, dynamic> get metadata => jsonDecode(metadataJson);
}

@HiveType(typeId: 21)
enum EventType {
  @HiveField(0)
  itemCreated,
  @HiveField(1)
  itemConsumed,
  @HiveField(2)
  itemWasted,
  @HiveField(3)
  itemEdited,
  @HiveField(4)
  itemDeleted,
  @HiveField(5)
  appInstalled,
}
