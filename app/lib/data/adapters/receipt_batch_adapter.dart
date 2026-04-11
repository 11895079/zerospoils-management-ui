import 'package:hive/hive.dart';
import '../../domain/models/receipt_batch.dart';

const receiptBatchAdapterTypeId = 30;
const receiptBatchItemAdapterTypeId = 31;

class ReceiptBatchItemAdapter extends TypeAdapter<ReceiptBatchItem> {
  @override
  final int typeId = receiptBatchItemAdapterTypeId;

  @override
  ReceiptBatchItem read(BinaryReader reader) {
    final id = reader.readString();
    final name = reader.readString();
    final price = reader.readDouble();
    final quantity = reader.readInt();
    final destinationIndex = reader.readByte();
    final hasInventoryId = reader.readBool();
    final inventoryId = hasInventoryId ? reader.readString() : null;
    final hasShoppingId = reader.readBool();
    final shoppingId = hasShoppingId ? reader.readString() : null;

    return ReceiptBatchItem(
      id: id,
      name: name,
      price: price,
      quantity: quantity,
      destination: ReceiptBatchDestination.values[destinationIndex],
      inventoryItemId: inventoryId,
      shoppingListItemId: shoppingId,
    );
  }

  @override
  void write(BinaryWriter writer, ReceiptBatchItem obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeDouble(obj.price);
    writer.writeInt(obj.quantity);
    writer.writeByte(obj.destination.index);
    writer.writeBool(obj.inventoryItemId != null);
    if (obj.inventoryItemId != null) {
      writer.writeString(obj.inventoryItemId!);
    }
    writer.writeBool(obj.shoppingListItemId != null);
    if (obj.shoppingListItemId != null) {
      writer.writeString(obj.shoppingListItemId!);
    }
  }
}

class ReceiptBatchAdapter extends TypeAdapter<ReceiptBatch> {
  @override
  final int typeId = receiptBatchAdapterTypeId;

  @override
  ReceiptBatch read(BinaryReader reader) {
    final id = reader.readString();
    final createdAt = reader.read() as DateTime;
    DateTime? purchasedAt;
    try {
      final hasPurchasedAt = reader.readBool();
      purchasedAt = hasPurchasedAt ? reader.read() as DateTime : null;
    } catch (_) {
      purchasedAt = null;
    }
    String? storeName;
    try {
      final hasStoreName = reader.readBool();
      storeName = hasStoreName ? reader.readString() : null;
    } catch (_) {
      storeName = null;
    }
    double? totalAmount;
    try {
      final hasTotalAmount = reader.readBool();
      totalAmount = hasTotalAmount ? reader.readDouble() : null;
    } catch (_) {
      totalAmount = null;
    }
    final sourceIndex = reader.readByte();
    final items = reader.readList().cast<ReceiptBatchItem>();
    final receiptImagePaths = reader.readList().cast<String>();
    List<String> goodsImagePaths;
    try {
      goodsImagePaths = reader.readList().cast<String>();
    } catch (_) {
      goodsImagePaths = const [];
    }

    return ReceiptBatch(
      id: id,
      createdAt: createdAt,
      purchasedAt: purchasedAt,
      storeName: storeName,
      totalAmount: totalAmount,
      source: ReceiptBatchSource.values[sourceIndex],
      items: items,
      receiptImagePaths: receiptImagePaths,
      goodsImagePaths: goodsImagePaths,
    );
  }

  @override
  void write(BinaryWriter writer, ReceiptBatch obj) {
    writer.writeString(obj.id);
    writer.write(obj.createdAt);
    writer.writeBool(obj.purchasedAt != null);
    if (obj.purchasedAt != null) {
      writer.write(obj.purchasedAt);
    }
    writer.writeBool(obj.storeName != null && obj.storeName!.isNotEmpty);
    if (obj.storeName != null && obj.storeName!.isNotEmpty) {
      writer.writeString(obj.storeName!);
    }
    writer.writeBool(obj.totalAmount != null);
    if (obj.totalAmount != null) {
      writer.writeDouble(obj.totalAmount!);
    }
    writer.writeByte(obj.source.index);
    writer.writeList(obj.items);
    writer.writeList(obj.receiptImagePaths);
    writer.writeList(obj.goodsImagePaths);
  }
}
