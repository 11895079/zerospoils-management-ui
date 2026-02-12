import 'package:equatable/equatable.dart';

enum ReceiptBatchSource { inventory, shoppingList }

enum ReceiptBatchDestination { inventory, shoppingList }

class ReceiptBatchItem extends Equatable {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final ReceiptBatchDestination destination;
  final String? inventoryItemId;
  final String? shoppingListItemId;

  const ReceiptBatchItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.destination,
    this.inventoryItemId,
    this.shoppingListItemId,
  });

  ReceiptBatchItem copyWith({
    String? id,
    String? name,
    double? price,
    int? quantity,
    ReceiptBatchDestination? destination,
    String? inventoryItemId,
    String? shoppingListItemId,
  }) {
    return ReceiptBatchItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      destination: destination ?? this.destination,
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      shoppingListItemId: shoppingListItemId ?? this.shoppingListItemId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    price,
    quantity,
    destination,
    inventoryItemId,
    shoppingListItemId,
  ];
}

class ReceiptBatch extends Equatable {
  final String id;
  final DateTime createdAt;
  final ReceiptBatchSource source;
  final List<ReceiptBatchItem> items;
  final List<String> receiptImagePaths;

  const ReceiptBatch({
    required this.id,
    required this.createdAt,
    required this.source,
    required this.items,
    this.receiptImagePaths = const [],
  });

  double get totalSpend =>
      items.fold(0, (sum, item) => sum + (item.price * item.quantity));

  ReceiptBatch copyWith({
    String? id,
    DateTime? createdAt,
    ReceiptBatchSource? source,
    List<ReceiptBatchItem>? items,
    List<String>? receiptImagePaths,
  }) {
    return ReceiptBatch(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      source: source ?? this.source,
      items: items ?? this.items,
      receiptImagePaths: receiptImagePaths ?? this.receiptImagePaths,
    );
  }

  @override
  List<Object?> get props => [id, createdAt, source, items, receiptImagePaths];
}
