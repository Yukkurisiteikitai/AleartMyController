import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/local/database.dart';
import '../../data/local/daos/record_dao.dart';
import 'event_list_notifier.dart';

/// ホーム（イベント一覧）画面（Android: EventListScreen / EventListViewModel 相当）。
///
/// - upcoming events を表示（local-draft:% は Repository 側で除外済み）。
/// - 記録件数バッジを各イベントに表示（左結合で0件も表示）。
/// - イベント削除は確認ダイアログ → records を巻き込まない（§9）。
class EventListScreen extends ConsumerWidget {
  const EventListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(eventListNotifierProvider);
    final notifier = ref.read(eventListNotifierProvider.notifier);

    // 同期エラーをスナックバーで通知。
    ref.listen<EventListState>(eventListNotifierProvider, (prev, next) {
      if (next.syncError != null && next.syncError != prev?.syncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('同期エラー: ${next.syncError}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('イベント一覧'),
        actions: [
          if (state.isSyncing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: 'カレンダー同期',
              onPressed: () => notifier.syncFromCalendar(),
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '設定',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: state.events.isEmpty
          ? const _EmptyState()
          : ListView.builder(
              itemCount: state.events.length,
              itemBuilder: (context, index) {
                final event = state.events[index];
                final count = state.countFor(event.eventId);
                return _EventListItem(
                  event: event,
                  count: count,
                  onTap: () =>
                      context.push('/events/${event.eventId}'),
                  onDelete: () => _confirmDelete(context, notifier, event),
                );
              },
            ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    EventListNotifier notifier,
    Event event,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('イベントを削除'),
        content: Text(
          '「${event.title}」を一覧から削除しますか？\n記録は削除されません。',
        ),
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
      await notifier.deleteEvent(event.eventId);
    }
  }
}

class _EventListItem extends StatelessWidget {
  const _EventListItem({
    required this.event,
    required this.count,
    required this.onTap,
    required this.onDelete,
  });

  final Event event;
  final RecordCountResult count;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final start = DateTime.fromMillisecondsSinceEpoch(event.startTime);
    final end = DateTime.fromMillisecondsSinceEpoch(event.endTime);
    final dateFmt = DateFormat('M/d(E)', 'ja');
    final timeFmt = DateFormat('HH:mm', 'ja');
    final dateStr = dateFmt.format(start);
    final timeStr = '${timeFmt.format(start)} – ${timeFmt.format(end)}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 日付カラム
              SizedBox(
                width: 56,
                child: Column(
                  children: [
                    Text(
                      dateStr,
                      style: Theme.of(context).textTheme.labelSmall,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      timeFmt.format(start),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // タイトル + 時刻
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeStr,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // バッジ
              Column(
                children: [
                  if (count.photoCount > 0)
                    _Badge(
                      icon: Icons.photo_camera_outlined,
                      count: count.photoCount,
                      color: colorScheme.primary,
                    ),
                  if (count.memoCount > 0)
                    _Badge(
                      icon: Icons.notes_outlined,
                      count: count.memoCount,
                      color: colorScheme.secondary,
                    ),
                ],
              ),
              // 削除ボタン
              IconButton(
                icon: const Icon(Icons.delete_outline),
                iconSize: 20,
                color: colorScheme.onSurfaceVariant,
                tooltip: '一覧から削除',
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.count,
    required this.color,
  });

  final IconData icon;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 2),
        Text(
          '$count',
          style: TextStyle(fontSize: 12, color: color),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'イベントがありません',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '右上の同期ボタンでカレンダーを読み込んでください',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
