import '../models/item_model.dart';
import '../models/receipt_batch.dart';

class ReceiptBatchStats {
  final double totalSpend;
  final double consumedValue;
  final double wastedValue;
  final double remainingValue;

  const ReceiptBatchStats({
    required this.totalSpend,
    required this.consumedValue,
    required this.wastedValue,
    required this.remainingValue,
  });
}

class ReceiptBatchStatsService {
  ReceiptBatchStats build({
    required ReceiptBatch batch,
    required List<Item> inventoryItems,
  }) {
    final inventoryMap = {for (final item in inventoryItems) item.id: item};

    double consumed = 0;
    double wasted = 0;
    double remaining = 0;

    for (final batchItem in batch.items) {
      final value = batchItem.price * batchItem.quantity;
      if (batchItem.destination != ReceiptBatchDestination.inventory) {
        remaining += value;
        continue;
      }
      final inventoryItem = inventoryMap[batchItem.inventoryItemId];

      if (inventoryItem == null) {
        remaining += value;
        continue;
      }

      switch (inventoryItem.status) {
        case ItemStatus.consumed:
          consumed += value;
          break;
        case ItemStatus.wasted:
          wasted += value;
          break;
        case ItemStatus.available:
          remaining += value;
          break;
      }
    }

    return ReceiptBatchStats(
      totalSpend: batch.totalSpend,
      consumedValue: _round(consumed),
      wastedValue: _round(wasted),
      remainingValue: _round(remaining),
    );
  }

  double _round(double value) => double.parse(value.toStringAsFixed(2));
}
