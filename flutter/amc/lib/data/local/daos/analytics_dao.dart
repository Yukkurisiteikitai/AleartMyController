import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'analytics_dao.g.dart';

// ---- 集計結果データクラス（Android AnalyticsDao の POJO 相当）----

class DailyRecordCount {
  const DailyRecordCount({
    required this.dayKey,
    required this.totalCount,
    required this.photoCount,
    required this.memoCount,
  });

  final int dayKey; // epoch_millis / 86400000 (UTC 日キー)
  final int totalCount;
  final int photoCount;
  final int memoCount;
}

class RecordTypeCount {
  const RecordTypeCount({required this.recordType, required this.count});

  final String recordType; // "photo" or "memo"
  final int count;
}

class EventRecordCount {
  const EventRecordCount({required this.eventTitle, required this.recordCount});

  final String eventTitle;
  final int recordCount;
}

@DriftAccessor(tables: [Records, ObservationEvents])
class AnalyticsDao extends DatabaseAccessor<AppDatabase>
    with _$AnalyticsDaoMixin {
  AnalyticsDao(super.attachedDatabase);

  Future<int> getTotalCount(int fromMillis) async {
    final row = await customSelect(
      'SELECT COUNT(*) AS c FROM records WHERE record_time >= ?',
      variables: [Variable.withInt(fromMillis)],
      readsFrom: {records},
    ).getSingle();
    return row.read<int>('c');
  }

  Future<int> getPhotoCount(int fromMillis) async {
    final row = await customSelect(
      "SELECT COUNT(*) AS c FROM records WHERE record_time >= ? AND record_type = 'photo'",
      variables: [Variable.withInt(fromMillis)],
      readsFrom: {records},
    ).getSingle();
    return row.read<int>('c');
  }

  Future<int> getMemoCount(int fromMillis) async {
    final row = await customSelect(
      "SELECT COUNT(*) AS c FROM records WHERE record_time >= ? AND record_type = 'memo'",
      variables: [Variable.withInt(fromMillis)],
      readsFrom: {records},
    ).getSingle();
    return row.read<int>('c');
  }

  Future<List<DailyRecordCount>> getDailyRecordCounts(int fromMillis) async {
    final rows = await customSelect(
      '''
      SELECT (record_time / 86400000) AS day_key,
             COUNT(*) AS total_count,
             SUM(CASE WHEN record_type = 'photo' THEN 1 ELSE 0 END) AS photo_count,
             SUM(CASE WHEN record_type = 'memo'  THEN 1 ELSE 0 END) AS memo_count
      FROM records
      WHERE record_time >= ?
      GROUP BY day_key
      ORDER BY day_key ASC
      ''',
      variables: [Variable.withInt(fromMillis)],
      readsFrom: {records},
    ).get();
    return rows
        .map(
          (row) => DailyRecordCount(
            dayKey: row.read<int>('day_key'),
            totalCount: row.read<int>('total_count'),
            photoCount: row.read<int?>('photo_count') ?? 0,
            memoCount: row.read<int?>('memo_count') ?? 0,
          ),
        )
        .toList();
  }

  Future<List<RecordTypeCount>> getRecordTypeBreakdown(int fromMillis) async {
    final rows = await customSelect(
      '''
      SELECT record_type, COUNT(*) AS count
      FROM records
      WHERE record_time >= ?
      GROUP BY record_type
      ''',
      variables: [Variable.withInt(fromMillis)],
      readsFrom: {records},
    ).get();
    return rows
        .map(
          (row) => RecordTypeCount(
            recordType: row.read<String>('record_type'),
            count: row.read<int>('count'),
          ),
        )
        .toList();
  }

  Future<List<EventRecordCount>> getTopEventsByRecordCount(int fromMillis) async {
    final rows = await customSelect(
      '''
      SELECT oe.title AS event_title, COUNT(r.record_id) AS record_count
      FROM records r
      INNER JOIN observation_events oe ON r.obs_event_id = oe.obs_event_id
      WHERE r.record_time >= ?
      GROUP BY r.obs_event_id
      ORDER BY record_count DESC
      LIMIT 10
      ''',
      variables: [Variable.withInt(fromMillis)],
      readsFrom: {records, observationEvents},
    ).get();
    return rows
        .map(
          (row) => EventRecordCount(
            eventTitle: row.read<String>('event_title'),
            recordCount: row.read<int>('record_count'),
          ),
        )
        .toList();
  }
}
