import 'package:drift/drift.dart';

/// UI 用ローカルテーブル群（migration_plan.md §3.1）。
///
/// Android Room の設計をそのまま再現する:
/// - events: Google Calendar キャッシュ（自由に削除可、子を持たない）
/// - observation_events: 永続スナップショット。events への FK は張らない（ソフト参照）
/// - records → observation_events に CASCADE
/// - photos / memos → records に CASCADE
///
/// 不変条件(§9): events 削除が records/写真/メモを巻き込まない
/// （records は observation_events を参照し、events は参照しないため）。

/// 記録タイプ。drift は enum.name（"photo" / "memo"）を保存する。
/// 生 SQL の比較リテラルも小文字（'photo' / 'memo'）に合わせること。
enum RecordType { photo, memo }

/// local-draft イベントの googleEventId プレフィックス（EventEntity.isLocalDraft 相当）。
const String localDraftGoogleIdPrefix = 'local-draft:';

@DataClassName('Event')
class Events extends Table {
  IntColumn get eventId => integer().autoIncrement()();
  TextColumn get googleEventId => text()();
  TextColumn get title => text()();
  IntColumn get startTime => integer()(); // epoch millis
  IntColumn get endTime => integer()(); // epoch millis

  @override
  List<Set<Column>> get uniqueKeys => [
        {googleEventId},
      ];
}

@DataClassName('ObservationEvent')
class ObservationEvents extends Table {
  IntColumn get obsEventId => integer().autoIncrement()();
  TextColumn get googleEventId => text().nullable()(); // soft ref, no FK to events
  TextColumn get title => text()();
  IntColumn get startTime => integer()(); // snapshot at session start
  IntColumn get endTime => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {googleEventId},
      ];
}

@DataClassName('Record')
@TableIndex(name: 'idx_records_obs_event_id', columns: {#obsEventId})
class Records extends Table {
  IntColumn get recordId => integer().autoIncrement()();
  IntColumn get obsEventId => integer()
      .references(ObservationEvents, #obsEventId, onDelete: KeyAction.cascade)();
  IntColumn get recordTime => integer()(); // epoch millis
  TextColumn get recordType => textEnum<RecordType>()();
}

@DataClassName('Photo')
@TableIndex(name: 'idx_photos_record_id', columns: {#recordId})
class Photos extends Table {
  IntColumn get photoId => integer().autoIncrement()();
  IntColumn get recordId =>
      integer().references(Records, #recordId, onDelete: KeyAction.cascade)();
  TextColumn get filePath => text()();
}

@DataClassName('Memo')
@TableIndex(name: 'idx_memos_record_id', columns: {#recordId})
class Memos extends Table {
  IntColumn get memoId => integer().autoIncrement()();
  IntColumn get recordId =>
      integer().references(Records, #recordId, onDelete: KeyAction.cascade)();
  TextColumn get memoText => text()();
  BoolColumn get isVoiceMemo => boolean().withDefault(const Constant(false))();
}
