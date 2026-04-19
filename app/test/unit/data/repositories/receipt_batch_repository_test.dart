import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:zerospoils/data/repositories/receipt_batch_repository.dart';
import 'package:zerospoils/domain/models/receipt_batch.dart';

class _FakeReceiptBatchBox extends Fake implements Box<ReceiptBatch> {}

class _FakeHiveInterface extends Fake implements HiveInterface {
  _FakeHiveInterface({required Box<ReceiptBatch> box}) : _box = box;

  final Box<ReceiptBatch> _box;
  int openBoxCalls = 0;
  bool deletedCorruptBox = false;

  @override
  bool isBoxOpen(String name) => false;

  @override
  Future<Box<E>> openBox<E>(
    String name, {
    HiveCipher? encryptionCipher,
    List<int>? encryptionKey,
    KeyComparator? keyComparator,
    CompactionStrategy? compactionStrategy,
    bool crashRecovery = true,
    String? path,
    Uint8List? bytes,
    String? collection,
  }) async {
    openBoxCalls += 1;
    if (openBoxCalls == 1) {
      throw HiveError('corrupt receipt batch box');
    }
    return _box as Box<E>;
  }

  @override
  Future<void> deleteBoxFromDisk(String name, {String? path}) async {
    deletedCorruptBox = true;
  }
}

void main() {
  test('init recreates receipt batch box after open failure', () async {
    final fakeHive = _FakeHiveInterface(box: _FakeReceiptBatchBox());
    final repository = HiveReceiptBatchRepository(hive: fakeHive);

    await repository.init();

    expect(fakeHive.deletedCorruptBox, true);
    expect(fakeHive.openBoxCalls, 2);
  });
}
