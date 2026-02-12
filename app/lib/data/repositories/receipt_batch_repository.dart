import 'package:hive/hive.dart';
import '../../domain/models/receipt_batch.dart';

abstract class ReceiptBatchRepository {
  Future<void> init();
  Future<void> saveBatch(ReceiptBatch batch);
  Future<List<ReceiptBatch>> getAllBatches();
  Future<ReceiptBatch?> getBatch(String id);
}

class HiveReceiptBatchRepository implements ReceiptBatchRepository {
  static const String _boxName = 'receipt_batches';
  Box<ReceiptBatch>? _box;

  @override
  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<ReceiptBatch>(_boxName);
    } else {
      _box = Hive.box<ReceiptBatch>(_boxName);
    }
  }

  @override
  Future<void> saveBatch(ReceiptBatch batch) async {
    if (_box == null) throw Exception('Repository not initialized');
    await _box!.put(batch.id, batch);
  }

  @override
  Future<List<ReceiptBatch>> getAllBatches() async {
    if (_box == null) throw Exception('Repository not initialized');
    final batches = _box!.values.toList();
    batches.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return batches;
  }

  @override
  Future<ReceiptBatch?> getBatch(String id) async {
    if (_box == null) throw Exception('Repository not initialized');
    return _box!.get(id);
  }
}
