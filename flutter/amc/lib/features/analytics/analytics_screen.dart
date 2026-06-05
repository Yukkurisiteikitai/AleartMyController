import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/local/daos/analytics_dao.dart';
import '../../widgets/gauge_card.dart';
import '../../widgets/section_card.dart';
import 'analytics_notifier.dart';

/// 分析画面（Android: AnalyticsScreen / AnalyticsViewModel 相当）。
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyticsNotifierProvider);
    final notifier = ref.read(analyticsNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('振り返り・分析'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '再読み込み',
            onPressed: () => notifier.refresh(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 期間セレクタ ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingMd,
              AppTheme.spacingMd,
              AppTheme.spacingMd,
              0,
            ),
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

          // ── コンテンツ ────────────────────────────────────────────────
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
                    Text('読み込みエラー', style: AppTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      state.error!,
                      style: AppTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                children: [
                  // ゲージ + サマリー
                  _SummaryRow(state: state),
                  const SizedBox(height: AppTheme.spacingMd),
                  // 週次棒グラフ
                  _DailyBarChartCard(dailyCounts: state.dailyCounts),
                  const SizedBox(height: AppTheme.spacingMd),
                  // イベント別ランキング
                  _TopEventsCard(topEvents: state.topEvents),
                  const SizedBox(height: AppTheme.spacingLg),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── サマリー行（ゲージ + 3統計） ───────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.state});

  final AnalyticsState state;

  @override
  Widget build(BuildContext context) {
    // 達成率: 記録のある日 / 期間日数
    final periodDays =
        state.period == AnalyticsPeriod.week ? 7 : 30;
    final activeDays =
        state.dailyCounts.where((d) => d.totalCount > 0).length;
    final achieveRate =
        periodDays == 0 ? 0.0 : (activeDays / periodDays).clamp(0.0, 1.0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ゲージカード
        Expanded(
          child: GaugeCard(
            value: achieveRate,
            title: '達成率',
            subtitle: '$activeDays / $periodDays 日',
          ),
        ),
        const SizedBox(width: AppTheme.spacingMd),
        // 統計カード縦列
        Expanded(
          child: Column(
            children: [
              _MiniStat(
                icon: Icons.all_inclusive,
                label: '総記録',
                value: '${state.totalCount}',
              ),
              const SizedBox(height: AppTheme.spacingSm),
              _MiniStat(
                icon: Icons.photo_camera_outlined,
                label: '写真',
                value: '${state.photoCount}',
              ),
              const SizedBox(height: AppTheme.spacingSm),
              _MiniStat(
                icon: Icons.notes,
                label: 'メモ',
                value: '${state.memoCount}',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(child: Text(label, style: AppTheme.bodySmall)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 日別棒グラフカード ─────────────────────────────────────────────────────────

class _DailyBarChartCard extends StatelessWidget {
  const _DailyBarChartCard({required this.dailyCounts});

  final List<DailyRecordCount> dailyCounts;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '日別記録数',
      child: dailyCounts.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
              child: Center(child: Text('データなし')),
            )
          : SizedBox(
              height: 160,
              child: _BarChart(dailyCounts: dailyCounts),
            ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.dailyCounts});

  final List<DailyRecordCount> dailyCounts;

  @override
  Widget build(BuildContext context) {
    final maxCount = dailyCounts
        .map((d) => d.totalCount)
        .fold(0, (a, b) => a > b ? a : b);
    final displayMax = maxCount == 0 ? 1.0 : maxCount.toDouble();

    final barGroups = dailyCounts.asMap().entries.map((entry) {
      final i = entry.key;
      final d = entry.value;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: d.totalCount.toDouble(),
            color: AppTheme.primary,
            width: 16,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        maxY: displayMax * 1.2,
        barGroups: barGroups,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: displayMax / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppTheme.divider,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= dailyCounts.length) {
                  return const SizedBox.shrink();
                }
                final dayKey = dailyCounts[index].dayKey;
                final date = DateTime.fromMillisecondsSinceEpoch(
                  dayKey * 86400000,
                  isUtc: true,
                );
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${date.month}/${date.day}',
                    style: AppTheme.bodySmall.copyWith(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppTheme.textPrimary,
            getTooltipItem: (group, _, rod, _) => BarTooltipItem(
              '${rod.toY.toInt()} 件',
              const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── イベント別ランキングカード ─────────────────────────────────────────────────

class _TopEventsCard extends StatelessWidget {
  const _TopEventsCard({required this.topEvents});

  final List<EventRecordCount> topEvents;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'イベント別記録数（Top 10）',
      child: topEvents.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
              child: Center(child: Text('データなし')),
            )
          : Column(
              children: topEvents.asMap().entries.map((entry) {
                final rank = entry.key + 1;
                final e = entry.value;
                return Padding(
                  padding:
                      const EdgeInsets.only(bottom: AppTheme.spacingSm),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: rank <= 3
                              ? AppTheme.primary.withValues(alpha: 0.15)
                              : AppTheme.background,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$rank',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: rank <= 3
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      Expanded(
                        child: Text(
                          e.eventTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        '${e.recordCount} 件',
                        style: AppTheme.labelMedium,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}
