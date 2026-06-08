// 名前付き引数 + private フィールドのため initializing formal は使えない（言語仕様）。
// ignore_for_file: prefer_initializing_formals
import 'package:drift/drift.dart' show Value;
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:rxdart/rxdart.dart';
import 'package:synchronized/synchronized.dart';
import 'package:uuid/uuid.dart';

import '../../core/content_policy.dart';
import '../local/daos/event_dao.dart';
import '../local/daos/observation_event_dao.dart';
import '../local/database.dart';
import '../local/tables.dart';
import '../remote/google_calendar_api.dart';

/// イベントのローカル監視 + Google Calendar 同期 + 下書きライフサイクル
/// （Android: EventRepository 相当）。
class EventRepository {
  EventRepository({
    required EventDao eventDao,
    required ObservationEventDao observationEventDao,
    required GoogleCalendarApi calendarApi,
  })  : _eventDao = eventDao,
        _observationEventDao = observationEventDao,
        _calendarApi = calendarApi;

  final EventDao _eventDao;
  final ObservationEventDao _observationEventDao;
  final GoogleCalendarApi _calendarApi;

  static const _uuid = Uuid();

  /// googleEventId ごとのロック（並行メモ追記の競合防止、§9）。
  final Map<String, Lock> _memoLocks = {};
  Lock _lockFor(String googleEventId) =>
      _memoLocks.putIfAbsent(googleEventId, Lock.new);

  bool _isLocalDraft(String googleEventId) =>
      googleEventId.startsWith(localDraftGoogleIdPrefix);

  // ---- ローカル監視 ----

  Stream<List<Event>> watchUpcomingEvents() =>
      _eventDao.watchUpcoming(DateTime.now().millisecondsSinceEpoch);

  Future<List<Event>> getUpcomingEventsOnce() =>
      _eventDao.getUpcoming(DateTime.now().millisecondsSinceEpoch);

  Stream<List<Event>> watchAllEvents() => _eventDao.watchAll();

  Future<Event?> findById(int id) => _eventDao.findById(id);

  Future<Event?> getOngoingEvent() =>
      _eventDao.findOngoing(DateTime.now().millisecondsSinceEpoch);

  /// 進行中イベントを監視する。1 分ごとに現在時刻を引き直し、drift Stream に流す。
  /// （Android: 60 秒ティッカー + flatMapLatest 相当、§3.4）。
  Stream<Event?> observeOngoingEvent() {
    return Stream<int>.periodic(
      const Duration(seconds: 60),
      (_) => DateTime.now().millisecondsSinceEpoch,
    ).startWith(DateTime.now().millisecondsSinceEpoch).switchMap(
          (now) => _eventDao.watchOngoing(now),
        );
  }

  // ---- Google Calendar 同期 ----

  /// 今日〜7日後のイベントを取得して DB へ upsert し、古いキャッシュを削除する。
  Future<void> syncFromCalendar() async {
    final now = DateTime.now();
    final weekLater = now.add(const Duration(days: 7));
    final response =
        await _calendarApi.listEvents(timeMin: now, timeMax: weekLater);

    // 同じ Google ID は後勝ちで上書き（重複除去）。
    final byGoogleId = <String, EventsCompanion>{};
    for (final item in response.items ?? <gcal.Event>[]) {
      final id = item.id;
      final start = _toMillis(item.start);
      final end = _toMillis(item.end);
      if (id == null || start == null || end == null) continue;
      byGoogleId[id] = EventsCompanion.insert(
        googleEventId: id,
        title: item.summary ?? '(無題)',
        startTime: start,
        endTime: end,
      );
    }

    await _eventDao.upsertAll(byGoogleId.values.toList());
    final activeIds = byGoogleId.keys.toList();
    if (activeIds.isNotEmpty) {
      await _eventDao.deleteStaleEvents(activeIds);
    }
  }

  // ---- 突発下書き ----

  Future<Event> createDraftEvent(String title) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final googleId = '$localDraftGoogleIdPrefix${_uuid.v4()}';
    final id = await _eventDao.upsert(
      EventsCompanion.insert(
        googleEventId: googleId,
        title: title,
        startTime: now,
        endTime: now + 60 * 60 * 1000,
      ),
    );
    return (await _eventDao.findById(id))!;
  }

  Future<Event> closeDraftEvent(int eventId, int endTimeMillis) async {
    final draft = await _eventDao.findById(eventId);
    if (draft == null) throw StateError('Event not found: $eventId');
    if (!_isLocalDraft(draft.googleEventId)) {
      throw StateError('Not a draft event: ${draft.googleEventId}');
    }
    await _eventDao.upsert(_replace(draft, endTime: endTimeMillis));
    return (await _eventDao.findById(eventId))!;
  }

  /// 下書きを Google Calendar に確定し、observation_events の googleEventId を
  /// 実 ID へ付け替える(§9)。googleEventId 別ロックで保護する。
  Future<Event> finalizeDraftEvent(int eventId, String? description) async {
    final draft = await _eventDao.findById(eventId);
    if (draft == null) throw StateError('Event not found: $eventId');
    if (!_isLocalDraft(draft.googleEventId)) {
      throw StateError('Not a draft event: ${draft.googleEventId}');
    }

    return _lockFor(draft.googleEventId).synchronized(() async {
      final desc = (description != null && description.trim().isNotEmpty)
          ? description
          : null;
      final inserted = await _calendarApi.insertEvent(
        summary: draft.title,
        description: desc,
        startMillis: draft.startTime,
        endMillis: draft.endTime,
      );
      final newGoogleId = inserted.id!;
      await _eventDao.upsert(_replace(draft, googleEventId: newGoogleId));
      await _observationEventDao.updateGoogleId(
        oldGoogleId: draft.googleEventId,
        newGoogleId: newGoogleId,
        title: draft.title,
        startTime: draft.startTime,
        endTime: draft.endTime,
      );
      return (await _eventDao.findById(eventId))!;
    });
  }

  /// 既存 Google イベントの description にメモを追記（ミラー）。
  /// 下書き・空文字はスキップ。googleEventId 別ロックで保護する(§9)。
  Future<void> appendMemoToGoogleEvent(Event event, String memoText) async {
    if (memoText.trim().isEmpty || _isLocalDraft(event.googleEventId)) return;

    await _lockFor(event.googleEventId).synchronized(() async {
      final remote = await _calendarApi.getEvent(event.googleEventId);
      final parts = <String>[
        if ((remote.description ?? '').trim().isNotEmpty)
          remote.description!.trim(),
        memoText.trim(),
      ];
      final description =
          AmcContentPolicy.buildCalendarMirrorBody(parts.join('\n\n'));
      await _calendarApi.patchEvent(event.googleEventId,
          description: description);
    });
  }

  // ---- helpers ----

  /// 同じ eventId 行を全フィールド指定で置き換える（upsert は InsertMode.replace）。
  EventsCompanion _replace(
    Event base, {
    String? googleEventId,
    int? endTime,
  }) {
    return EventsCompanion(
      eventId: Value(base.eventId),
      googleEventId: Value(googleEventId ?? base.googleEventId),
      title: Value(base.title),
      startTime: Value(base.startTime),
      endTime: Value(endTime ?? base.endTime),
    );
  }

  int? _toMillis(gcal.EventDateTime? dt) {
    if (dt == null) return null;
    // 終日イベントは date のみ（dateTime が null）→ date にフォールバック(§5.1)。
    final value = dt.dateTime ?? dt.date;
    return value?.millisecondsSinceEpoch;
  }
}
