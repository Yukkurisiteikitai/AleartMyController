import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/daos/amc_attachment_dao.dart';
import '../data/local/daos/amc_draft_dao.dart';
import '../data/local/daos/analytics_dao.dart';
import '../data/local/daos/event_dao.dart';
import '../data/local/daos/memo_dao.dart';
import '../data/local/daos/observation_event_dao.dart';
import '../data/local/daos/photo_dao.dart';
import '../data/local/daos/record_dao.dart';
import '../data/local/database.dart';

/// drift AppDatabase（プロセス内シングルトン）。
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final eventDaoProvider =
    Provider<EventDao>((ref) => ref.watch(appDatabaseProvider).eventDao);
final observationEventDaoProvider = Provider<ObservationEventDao>(
    (ref) => ref.watch(appDatabaseProvider).observationEventDao);
final recordDaoProvider =
    Provider<RecordDao>((ref) => ref.watch(appDatabaseProvider).recordDao);
final photoDaoProvider =
    Provider<PhotoDao>((ref) => ref.watch(appDatabaseProvider).photoDao);
final memoDaoProvider =
    Provider<MemoDao>((ref) => ref.watch(appDatabaseProvider).memoDao);
final analyticsDaoProvider = Provider<AnalyticsDao>(
    (ref) => ref.watch(appDatabaseProvider).analyticsDao);
final amcDraftDaoProvider =
    Provider<AmcDraftDao>((ref) => ref.watch(appDatabaseProvider).amcDraftDao);
final amcAttachmentDaoProvider = Provider<AmcAttachmentDao>(
    (ref) => ref.watch(appDatabaseProvider).amcAttachmentDao);
