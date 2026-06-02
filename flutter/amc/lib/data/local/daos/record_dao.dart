import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'record_dao.g.dart';

/// 記録本体 + 添付（写真・メモ）をまとめた POJO（Android: RecordWithAttachments 相当）。
class RecordWithAttachments {
  const RecordWithAttachments({
    required this.record,
    required this.photos,
    required this.memos,
  });

  final Record record;
  final List<Photo> photos;
  final List<Memo> memos;
}

/// イベント一覧のバッジ表示用集計結果（Android: RecordCountResult 相当）。
class RecordCountResult {
  const RecordCountResult({
    required this.eventId,
    required this.photoCount,
    required this.memoCount,
  });

  final int eventId;
  final int photoCount;
  final int memoCount;
}

@DriftAccessor(tables: [Records, Photos, Memos, ObservationEvents, Events])
class RecordDao extends DatabaseAccessor<AppDatabase> with _$RecordDaoMixin {
  RecordDao(super.attachedDatabase);

  Future<int> insertRecord(RecordsCompanion record) =>
      into(records).insert(record);

  Future<Record?> findById(int recordId) =>
      (select(records)..where((t) => t.recordId.equals(recordId)))
          .getSingleOrNull();

  Future<void> deleteById(int recordId) =>
      (delete(records)..where((t) => t.recordId.equals(recordId))).go();

  /// カレンダーイベント(Events.eventId)に紐づく記録を時刻昇順で監視。
  /// events → observation_events → records の JOIN で解決する（§3.4 / Android 同等）。
  Stream<List<Record>> watchByEvent(int eventId) {
    final query = select(records).join([
      innerJoin(
        observationEvents,
        observationEvents.obsEventId.equalsExp(records.obsEventId),
      ),
      innerJoin(
        events,
        events.googleEventId.equalsExp(observationEvents.googleEventId),
      ),
    ])
      ..where(events.eventId.equals(eventId))
      ..orderBy([OrderingTerm.asc(records.recordTime)]);
    return query.watch().map(
          (rows) => rows.map((r) => r.readTable(records)).toList(),
        );
  }

  /// イベントに紐づく記録を時刻昇順で監視（添付込み）。
  Stream<List<RecordWithAttachments>> watchByEventWithAttachments(int eventId) {
    return watchByEvent(eventId).asyncMap(_withAttachments);
  }

  /// 全記録を最新順で監視（全履歴表示用）。
  Stream<List<Record>> watchAll() {
    return (select(records)
          ..orderBy([(t) => OrderingTerm.desc(t.recordTime)]))
        .watch();
  }

  /// 全記録を最新順で監視（添付込み）。
  Stream<List<RecordWithAttachments>> watchAllWithAttachments() {
    return watchAll().asyncMap(_withAttachments);
  }

  Future<List<RecordWithAttachments>> _withAttachments(List<Record> recs) async {
    final result = <RecordWithAttachments>[];
    for (final rec in recs) {
      final ph = await (select(photos)
            ..where((t) => t.recordId.equals(rec.recordId)))
          .get();
      final me = await (select(memos)
            ..where((t) => t.recordId.equals(rec.recordId)))
          .get();
      result.add(RecordWithAttachments(record: rec, photos: ph, memos: me));
    }
    return result;
  }

  /// 写真・メモ件数の一括集計（イベント一覧バッジ用、LEFT JOIN）。
  /// 引数は Events.eventId のリスト。記録が無いイベントも count=0 で返る。
  Future<List<RecordCountResult>> countByEvents(List<int> eventIds) async {
    if (eventIds.isEmpty) return const [];
    final placeholders = List.filled(eventIds.length, '?').join(',');
    final rows = await customSelect(
      '''
      SELECT e.event_id AS event_id,
             SUM(CASE WHEN r.record_type = 'photo' THEN 1 ELSE 0 END) AS photo_count,
             SUM(CASE WHEN r.record_type = 'memo'  THEN 1 ELSE 0 END) AS memo_count
      FROM events e
      LEFT JOIN observation_events oe ON oe.google_event_id = e.google_event_id
      LEFT JOIN records r ON r.obs_event_id = oe.obs_event_id
      WHERE e.event_id IN ($placeholders)
      GROUP BY e.event_id
      ''',
      variables: eventIds.map((id) => Variable.withInt(id)).toList(),
      readsFrom: {events, observationEvents, records},
    ).get();
    return rows
        .map(
          (row) => RecordCountResult(
            eventId: row.read<int>('event_id'),
            photoCount: row.read<int?>('photo_count') ?? 0,
            memoCount: row.read<int?>('memo_count') ?? 0,
          ),
        )
        .toList();
  }
}
