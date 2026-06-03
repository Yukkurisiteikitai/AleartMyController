import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/daos/record_dao.dart';
import '../../data/local/database.dart';
import '../../providers/database_providers.dart';
import '../../providers/repository_providers.dart';

/// イベント一覧画面の状態。
class EventListState {
  const EventListState({
    this.events = const [],
    this.counts = const [],
    this.isSyncing = false,
    this.syncError,
  });

  final List<Event> events;
  final List<RecordCountResult> counts;
  final bool isSyncing;
  final String? syncError;

  /// 特定イベントの集計結果を返す（存在しない場合は 0 件）。
  RecordCountResult countFor(int eventId) {
    return counts.firstWhere(
      (c) => c.eventId == eventId,
      orElse: () =>
          RecordCountResult(eventId: eventId, photoCount: 0, memoCount: 0),
    );
  }

  EventListState copyWith({
    List<Event>? events,
    List<RecordCountResult>? counts,
    bool? isSyncing,
    Object? syncError = _sentinel,
  }) {
    return EventListState(
      events: events ?? this.events,
      counts: counts ?? this.counts,
      isSyncing: isSyncing ?? this.isSyncing,
      syncError:
          syncError == _sentinel ? this.syncError : syncError as String?,
    );
  }
}

const _sentinel = Object();

/// イベント一覧ページの状態管理（Android: EventListViewModel 相当）。
///
/// - upcoming events を watchUpcomingEvents() で Stream 購読。
/// - バッジ集計は countByEvents()（LEFT JOIN、記録0件も表示）。
/// - local-draft:% プレフィックスのイベントは Repository 側で担保済み（§9）。
class EventListNotifier extends Notifier<EventListState> {
  StreamSubscription<List<Event>>? _eventsSub;

  @override
  EventListState build() {
    final eventRepo = ref.watch(eventRepositoryProvider);

    _eventsSub?.cancel();
    _eventsSub = eventRepo.watchUpcomingEvents().listen((events) {
      _onEventsUpdated(events);
    });

    ref.onDispose(() => _eventsSub?.cancel());

    return const EventListState();
  }

  Future<void> _onEventsUpdated(List<Event> events) async {
    final recordDao = ref.read(recordDaoProvider);
    final eventIds = events.map((e) => e.eventId).toList();
    final counts = await recordDao.countByEvents(eventIds);
    state = state.copyWith(events: events, counts: counts);
  }

  /// Google Calendar から同期する。
  Future<void> syncFromCalendar() async {
    if (state.isSyncing) return;
    state = state.copyWith(isSyncing: true, syncError: null);
    try {
      final eventRepo = ref.read(eventRepositoryProvider);
      await eventRepo.syncFromCalendar();
      state = state.copyWith(isSyncing: false);
    } catch (e) {
      state = state.copyWith(isSyncing: false, syncError: e.toString());
    }
  }

  /// イベントを削除する（records は巻き込まない、§9）。
  /// 確認ダイアログは Screen 側で担う。
  Future<void> deleteEvent(int eventId) async {
    final eventDao = ref.read(eventDaoProvider);
    await eventDao.deleteById(eventId);
  }
}

/// イベント一覧 Notifier の Provider。
final eventListNotifierProvider =
    NotifierProvider.autoDispose<EventListNotifier, EventListState>(
  EventListNotifier.new,
);
