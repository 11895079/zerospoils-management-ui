import 'package:equatable/equatable.dart';
enum ReceiptBatchSource { inventory, shoppingList }

enum PaymentMethod { cash, credit, debit, mobile, other }

extension PaymentMethodLabel on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.credit:
        return 'Credit';
      case PaymentMethod.debit:
        return 'Debit';
      case PaymentMethod.mobile:
        return 'Mobile Pay';
      case PaymentMethod.other:
        return 'Other';
    }
  }
}

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
  final DateTime? purchasedAt;
  final String? storeName;
  final double? totalAmount;
  final ReceiptBatchSource source;
  final List<ReceiptBatchItem> items;
  final List<String> receiptImagePaths;
  final List<String> goodsImagePaths;
  final PaymentMethod? paymentMethod;

  const ReceiptBatch({
    required this.id,
    required this.createdAt,
    this.purchasedAt,
    this.storeName,
    this.totalAmount,
    required this.source,
    required this.items,
    this.receiptImagePaths = const [],
    this.goodsImagePaths = const [],
    this.paymentMethod,
  });

  double get totalSpend =>
      totalAmount ??
      items.fold(0, (sum, item) => sum + (item.price * item.quantity));

  ReceiptBatch copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? purchasedAt,
    String? storeName,
    double? totalAmount,
    ReceiptBatchSource? source,
    List<ReceiptBatchItem>? items,
    List<String>? receiptImagePaths,
    List<String>? goodsImagePaths,
    PaymentMethod? paymentMethod,
  }) {
    return ReceiptBatch(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      storeName: storeName ?? this.storeName,
      totalAmount: totalAmount ?? this.totalAmount,
      source: source ?? this.source,
      items: items ?? this.items,
      receiptImagePaths: receiptImagePaths ?? this.receiptImagePaths,
      goodsImagePaths: goodsImagePaths ?? this.goodsImagePaths,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  @override
  List<Object?> get props => [
    id,
    createdAt,
    purchasedAt,
    storeName,
    totalAmount,
    source,
    items,
    receiptImagePaths,
    goodsImagePaths,
    paymentMethod,
  ];
}
