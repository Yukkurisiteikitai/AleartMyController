import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database.dart';
import '../../providers/repository_providers.dart';

/// 記録詳細画面の状態。
class RecordDetailState {
  const RecordDetailState({
    this.record,
    this.photos = const [],
    this.memos = const [],
    this.isLoading = true,
    this.notFound = false,
  });

  final Record? record;
  final List<Photo> photos;
  final List<Memo> memos;
  final bool isLoading;
  final bool notFound;
}

/// 記録詳細画面の状態管理（Android: RecordDetailViewModel 相当）。
///
/// 表示のみ。副作用なし（§9 不変条件）。
/// Riverpod 3.x: family arg をコンストラクタで受け取る。
class RecordDetailNotifier extends AsyncNotifier<RecordDetailState> {
  RecordDetailNotifier(this.recordId);

  final int recordId;

  @override
  Future<RecordDetailState> build() async {
    final repo = ref.read(recordRepositoryProvider);
    final record = await repo.findRecordById(recordId);
    if (record == null) {
      return const RecordDetailState(isLoading: false, notFound: true);
    }
    final photos = await repo.getPhotosForRecord(recordId);
    final memos = await repo.getMemosForRecord(recordId);
    return RecordDetailState(
      record: record,
      photos: photos,
      memos: memos,
      isLoading: false,
    );
  }
}

/// RecordDetail Notifier の Provider（recordId ファミリ）。
final recordDetailNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<RecordDetailNotifier, RecordDetailState, int>(
  RecordDetailNotifier.new,
);
