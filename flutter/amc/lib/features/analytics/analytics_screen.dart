import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/daos/analytics_dao.dart';
import 'analytics_notifier.dart';

/// 分析画面（Android: AnalyticsScreen / AnalyticsViewModel 相当）。
///
/// WEEK / MONTH の切り替えで集計期間を変更する。
/// Toggl 集計は除外（migration_plan.md §0 / §6.2）。
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyticsNotifierProvider);
    final notifier = ref.read(analyticsNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('分析'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '再読み込み',
            onPressed: () => notifier.refresh(),
          ),
        ],
      ),
      body: _AnalyticsBody(state: state, notifier: notifier),
    );
  }
}

class _AnalyticsBody extends StatelessWidget {
  const _AnalyticsBody({required this.state, required this.notifier});

  final AnalyticsState state;
  final AnalyticsNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ---- 期間セレクタ ----
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SegmentedButton<AnalyticsPeriod>(
            segments: const [
              ButtonSegment(
                value: AnalyticsPeriod.week,
                label: Text('週'),
                icon: Icon(Icons.calendar_view_week),
              ),
              ButtonSegment(
                value: AnalyticsPeriod.month,
                label: Text('月'),
                icon: Icon(Icons.calendar_month),
              ),
            ],
            selected: {state.period},
            onSelectionChanged: (s) => notifier.setPeriod(s.first),
          ),
        ),

        // ---- コンテンツ ----
        if (state.isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (state.error != null)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text('読み込みエラー',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(state.error!,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                _SummaryCard(state: state),
                const SizedBox(height: 16),
                _DailyCountsCard(dailyCounts: state.dailyCounts),
                const SizedBox(height: 16),
                _TopEventsCard(topEvents: state.topEvents),
              ],
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// サマリーカード
// ---------------------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.state});

  final AnalyticsState state;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('合計', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatChip(
                  icon: Icons.all_inclusive,
                  label: '総記録',
                  value: '${state.totalCount}',
                ),
                _StatChip(
                  icon: Icons.photo_camera_outlined,
                  label: '写真',
                  value: '${state.photoCount}',
                ),
                _StatChip(
                  icon: Icons.notes,
                  label: 'メモ',
                  value: '${state.memoCount}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 日別記録数カード
// ---------------------------------------------------------------------------

class _DailyCountsCard extends StatelessWidget {
  const _DailyCountsCard({required this.dailyCounts});

  final List<DailyRecordCount> dailyCounts;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('日別記録数', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (dailyCounts.isEmpty)
              const Text('データなし')
            else
              ...dailyCounts.map((d) {
                final date = DateTime.fromMillisecondsSinceEpoch(
                    d.dayKey * 86400000,
                    isUtc: true);
                final label =
                    '${date.month}/${date.day}';
                final maxCount = dailyCounts
                    .map((e) => e.totalCount)
                    .reduce((a, b) => a > b ? a : b);
                final fraction =
                    maxCount == 0 ? 0.0 : d.totalCount / maxCount;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 48,
                        child: Text(label,
                            style: Theme.of(context).textTheme.bodySmall),
                      ),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: fraction,
                          minHeight: 12,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 32,
                        child: Text(
                          '${d.totalCount}',
                          textAlign: TextAlign.end,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// イベント別記録ランキングカード
// ---------------------------------------------------------------------------

class _TopEventsCard extends StatelessWidget {
  const _TopEventsCard({required this.topEvents});

  final List<EventRecordCount> topEvents;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('イベント別記録数（Top 10）',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (topEvents.isEmpty)
              const Text('データなし')
            else
              ...topEvents.asMap().entries.map((entry) {
                final rank = entry.key + 1;
                final e = entry.value;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      '$rank',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  title: Text(
                    e.eventTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    '${e.recordCount} 件',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
