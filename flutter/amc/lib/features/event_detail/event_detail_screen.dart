import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/local/daos/record_dao.dart';
import '../../data/local/database.dart';
import '../../data/local/tables.dart';
import 'event_detail_notifier.dart';

/// イベント詳細画面（Android: EventDetailScreen / EventDetailViewModel 相当）。
///
/// - Event のタイトル・日時ヘッダー。
/// - 記録（写真・メモ）のタイムライン（添付込み）。
/// - 記録追加ボタン（FAB → /add-record/:eventId）。
/// - 記録削除は確認ダイアログ。
class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final int eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(eventDetailNotifierProvider(eventId));
    final notifier = ref.read(eventDetailNotifierProvider(eventId).notifier);

    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('イベント詳細')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.notFound || state.event == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('イベント詳細')),
        body: const Center(child: Text('イベントが見つかりません')),
      );
    }

    final event = state.event!;
    final start = DateTime.fromMillisecondsSinceEpoch(event.startTime);
    final end = DateTime.fromMillisecondsSinceEpoch(event.endTime);
    final dateFmt = DateFormat('yyyy年M月d日(E)', 'ja');
    final timeFmt = DateFormat('HH:mm', 'ja');

    return Scaffold(
      appBar: AppBar(
        title: Text(event.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-record/$eventId'),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('記録を追加'),
      ),
      body: CustomScrollView(
        slivers: [
          // イベント情報ヘッダー
          SliverToBoxAdapter(
            child: _EventHeader(
              event: event,
              dateStr: dateFmt.format(start),
              timeStr: '${timeFmt.format(start)} – ${timeFmt.format(end)}',
            ),
          ),
          // 記録一覧
          if (state.records.isEmpty)
            const SliverFillRemaining(
              child: _EmptyRecords(),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final rwa = state.records[index];
                  return _RecordTimelineItem(
                    rwa: rwa,
                    onDelete: () =>
                        _confirmDeleteRecord(context, notifier, rwa.record),
                    onTap: () =>
                        context.push('/record/${rwa.record.recordId}'),
                  );
                },
                childCount: state.records.length,
              ),
            ),
          // FAB 分のパディング
          const SliverToBoxAdapter(child: SizedBox(height: 88)),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteRecord(
    BuildContext context,
    EventDetailNotifier notifier,
    Record record,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('記録を削除'),
        content: const Text('この記録を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => ctx.pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await notifier.deleteRecord(record.recordId);
    }
  }
}

class _EventHeader extends StatelessWidget {
  const _EventHeader({
    required this.event,
    required this.dateStr,
    required this.timeStr,
  });

  final Event event;
  final String dateStr;
  final String timeStr;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 16),
              const SizedBox(width: 4),
              Text(dateStr, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.access_time_outlined, size: 16),
              const SizedBox(width: 4),
              Text(timeStr, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecordTimelineItem extends StatelessWidget {
  const _RecordTimelineItem({
    required this.rwa,
    required this.onDelete,
    required this.onTap,
  });

  final RecordWithAttachments rwa;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final record = rwa.record;
    final time = DateTime.fromMillisecondsSinceEpoch(record.recordTime);
    final timeFmt = DateFormat('HH:mm', 'ja');

    final isPhoto = record.recordType == RecordType.photo;
    final icon =
        isPhoto ? Icons.photo_camera_outlined : Icons.notes_outlined;
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor =
        isPhoto ? colorScheme.primary : colorScheme.secondary;

    // 写真のサムネイルパス（先頭の1枚）
    final firstPhoto = rwa.photos.isNotEmpty ? rwa.photos.first : null;
    // メモテキスト（先頭）
    final firstMemo = rwa.memos.isNotEmpty ? rwa.memos.first : null;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // タイムライン縦線 + 時刻
            Column(
              children: [
                Text(
                  timeFmt.format(time),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: colorScheme.outlineVariant,
                ),
              ],
            ),
            const SizedBox(width: 12),
            // アイコン
            CircleAvatar(
              radius: 16,
              backgroundColor: iconColor.withValues(alpha: 0.12),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 12),
            // コンテンツ
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (firstPhoto != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        firstPhoto.filePath,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 120,
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  if (firstMemo != null)
                    Text(
                      firstMemo.memoText,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  if (rwa.photos.length > 1)
                    Text(
                      '他 ${rwa.photos.length - 1} 枚',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                ],
              ),
            ),
            // 削除ボタン
            IconButton(
              icon: const Icon(Icons.delete_outline),
              iconSize: 18,
              color: colorScheme.onSurfaceVariant,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRecords extends StatelessWidget {
  const _EmptyRecords();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            '記録がありません',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '下のボタンから写真やメモを追加できます',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
