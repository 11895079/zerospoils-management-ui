library;

import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'user_category.g.dart';

@HiveType(typeId: 22)
class UserCategory extends Equatable {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String? icon;
  @HiveField(3)
  final int? color;
  @HiveField(4)
  final DateTime createdAt;

  const UserCategory({
    required this.id,
    required this.name,
    this.icon,
    this.color,
    required this.createdAt,
  });

  UserCategory copyWith({
    String? id,
    String? name,
    String? icon,
    int? color,
    DateTime? createdAt,
  }) {
    return UserCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, icon, color, createdAt];
}
