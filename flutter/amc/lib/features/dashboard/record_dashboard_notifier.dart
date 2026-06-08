import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database.dart';
import '../../data/repository/event_repository.dart';
import '../../data/repository/record_repository.dart';
import '../../providers/repository_providers.dart';

// ============================================================
//  State
// ============================================================

/// ダッシュボード画面の状態。
///
/// [event] : 進行中（または指定された）イベント。null = イベントなし。
/// [records] : そのイベントに紐づく記録一覧（最新順）。
/// [elapsedSeconds] : イベント開始からの経過秒数（タイマー用）。
/// [isStopping] : 停止確認モード（長押し中）。
/// [message] : SnackBar 等で表示するワンショットメッセージ。null = 無し。
class RecordDashboardState {
  const RecordDashboardState({
    this.event,
    this.records = const [],
    this.elapsedSeconds = 0,
    this.isStopping = false,
    this.message,
  });

  final Event? event;
  final List<Record> records;
  final int elapsedSeconds;
  final bool isStopping;
  final String? message;

  RecordDashboardState copyWith({
    Object? event = _sentinel,
    List<Record>? records,
    int? elapsedSeconds,
    bool? isStopping,
    Object? message = _sentinel,
  }) {
    return RecordDashboardState(
      event: event == _sentinel ? this.event : event as Event?,
      records: records ?? this.records,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isStopping: isStopping ?? this.isStopping,
      message: message == _sentinel ? this.message : message as String?,
    );
  }
}

const _sentinel = Object();

// ============================================================
//  Notifier
// ============================================================

/// 記録ダッシュボードの状態管理（Android: RecordDashboardViewModel 相当）。
///
/// 担当:
/// - 進行中イベントの結合（eventId 指定 or observeOngoingEvent() で取得）
/// - 記録一覧の Stream 購読
/// - 1 秒周期タイマーで elapsedSeconds を更新（§9 不変条件）
/// - 長押し / ダブルタップ停止（GestureDetector で受け取り、§9 不変条件）
/// - 下書きイベントの確定（closeDraftEvent + finalizeDraftEvent）
class RecordDashboardNotifier extends Notifier<RecordDashboardState> {
  StreamSubscription<Event?>? _eventSub;
  StreamSubscription<List<Record>>? _recordSub;
  Timer? _timer;

  EventRepository get _eventRepo => ref.read(eventRepositoryProvider);
  RecordRepository get _recordRepo => ref.read(recordRepositoryProvider);

  @override
  RecordDashboardState build() {
    ref.onDispose(_dispose);
    return const RecordDashboardState();
  }

  // ---- 初期化 ----

  /// 画面マウント時に呼ぶ。[eventId] が指定されていればそのイベントを固定で使う。
  /// null の場合は observeOngoingEvent() で進行中イベントを追従する。
  void init(int? eventId) {
    _dispose();
    if (eventId != null) {
      _startWithFixedEvent(eventId);
    } else {
      _startWithOngoingEvent();
    }
  }

  void _startWithFixedEvent(int eventId) {
    _eventRepo.findById(eventId).then((event) {
      if (event != null) {
        _onEventChanged(event);
      }
    });
  }

  void _startWithOngoingEvent() {
    _eventSub = _eventRepo.observeOngoingEvent().listen(_onEventChanged);
  }

  void _onEventChanged(Event? event) {
    if (event == null) {
      _stopTimer();
      _recordSub?.cancel();
      _recordSub = null;
      state = const RecordDashboardState();
      return;
    }

    // イベントが変わった場合のみ記録購読を張り替える。
    if (state.event?.eventId != event.eventId) {
      _recordSub?.cancel();
      _recordSub = _recordRepo
          .watchRecordsByEvent(event.eventId)
          .listen((records) {
        state = state.copyWith(records: records);
      });
    }

    // タイマーを開始（既に動いていればリセット）。
    _startTimer(event.startTime);
    state = state.copyWith(event: event, isStopping: false, message: null);
  }

  // ---- タイマー（§9: Stream.periodic(Duration(seconds: 1))） ----

  void _startTimer(int startTimeMillis) {
    _stopTimer();
    // 初回値を即反映。
    final now = DateTime.now().millisecondsSinceEpoch;
    state = state.copyWith(
      elapsedSeconds: ((now - startTimeMillis) ~/ 1000).clamp(0, 1 << 30),
    );

    // 1 秒周期の periodic ストリームで更新する。
    StreamSubscription<int>? sub;
    sub = Stream.periodic(const Duration(seconds: 1), (_) {
      return ((DateTime.now().millisecondsSinceEpoch - startTimeMillis) ~/
              1000)
          .clamp(0, 1 << 30);
    }).listen((seconds) {
      state = state.copyWith(elapsedSeconds: seconds);
    });
    _timerSub = sub;
  }

  StreamSubscription<int>? _timerSub;

  void _stopTimer() {
    _timerSub?.cancel();
    _timerSub = null;
    _timer?.cancel();
    _timer = null;
  }

  // ---- 停止操作（§9: 長押し / ダブルタップ） ----

  /// 長押し開始: 停止確認モードへ移行する。
  void onLongPressStart() {
    if (state.event == null) return;
    state = state.copyWith(isStopping: true);
  }

  /// 長押しキャンセル: 停止確認モードを解除する。
  void onLongPressCancel() {
    state = state.copyWith(isStopping: false);
  }

  /// 長押し確定（指を離したとき）: イベントを終了する。
  Future<void> onLongPressEnd() async {
    if (!state.isStopping) return;
    await _stopEvent();
  }

  /// ダブルタップ: 即時停止する（§9）。
  Future<void> onDoubleTap() async {
    if (state.event == null) return;
    await _stopEvent();
  }

  // ---- 内部: 停止 + 下書き確定 ----

  Future<void> _stopEvent() async {
    final event = state.event;
    if (event == null) return;

    final endTime = DateTime.now().millisecondsSinceEpoch;
    try {
      // 下書きイベントの場合は endTime を更新し、Google Calendar へ確定する。
      final isLocalDraft =
          event.googleEventId.startsWith('local-draft:');
      if (isLocalDraft) {
        await _eventRepo.closeDraftEvent(event.eventId, endTime);
        await _eventRepo.finalizeDraftEvent(event.eventId, null);
      }
      // 停止後は状態をクリアして完了メッセージを出す。
      _stopTimer();
      _recordSub?.cancel();
      _recordSub = null;
      state = RecordDashboardState(message: '記録を終了しました');
    } catch (e) {
      state = state.copyWith(
        isStopping: false,
        message: '終了に失敗しました: $e',
      );
    }
  }

  // ---- メッセージ消費 ----

  /// SnackBar 表示後に呼んでメッセージをクリアする。
  void consumeMessage() {
    state = state.copyWith(message: null);
  }

  // ---- dispose ----

  void _dispose() {
    _eventSub?.cancel();
    _recordSub?.cancel();
    _timerSub?.cancel();
    _timer?.cancel();
    _eventSub = null;
    _recordSub = null;
    _timerSub = null;
    _timer = null;
  }
}

// ============================================================
//  Provider
// ============================================================

final recordDashboardProvider =
    NotifierProvider<RecordDashboardNotifier, RecordDashboardState>(
  RecordDashboardNotifier.new,
);
