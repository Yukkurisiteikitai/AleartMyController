import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/theme/app_theme.dart';
import '../../data/local/daos/record_dao.dart';
import '../../data/local/tables.dart';
import 'history_notifier.dart';

/// 履歴画面（Android: HistoryScreen / HistoryViewModel 相当）。
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
    final state = ref.watch(historyNotifierProvider);

    // 記録のある日付セット
    final recordDays = <DateTime>{};
    for (final item in state.records) {
      final d = DateTime.fromMillisecondsSinceEpoch(item.record.recordTime);
      recordDays.add(DateTime(d.year, d.month, d.day));
    }

    // 選択日の記録
    final selectedRecords = _selectedDay == null
        ? <RecordWithAttachments>[]
        : state.records.where((item) {
            final d = DateTime.fromMillisecondsSinceEpoch(
                item.record.recordTime);
            return isSameDay(d, _selectedDay);
          }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('履歴（カレンダー）'),
        actions: [
          if (!state.isLoading && state.error == null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  '${state.records.length} 件',
                  style: AppTheme.bodySmall,
                ),
              ),
            ),
        ],
      ),
      body: _HistoryBody(
        state: state,
        focusedDay: _focusedDay,
        selectedDay: _selectedDay,
        recordDays: recordDays,
        selectedRecords: selectedRecords,
        onDaySelected: (selected, focused) {
          setState(() {
            _selectedDay = selected;
            _focusedDay = focused;
          });
        },
        onPageChanged: (focused) {
          setState(() => _focusedDay = focused);
        },
      ),
    );
  }
}

class _HistoryBody extends StatelessWidget {
  const _HistoryBody({
    required this.state,
    required this.focusedDay,
    required this.selectedDay,
    required this.recordDays,
    required this.selectedRecords,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  final HistoryState state;
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Set<DateTime> recordDays;
  final List<RecordWithAttachments> selectedRecords;
  final void Function(DateTime, DateTime) onDaySelected;
  final void Function(DateTime) onPageChanged;

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
            Text('読み込みエラー', style: AppTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              state.error!,
              style: AppTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // ── カレンダー ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingSm,
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
              focusedDay: focusedDay,
              selectedDayPredicate: (day) => isSameDay(selectedDay, day),
              onDaySelected: onDaySelected,
              onPageChanged: onPageChanged,
              calendarFormat: CalendarFormat.month,
              availableGestures: AvailableGestures.horizontalSwipe,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: AppTheme.titleMedium,
                leftChevronIcon: const Icon(
                  Icons.chevron_left,
                  color: AppTheme.primary,
                ),
                rightChevronIcon: const Icon(
                  Icons.chevron_right,
                  color: AppTheme.primary,
                ),
                headerPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                markerDecoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 1,
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
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // ── 選択日の記録リスト ──────────────────────────────────────────
        if (selectedDay != null)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingXs,
            ),
            child: Row(
              children: [
                Text(
                  DateFormat('M月d日(E)', 'ja').format(selectedDay!),
                  style: AppTheme.titleMedium,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  '${selectedRecords.length} 件',
                  style: AppTheme.labelMedium,
                ),
              ],
            ),
          ),

        Expanded(
          child: state.records.isEmpty
              ? const _EmptyHistory()
              : selectedDay == null
                  ? Center(
                      child: Text(
                        '日付をタップして記録を確認',
                        style: AppTheme.bodySmall,
                      ),
                    )
                  : selectedRecords.isEmpty
                      ? Center(
                          child: Text(
                            'この日の記録はありません',
                            style: AppTheme.bodySmall,
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingMd,
                            vertical: AppTheme.spacingSm,
                          ),
                          itemCount: selectedRecords.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppTheme.spacingSm),
                          itemBuilder: (context, index) {
                            return _RecordCard(item: selectedRecords[index]);
                          },
                        ),
        ),
      ],
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
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.divider),
        ),
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(
                isPhoto ? Icons.photo_camera_outlined : Icons.notes_outlined,
                size: 18,
                color: iconColor,
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(timeStr, style: AppTheme.labelMedium),
                  const SizedBox(height: 2),
                  Text(
                    isPhoto
                        ? '写真 ${item.photos.length} 枚'
                        : item.memos.isNotEmpty
                            ? item.memos.first.memoText
                            : 'メモ',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history,
              size: 32,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text('記録がありません', style: AppTheme.titleMedium),
        ],
      ),
    );
  }
}
