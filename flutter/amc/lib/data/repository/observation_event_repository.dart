import 'package:drift/drift.dart';

import '../local/daos/observation_event_dao.dart';
import '../local/database.dart';

/// ObservationEvent の findOrCreate を担う（Android: ObservationEventRepository 相当）。
class ObservationEventRepository {
  ObservationEventRepository(this._dao);

  final ObservationEventDao _dao;

  /// Event(カレンダーキャッシュ) に対応する ObservationEvent の obsEventId を返す。
  ///
  /// 不変条件(§9): insert-or-ignore のセマンティクス。重複 googleEventId では
  /// 既存の obsEventId を返す。drift の insertOrIgnore は戻り値が信頼できないため、
  /// 常に [ObservationEventDao.findByGoogleEventId] で解決する。
  Future<int> findOrCreate(Event event) async {
    await _dao.insertOrIgnore(
      ObservationEventsCompanion.insert(
        googleEventId: Value(event.googleEventId),
        title: event.title,
        startTime: event.startTime,
        endTime: event.endTime,
      ),
    );
    final existing = await _dao.findByGoogleEventId(event.googleEventId);
    return existing!.obsEventId;
  }

  Future<ObservationEvent?> findById(int obsEventId) => _dao.findById(obsEventId);

  /// cloud pull 専用: 既存行があれば返し、なければ新規作成する。
  /// Event row を持たないクラウド由来レコードに使う（Event.googleEventId の代わりに生の文字列で解決）。
  Future<int> findOrCreateByRaw({
    required String googleEventId,
    required String title,
    required int startTime,
    required int endTime,
  }) async {
    final existing = await _dao.findByGoogleEventId(googleEventId);
    if (existing != null) return existing.obsEventId;
    await _dao.insertOrIgnore(
      ObservationEventsCompanion.insert(
        googleEventId: Value(googleEventId),
        title: title,
        startTime: startTime,
        endTime: endTime,
      ),
    );
    final created = await _dao.findByGoogleEventId(googleEventId);
    return created!.obsEventId;
  }
}
