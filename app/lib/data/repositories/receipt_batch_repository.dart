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
  final HiveInterface _hive;
  Box<ReceiptBatch>? _box;

  HiveReceiptBatchRepository({HiveInterface? hive}) : _hive = hive ?? Hive;

  @override
  Future<void> init() async {
    if (_box != null && _box!.isOpen) {
      return;
    }

    if (_hive.isBoxOpen(_boxName)) {
      _box = _hive.box<ReceiptBatch>(_boxName);
      return;
    }

    try {
      _box = await _hive.openBox<ReceiptBatch>(_boxName);
    } catch (_) {
      await _hive.deleteBoxFromDisk(_boxName);
      _box = await _hive.openBox<ReceiptBatch>(_boxName);
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
