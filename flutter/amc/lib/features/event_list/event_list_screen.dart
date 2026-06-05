import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/local/database.dart';
import '../../data/local/daos/record_dao.dart';
import '../../data/local/tables.dart';
import '../../features/history/history_notifier.dart';
import '../../features/settings/settings_notifier.dart';
import '../../widgets/brand_header.dart';
import '../../widgets/donut_progress.dart';
import 'event_list_notifier.dart';

/// ホーム（イベント一覧）画面（Android: EventListScreen / EventListViewModel 相当）。
class EventListScreen extends ConsumerWidget {
  const EventListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(eventListNotifierProvider);
    final notifier = ref.read(eventListNotifierProvider.notifier);

    // 同期エラー通知
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

    // ログイン完了時に自動でカレンダー同期を開始する
    ref.listen<SettingsState>(settingsNotifierProvider, (prev, next) {
      if (next.isSignedIn && !(prev?.isSignedIn ?? true)) {
        notifier.syncFromCalendar();
      }
    });

    // 今日のテキスト・写真記録（historyから取得）
    final allRecords = ref.watch(historyNotifierProvider).records;
    final now = DateTime.now();
    final todayRecords = allRecords.where((r) {
      final d = DateTime.fromMillisecondsSinceEpoch(r.record.recordTime);
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList()
      ..sort((a, b) => b.record.recordTime.compareTo(a.record.recordTime));

    // 今日のイベントだけに絞って達成率を計算する。
    final todayEvents = state.events.where((e) {
      final d = DateTime.fromMillisecondsSinceEpoch(e.startTime);
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();
    final totalEvents = todayEvents.length;
    final eventsWithRecords = todayEvents.where((e) {
      final c = state.countFor(e.eventId);
      return c.photoCount + c.memoCount > 0;
    }).length;
    final progress =
        totalEvents == 0 ? 0.0 : (eventsWithRecords / totalEvents).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: const BrandHeader(),
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
      body: CustomScrollView(
        slivers: [
          // ── 今日の進捗カード ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingMd,
                AppTheme.spacingMd,
                AppTheme.spacingMd,
                AppTheme.spacingSm,
              ),
              child: _TodaySummaryCard(
                progress: progress,
                eventsWithRecords: eventsWithRecords,
                totalEvents: totalEvents,
              ),
            ),
          ),

          // ── Google 未連携バナー ──────────────────────────────────────
          // (設定画面へのナビゲーションのみ。isSignedIn は settingsProvider 不使用のため
          //  同期ボタンの存在で代替)

          // ── 今日の記録ログ ─────────────────────────────────────────
          if (todayRecords.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingMd, AppTheme.spacingXs,
                  AppTheme.spacingMd, AppTheme.spacingXs,
                ),
                child: Row(
                  children: [
                    Text('今日の記録', style: AppTheme.titleMedium),
                    const SizedBox(width: AppTheme.spacingSm),
                    Text('${todayRecords.length} 件',
                        style: AppTheme.labelMedium),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = todayRecords[index];
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppTheme.spacingSm),
                      child: _TodayRecordTile(
                        item: item,
                        onTap: () =>
                            context.push('/record/${item.record.recordId}'),
                      ),
                    );
                  },
                  childCount: todayRecords.length,
                ),
              ),
            ),
          ],

          // ── イベントリスト ───────────────────────────────────────────
          if (state.events.isEmpty)
            const SliverFillRemaining(child: _EmptyState())
          else ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final event = state.events[index];
                    final count = state.countFor(event.eventId);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                      child: _EventCard(
                        event: event,
                        count: count,
                        onTap: () => context.push('/events/${event.eventId}'),
                        onDelete: () =>
                            _confirmDelete(context, notifier, event),
                      ),
                    );
                  },
                  childCount: state.events.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppTheme.spacingLg),
            ),
          ],
        ],
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

// ── 今日の進捗サマリーカード ──────────────────────────────────────────────────

class _TodaySummaryCard extends StatelessWidget {
  const _TodaySummaryCard({
    required this.progress,
    required this.eventsWithRecords,
    required this.totalEvents,
  });

  final double progress;
  final int eventsWithRecords;
  final int totalEvents;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary,
            AppTheme.primaryLight,
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Row(
        children: [
          // 左: テキスト + stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '今日の記録',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: AppTheme.spacingXs),
                if (totalEvents == 0)
                  const Text(
                    '今日の予定なし',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$eventsWithRecords',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          ' / $totalEvents 件',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  totalEvents == 0
                      ? 'カレンダーを同期してください'
                      : '記録済みイベント',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          // ドーナツ（今日のイベントがある場合のみ）
          if (totalEvents > 0)
            DonutProgress(
              value: progress,
              size: 100,
              color: Colors.white,
              backgroundColor: Colors.white24,
              centerTextStyle: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            )
          else
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_today_outlined,
                color: Colors.white54,
                size: 32,
              ),
            ),
        ],
      ),
    );
  }
}

// ── イベントカード ────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  const _EventCard({
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
    final start = DateTime.fromMillisecondsSinceEpoch(event.startTime);
    final end = DateTime.fromMillisecondsSinceEpoch(event.endTime);
    final dateFmt = DateFormat('M/d(E)', 'ja');
    final timeFmt = DateFormat('HH:mm', 'ja');
    final hasRecord = count.photoCount + count.memoCount > 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: hasRecord
                ? AppTheme.primary.withValues(alpha: 0.3)
                : AppTheme.divider,
          ),
        ),
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Row(
          children: [
            // 日付カラム
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Column(
                children: [
                  Text(
                    dateFmt.format(start),
                    style: AppTheme.bodySmall.copyWith(fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    timeFmt.format(start),
                    style: AppTheme.labelMedium.copyWith(fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            // タイトル + 時刻範囲
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: AppTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${timeFmt.format(start)} – ${timeFmt.format(end)}',
                    style: AppTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            // バッジ列
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (count.photoCount > 0)
                  _CountBadge(
                    icon: Icons.photo_camera_outlined,
                    count: count.photoCount,
                  ),
                if (count.memoCount > 0)
                  _CountBadge(
                    icon: Icons.notes_outlined,
                    count: count.memoCount,
                    color: const Color(0xFF7C4DFF),
                  ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              iconSize: 18,
              color: AppTheme.textSecondary,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.icon,
    required this.count,
    this.color = AppTheme.primary,
  });

  final IconData icon;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 2),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayRecordTile extends StatelessWidget {
  const _TodayRecordTile({required this.item, required this.onTap});

  final RecordWithAttachments item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPhoto = item.record.recordType == RecordType.photo;
    final time = DateFormat('HH:mm').format(
      DateTime.fromMillisecondsSinceEpoch(item.record.recordTime),
    );
    final label = isPhoto
        ? '写真 ${item.photos.length} 枚'
        : item.memos.isNotEmpty
            ? item.memos.first.memoText
            : 'メモ';
    final iconColor = isPhoto ? AppTheme.primary : const Color(0xFF7C4DFF);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.divider),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
        child: Row(
          children: [
            Icon(
              isPhoto ? Icons.photo_camera_outlined : Icons.notes_outlined,
              size: 18,
              color: iconColor,
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodyMedium,
              ),
            ),
            Text(time, style: AppTheme.labelMedium),
          ],
        ),
      ),
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
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_outlined,
              size: 36,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text('イベントがありません', style: AppTheme.titleMedium),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            '右上の同期ボタンでカレンダーを読み込んでください',
            style: AppTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
