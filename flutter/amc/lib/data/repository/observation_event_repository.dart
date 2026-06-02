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
}
