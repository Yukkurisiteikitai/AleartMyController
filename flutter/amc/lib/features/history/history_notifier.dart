import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/daos/record_dao.dart';
import '../../providers/repository_providers.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

/// 全履歴画面の状態（Android: HistoryViewModel 相当）。
///
/// - Events / ObservationEvents / Records の 3 テーブル JOIN 結果を表示する（§9 不変条件）。
/// - `watchAllRecordsWithAttachments()` を使用して Stream を購読する。
class HistoryState {
  const HistoryState({
    this.records = const [],
    this.isLoading = true,
    this.error,
  });

  final List<RecordWithAttachments> records;
  final bool isLoading;
  final String? error;

  HistoryState copyWith({
    List<RecordWithAttachments>? records,
    bool? isLoading,
    Object? error = _sentinel,
  }) {
    return HistoryState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      error: error == _sentinel ? this.error : error as String?,
    );
  }
}

const _sentinel = Object();

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// 全履歴画面の状態管理（Android: HistoryViewModel 相当、migration_plan.md §6.2）。
///
/// - `recordRepository.watchAllRecordsWithAttachments()` を購読して全記録を取得する。
/// - 3 テーブル JOIN（events → observation_events → records）は RecordDao / RecordRepository 内部で実施済み。
class HistoryNotifier extends Notifier<HistoryState> {
  @override
  HistoryState build() {
    final sub = ref
        .watch(recordRepositoryProvider)
        .watchAllRecordsWithAttachments()
        .listen(
      (records) {
        state = state.copyWith(records: records, isLoading: false, error: null);
      },
      onError: (Object e) {
        state = state.copyWith(isLoading: false, error: e.toString());
      },
    );
    ref.onDispose(sub.cancel);

    return const HistoryState();
  }
}

final historyNotifierProvider =
    NotifierProvider<HistoryNotifier, HistoryState>(HistoryNotifier.new);
