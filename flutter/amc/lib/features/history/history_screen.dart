import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/theme/app_theme.dart';
import '../../data/local/daos/record_dao.dart';
import '../../data/local/database.dart';
import '../../data/local/tables.dart';
import '../../providers/all_events_provider.dart';
import 'history_notifier.dart';

/// 履歴画面: 月間カレンダー + 選択日のイベント＋記録タイムライン。
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(historyNotifierProvider);
    final allEventsAsync = ref.watch(allEventsProvider);

    // 記録のある日付セット
    final recordDays = <DateTime>{};
    for (final item in historyState.records) {
      final d = DateTime.fromMillisecondsSinceEpoch(item.record.recordTime);
      recordDays.add(DateTime(d.year, d.month, d.day));
    }

    // 全イベントマップ (eventId → Event)
    final eventMap = <int, Event>{};
    allEventsAsync.whenData((events) {
      for (final e in events) {
        eventMap[e.eventId] = e;
      }
    });

    // 選択日のデータ
    final selectedDay = _selectedDay;
    final dayRecords = selectedDay == null
        ? <RecordWithAttachments>[]
        : historyState.records.where((r) {
            final d = DateTime.fromMillisecondsSinceEpoch(r.record.recordTime);
            return isSameDay(d, selectedDay);
          }).toList()
      ..sort((a, b) => a.record.recordTime.compareTo(b.record.recordTime));

    // 選択日のイベント
    final dayEvents = selectedDay == null
        ? <Event>[]
        : (allEventsAsync.asData?.value ?? []).where((e) {
            final s = DateTime.fromMillisecondsSinceEpoch(e.startTime);
            return s.year == selectedDay.year &&
                s.month == selectedDay.month &&
                s.day == selectedDay.day;
          }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('履歴'),
        actions: [
          if (!historyState.isLoading && historyState.error == null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  '${historyState.records.length} 件',
                  style: AppTheme.bodySmall,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(
        context,
        historyState,
        recordDays,
        eventMap,
        dayRecords,
        dayEvents,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    HistoryState state,
    Set<DateTime> recordDays,
    Map<int, Event> eventMap,
    List<RecordWithAttachments> dayRecords,
    List<Event> dayEvents,
  ) {
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
            Text('読み込みエラー', style: AppTheme.titleMedium),
            const SizedBox(height: 4),
            Text(state.error!, style: AppTheme.bodySmall,
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return Column(
      children: [
        // ── カレンダー ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingMd, AppTheme.spacingSm,
            AppTheme.spacingMd, AppTheme.spacingXs,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.divider),
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
              },
              onPageChanged: (focused) =>
                  setState(() => _focusedDay = focused),
              calendarFormat: CalendarFormat.month,
              availableGestures: AvailableGestures.horizontalSwipe,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: AppTheme.titleMedium,
                leftChevronIcon: const Icon(
                  Icons.chevron_left, color: AppTheme.primary),
                rightChevronIcon: const Icon(
                  Icons.chevron_right, color: AppTheme.primary),
                headerPadding:
                    const EdgeInsets.symmetric(vertical: 8),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(
                  color: AppTheme.primary, fontWeight: FontWeight.w700),
                selectedDecoration: const BoxDecoration(
                  color: AppTheme.primary, shape: BoxShape.circle),
                selectedTextStyle: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
                outsideDaysVisible: false,
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, _) {
                  final key = DateTime(date.year, date.month, date.day);
                  if (!recordDays.contains(key)) return null;
                  return Positioned(
                    bottom: 2,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppTheme.primary, shape: BoxShape.circle),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // ── 選択日ヘッダー ──────────────────────────────────────────────
        if (_selectedDay != null)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingXs,
            ),
            child: Row(
              children: [
                Text(
                  DateFormat('M月d日(E)', 'ja').format(_selectedDay!),
                  style: AppTheme.titleMedium,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                if (dayRecords.isNotEmpty)
                  Text('${dayRecords.length} 件',
                      style: AppTheme.labelMedium),
              ],
            ),
          ),

        // ── タイムライン ───────────────────────────────────────────────
        Expanded(
          child: _selectedDay == null
              ? Center(
                  child: Text('日付をタップして記録を確認',
                      style: AppTheme.bodySmall))
              : (dayEvents.isEmpty && dayRecords.isEmpty)
                  ? Center(
                      child: Text('この日の記録はありません',
                          style: AppTheme.bodySmall))
                  : _DayTimeline(
                      dayEvents: dayEvents,
                      dayRecords: dayRecords,
                      eventMap: eventMap,
                    ),
        ),
      ],
    );
  }
}

