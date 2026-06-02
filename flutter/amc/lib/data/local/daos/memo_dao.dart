import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'memo_dao.g.dart';

@DriftAccessor(tables: [Memos])
class MemoDao extends DatabaseAccessor<AppDatabase> with _$MemoDaoMixin {
  MemoDao(super.attachedDatabase);

  Future<int> insertMemo(MemosCompanion memo) => into(memos).insert(memo);

  Future<void> deleteById(int memoId) =>
      (delete(memos)..where((t) => t.memoId.equals(memoId))).go();

  Stream<List<Memo>> watchByRecord(int recordId) =>
      (select(memos)..where((t) => t.recordId.equals(recordId))).watch();

  Future<List<Memo>> findByRecord(int recordId) =>
      (select(memos)..where((t) => t.recordId.equals(recordId))).get();
}
