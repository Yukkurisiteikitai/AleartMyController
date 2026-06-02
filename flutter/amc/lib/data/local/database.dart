import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'amc_tables.dart';
import 'daos/amc_attachment_dao.dart';
import 'daos/amc_draft_dao.dart';
import 'daos/analytics_dao.dart';
import 'daos/event_dao.dart';
import 'daos/memo_dao.dart';
import 'daos/observation_event_dao.dart';
import 'daos/photo_dao.dart';
import 'daos/record_dao.dart';
import 'tables.dart';

part 'database.g.dart';

/// drift AppDatabase（migration_plan.md §3）。
///
/// UI 用 5 表 + AMC キュー 3 表。schemaVersion = 1 から開始（Android Room の
/// v1→v8 マイグレーション履歴は移植しない、§3.3）。
@DriftDatabase(
  tables: [
    Events,
    ObservationEvents,
    Records,
    Photos,
    Memos,
    AmcDraftRecords,
    AmcRecordRevisions,
    AmcAttachmentQueue,
  ],
  daos: [
    EventDao,
    ObservationEventDao,
    RecordDao,
    PhotoDao,
    MemoDao,
    AnalyticsDao,
    AmcDraftDao,
    AmcAttachmentDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// 本番用。executor 省略時は端末のドキュメント領域に永続化する。
  /// テストでは `AppDatabase(NativeDatabase.memory())` のように executor を注入する。
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'amc'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        beforeOpen: (details) async {
          // CASCADE を効かせるため外部キー制約を有効化（§3.1 注意書き）。
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
