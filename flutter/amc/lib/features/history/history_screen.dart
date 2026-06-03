import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/local/daos/record_dao.dart';
import '../../data/local/tables.dart';
import 'history_notifier.dart';

/// 履歴画面（Android: HistoryScreen / HistoryViewModel 相当）。
///
/// 全記録（写真・メモ）を最新順で一覧表示する。
/// Events / ObservationEvents / Records の 3 テーブル JOIN 結果を表示する（§9 不変条件）。
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(historyNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('履歴'),
        actions: [
          if (!state.isLoading && state.error == null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  '${state.records.length} 件',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
        ],
      ),
      body: _HistoryBody(state: state),
    );
  }
}

class _HistoryBody extends StatelessWidget {
  const _HistoryBody({required this.state});

  final HistoryState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              '読み込みエラー',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              state.error!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (state.records.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('記録がありません'),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.records.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = state.records[index];
        return _RecordListTile(item: item);
      },
    );
  }
}

class _RecordListTile extends StatelessWidget {
  const _RecordListTile({required this.item});

  final RecordWithAttachments item;

  @override
  Widget build(BuildContext context) {
    final record = item.record;
    final isPhoto = record.recordType == RecordType.photo;
    final dateStr = DateFormat('yyyy/MM/dd HH:mm').format(
      DateTime.fromMillisecondsSinceEpoch(record.recordTime),
    );

    final subtitle = isPhoto
        ? '写真 ${item.photos.length} 枚'
        : item.memos.isNotEmpty
            ? item.memos.first.memoText
            : 'メモ';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isPhoto
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.secondaryContainer,
        child: Icon(
          isPhoto ? Icons.photo_camera_outlined : Icons.notes,
          color: isPhoto
              ? Theme.of(context).colorScheme.onPrimaryContainer
              : Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
      title: Text(dateStr, style: Theme.of(context).textTheme.bodyMedium),
      subtitle: Text(
        subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/record/${record.recordId}'),
    );
  }
}
