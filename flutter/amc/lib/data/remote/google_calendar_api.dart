import 'package:googleapis/calendar/v3.dart' as gcal;

import '../repository/auth_repository.dart';

/// googleapis CalendarApi のラッパ（Android: GoogleCalendarApi 相当、§5.1）。
class GoogleCalendarApi {
  GoogleCalendarApi(this._auth);

  final AuthRepository _auth;

  static const String _calendarId = 'primary';

  Future<gcal.CalendarApi> _api() async {
    final client = await _auth.calendarAuthClient();
    if (client == null) {
      throw StateError('Google Calendar に未サインインです');
    }
    return gcal.CalendarApi(client);
  }

  /// 期間内のイベントを開始時刻順で取得する（単一イベント展開）。
  Future<gcal.Events> listEvents({
    required DateTime timeMin,
    required DateTime timeMax,
  }) async {
    final api = await _api();
    return api.events.list(
      _calendarId,
      timeMin: timeMin.toUtc(),
      timeMax: timeMax.toUtc(),
      singleEvents: true,
      orderBy: 'startTime',
    );
  }

  Future<gcal.Event> getEvent(String eventId) async {
    final api = await _api();
    return api.events.get(_calendarId, eventId);
  }

  Future<gcal.Event> insertEvent({
    required String summary,
    String? description,
    required int startMillis,
    required int endMillis,
  }) async {
    final api = await _api();
    final event = gcal.Event()
      ..summary = summary
      ..description = description
      ..start = (gcal.EventDateTime()
        ..dateTime = DateTime.fromMillisecondsSinceEpoch(startMillis).toUtc())
      ..end = (gcal.EventDateTime()
        ..dateTime = DateTime.fromMillisecondsSinceEpoch(endMillis).toUtc());
    return api.events.insert(event, _calendarId);
  }

  Future<gcal.Event> patchEvent(
    String eventId, {
    String? description,
  }) async {
    final api = await _api();
    final patch = gcal.Event()..description = description;
    return api.events.patch(patch, _calendarId, eventId);
  }
}
