import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'shopping_list_item.g.dart';

@HiveType(typeId: 20)
class ShoppingListItem extends Equatable {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String? category;
  @HiveField(3)
  final int quantity;
  @HiveField(4)
  final String? unit;
  @HiveField(5)
  final double? estimatedCost;
  @HiveField(6)
  final bool isPurchased;
  @HiveField(7)
  final DateTime? purchasedAt;
  @HiveField(8)
  final String? notes;
  @HiveField(9)
  final DateTime createdAt;
  @HiveField(10)
  final DateTime updatedAt;

  const ShoppingListItem({
    required this.id,
    required this.name,
    this.category,
    this.quantity = 1,
    this.unit,
    this.estimatedCost,
    this.isPurchased = false,
    this.purchasedAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  ShoppingListItem copyWith({
    String? id,
    String? name,
    String? category,
    int? quantity,
    String? unit,
    double? estimatedCost,
    bool? isPurchased,
    DateTime? purchasedAt,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShoppingListItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      isPurchased: isPurchased ?? this.isPurchased,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    category,
    quantity,
    unit,
    estimatedCost,
    isPurchased,
    purchasedAt,
    notes,
    createdAt,
    updatedAt,
  ];
}