// ── 日別タイムライン ──────────────────────────────────────────────────────────

class _DayTimeline extends StatelessWidget {
  const _DayTimeline({
    required this.dayEvents,
    required this.dayRecords,
    required this.eventMap,
  });

  final List<Event> dayEvents;
  final List<RecordWithAttachments> dayRecords;
  final Map<int, Event> eventMap;

  @override
  Widget build(BuildContext context) {
    // イベントと記録を時刻順にインターリーブして表示する
    // sealed union で代替
    final items = <_TimelineItem>[];
    for (final e in dayEvents) {
      items.add(_TimelineItem.event(e));
    }
    for (final r in dayRecords) {
      items.add(_TimelineItem.record(r));
    }
    items.sort((a, b) => a.timeMillis.compareTo(b.timeMillis));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingMd, AppTheme.spacingXs,
        AppTheme.spacingMd, AppTheme.spacingLg,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
          child: item.when(
            event: (e) => _EventTimelineBlock(event: e),
            record: (r) => _RecordCard(item: r),
          ),
        );
      },
    );
  }
}

// 簡易sealed-union
class _TimelineItem {
  _TimelineItem._({required this.timeMillis, this.event, this.record});

  factory _TimelineItem.event(Event e) =>
      _TimelineItem._(timeMillis: e.startTime, event: e);
  factory _TimelineItem.record(RecordWithAttachments r) =>
      _TimelineItem._(timeMillis: r.record.recordTime, record: r);

  final int timeMillis;
  final Event? event;
  final RecordWithAttachments? record;

  T when<T>({
    required T Function(Event) event,
    required T Function(RecordWithAttachments) record,
  }) {
    if (this.event != null) return event(this.event!);
    return record(this.record!);
  }
}

class _EventTimelineBlock extends StatelessWidget {
  const _EventTimelineBlock({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final start = DateTime.fromMillisecondsSinceEpoch(event.startTime);
    final end = DateTime.fromMillisecondsSinceEpoch(event.endTime);
    final timeFmt = DateFormat('HH:mm');

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: Row(
        children: [
          const Icon(Icons.event_rounded, color: Colors.white, size: 16),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              event.title,
              style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${timeFmt.format(start)} – ${timeFmt.format(end)}',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.item});

  final RecordWithAttachments item;

  @override
  Widget build(BuildContext context) {
    final record = item.record;
    final isPhoto = record.recordType == RecordType.photo;
    final timeStr = DateFormat('HH:mm').format(
      DateTime.fromMillisecondsSinceEpoch(record.recordTime),
    );
    final iconColor = isPhoto ? AppTheme.primary : const Color(0xFF7C4DFF);

    return InkWell(
      onTap: () => context.push('/record/${record.recordId}'),
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
              size: 16, color: iconColor,
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Text(
                isPhoto
                    ? '写真 ${item.photos.length} 枚'
                    : item.memos.isNotEmpty
                        ? item.memos.first.memoText
                        : 'メモ',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodySmall,
              ),
            ),
            Text(timeStr, style: AppTheme.labelMedium),
            const Icon(Icons.chevron_right,
                color: AppTheme.textSecondary, size: 14),
          ],
        ),
      ),
    );
  }
}
