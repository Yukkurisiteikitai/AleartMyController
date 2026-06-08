import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/local/daos/record_dao.dart';
import '../../data/local/database.dart';
import '../../data/local/tables.dart';
import '../../widgets/donut_progress.dart';
import '../../widgets/primary_action_button.dart';
import '../../widgets/section_card.dart';
import 'event_detail_notifier.dart';

/// イベント詳細画面（Android: EventDetailScreen / EventDetailViewModel 相当）。
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
    final durationMin =
        end.difference(start).inMinutes.clamp(0, 9999);

    // Progress: records / target(5), capped at 1.0
    final progress = (state.records.length / 5.0).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(event.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: CustomScrollView(
        slivers: [
          // ── 進捗ヘッダー ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _EventProgressHeader(
              event: event,
              dateStr: dateFmt.format(start),
              timeStr: '${timeFmt.format(start)} – ${timeFmt.format(end)}',
              durationMin: durationMin,
              progress: progress,
              recordCount: state.records.length,
            ),
          ),

          // ── 記録追加ボタン ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: AppTheme.spacingSm,
              ),
              child: PrimaryActionButton(
                label: '記録する',
                icon: Icons.add_a_photo_outlined,
                onPressed: () => context.push('/add-record/$eventId'),
              ),
            ),
          ),

          // ── 記録一覧 ───────────────────────────────────────────────────
          if (state.records.isEmpty)
            const SliverFillRemaining(child: _EmptyRecords())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingMd,
                AppTheme.spacingSm,
                AppTheme.spacingMd,
                AppTheme.spacingXl,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final rwa = state.records[index];
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppTheme.spacingSm),
                      child: _RecordTimelineItem(
                        rwa: rwa,
                        onDelete: () =>
                            _confirmDeleteRecord(context, notifier, rwa.record),
                        onTap: () =>
                            context.push('/record/${rwa.record.recordId}'),
                      ),
                    );
                  },
                  childCount: state.records.length,
                ),
              ),
            ),
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

// ── 進捗ヘッダー ──────────────────────────────────────────────────────────────

class _EventProgressHeader extends StatelessWidget {
  const _EventProgressHeader({
    required this.event,
    required this.dateStr,
    required this.timeStr,
    required this.durationMin,
    required this.progress,
    required this.recordCount,
  });

  final Event event;
  final String dateStr;
  final String timeStr;
  final int durationMin;
  final double progress;
  final int recordCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.title, style: AppTheme.headlineMedium),
            const SizedBox(height: AppTheme.spacingSm),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(dateStr, style: AppTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(
                  Icons.access_time_outlined,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(timeStr, style: AppTheme.bodySmall),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 進捗リング
                DonutProgress(
                  value: progress,
                  size: 100,
                  strokeWidth: 12,
                  label: '記録進捗',
                ),
                // 時間情報
                Column(
                  children: [
                    _InfoTile(
                      icon: Icons.timer_outlined,
                      label: '時間',
                      value: '$durationMin',
                      unit: 'min',
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    _InfoTile(
                      icon: Icons.photo_library_outlined,
                      label: '記録数',
                      value: '$recordCount',
                      unit: '件',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(label, style: AppTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 2),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(unit, style: AppTheme.bodySmall),
            ),
          ],
        ),
      ],
    );
  }
}

// ── タイムラインアイテム ───────────────────────────────────────────────────────

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
    final icon = isPhoto ? Icons.photo_camera_outlined : Icons.notes_outlined;
    final iconColor = isPhoto ? AppTheme.primary : const Color(0xFF7C4DFF);
    final firstPhoto = rwa.photos.isNotEmpty ? rwa.photos.first : null;
    final firstMemo = rwa.memos.isNotEmpty ? rwa.memos.first : null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.divider),
        ),
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(timeFmt.format(time), style: AppTheme.labelMedium),
                  const SizedBox(height: 4),
                  if (firstPhoto != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      child: kIsWeb
                          ? Container(
                              height: 120,
                              color: AppTheme.background,
                              child: const Center(
                                child: Icon(
                                  Icons.photo_outlined,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            )
                          : Image.file(
                              File(firstPhoto.filePath),
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                height: 120,
                                color: AppTheme.background,
                                child: const Icon(
                                  Icons.broken_image_outlined,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                    ),
                  if (firstMemo != null)
                    Text(
                      firstMemo.memoText,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodyMedium,
                    ),
                  if (rwa.photos.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '他 ${rwa.photos.length - 1} 枚',
                        style: AppTheme.bodySmall,
                      ),
                    ),
                ],
              ),
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

class _EmptyRecords extends StatelessWidget {
  const _EmptyRecords();

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
              Icons.photo_library_outlined,
              size: 36,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text('記録がありません', style: AppTheme.titleMedium),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            '上のボタンから写真やメモを追加できます',
            style: AppTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
