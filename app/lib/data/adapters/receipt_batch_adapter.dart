import 'package:hive/hive.dart';
import '../../domain/models/receipt_batch.dart';

class ReceiptBatchItemAdapter extends TypeAdapter<ReceiptBatchItem> {
  @override
  final int typeId = 31;

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
  final int typeId = 30;

  @override
  ReceiptBatch read(BinaryReader reader) {
    final id = reader.readString();
    final createdAt = reader.read() as DateTime;
    final sourceIndex = reader.readByte();
    final items = reader.readList().cast<ReceiptBatchItem>();
    final receiptImagePaths = reader.readList().cast<String>();

    return ReceiptBatch(
      id: id,
      createdAt: createdAt,
      source: ReceiptBatchSource.values[sourceIndex],
      items: items,
      receiptImagePaths: receiptImagePaths,
    );
  }

  @override
  void write(BinaryWriter writer, ReceiptBatch obj) {
    writer.writeString(obj.id);
    writer.write(obj.createdAt);
    writer.writeByte(obj.source.index);
    writer.writeList(obj.items);
    writer.writeList(obj.receiptImagePaths);
  }
}
