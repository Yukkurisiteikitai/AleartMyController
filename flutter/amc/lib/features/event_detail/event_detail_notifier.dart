import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/daos/record_dao.dart';
import '../../data/local/database.dart';
import '../../providers/repository_providers.dart';

/// イベント詳細画面の状態。
class EventDetailState {
  const EventDetailState({
    this.event,
    this.records = const [],
    this.isLoading = true,
    this.notFound = false,
  });

  final Event? event;
  final List<RecordWithAttachments> records;
  final bool isLoading;
  final bool notFound;

  EventDetailState copyWith({
    Event? event,
    List<RecordWithAttachments>? records,
    bool? isLoading,
    bool? notFound,
  }) {
    return EventDetailState(
      event: event ?? this.event,
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      notFound: notFound ?? this.notFound,
    );
  }
}

/// イベント詳細画面の状態管理（Android: EventDetailViewModel 相当）。
///
/// Riverpod 3.x: family arg を コンストラクタで受け取る。
class EventDetailNotifier extends Notifier<EventDetailState> {
  EventDetailNotifier(this.eventId);

  final int eventId;

  StreamSubscription<List<RecordWithAttachments>>? _recordsSub;

  @override
  EventDetailState build() {
    final eventRepo = ref.watch(eventRepositoryProvider);
    final recordRepo = ref.watch(recordRepositoryProvider);

    _load(eventRepo, recordRepo, eventId);
    ref.onDispose(() => _recordsSub?.cancel());

    return const EventDetailState();
  }

  Future<void> _load(dynamic eventRepo, dynamic recordRepo, int id) async {
    final event = await eventRepo.findById(id);
    if (event == null) {
      state = state.copyWith(isLoading: false, notFound: true);
      return;
    }
    state = state.copyWith(event: event, isLoading: false);

    _recordsSub?.cancel();
    _recordsSub =
        recordRepo.watchRecordsByEventWithAttachments(id).listen((records) {
      state = state.copyWith(records: records);
    });
  }

  /// 記録を削除する（records → photos/memos は CASCADE で削除される）。
  Future<void> deleteRecord(int recordId) async {
    final recordRepo = ref.read(recordRepositoryProvider);
    await recordRepo.deleteRecord(recordId);
  }
}

/// EventDetail Notifier の Provider（eventId ファミリ）。
final eventDetailNotifierProvider = NotifierProvider.autoDispose
    .family<EventDetailNotifier, EventDetailState, int>(
  EventDetailNotifier.new,
);
