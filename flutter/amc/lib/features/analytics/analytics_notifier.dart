import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/daos/analytics_dao.dart';
import '../../providers/database_providers.dart';

// ---------------------------------------------------------------------------
// Range
// ---------------------------------------------------------------------------

/// 集計期間（Android: AnalyticsViewModel の period 相当）。
enum AnalyticsPeriod {
  week,
  month;

  /// 集計開始 epoch_millis を返す（UTC）。
  int fromMillis() {
    final now = DateTime.now();
    final start = period == AnalyticsPeriod.week
        ? now.subtract(const Duration(days: 7))
        : DateTime(now.year, now.month - 1, now.day);
    return start.millisecondsSinceEpoch;
  }

  AnalyticsPeriod get period => this;
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

/// 分析画面の状態（Android: AnalyticsViewModel 相当）。
///
/// Toggl 集計は除外（migration_plan.md §0 / §6.2）。
class AnalyticsState {
  const AnalyticsState({
    this.period = AnalyticsPeriod.week,
    this.totalCount = 0,
    this.photoCount = 0,
    this.memoCount = 0,
    this.dailyCounts = const [],
    this.typeBreakdown = const [],
    this.topEvents = const [],
    this.isLoading = true,
    this.error,
  });

  final AnalyticsPeriod period;
  final int totalCount;
  final int photoCount;
  final int memoCount;
  final List<DailyRecordCount> dailyCounts;
  final List<RecordTypeCount> typeBreakdown;
  final List<EventRecordCount> topEvents;
  final bool isLoading;
  final String? error;

  AnalyticsState copyWith({
    AnalyticsPeriod? period,
    int? totalCount,
    int? photoCount,
    int? memoCount,
    List<DailyRecordCount>? dailyCounts,
    List<RecordTypeCount>? typeBreakdown,
    List<EventRecordCount>? topEvents,
    bool? isLoading,
    Object? error = _sentinel,
  }) {
    return AnalyticsState(
      period: period ?? this.period,
      totalCount: totalCount ?? this.totalCount,
      photoCount: photoCount ?? this.photoCount,
      memoCount: memoCount ?? this.memoCount,
      dailyCounts: dailyCounts ?? this.dailyCounts,
      typeBreakdown: typeBreakdown ?? this.typeBreakdown,
      topEvents: topEvents ?? this.topEvents,
      isLoading: isLoading ?? this.isLoading,
      error: error == _sentinel ? this.error : error as String?,
    );
  }
}

const _sentinel = Object();

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// 分析画面の状態管理（Android: AnalyticsViewModel 相当、migration_plan.md §6.2）。
///
/// - WEEK / MONTH の切り替えで AnalyticsDao の各メソッドを再取得する。
/// - Toggl 集計は除外（§0 スコープ / 不変条件）。
class AnalyticsNotifier extends Notifier<AnalyticsState> {
  @override
  AnalyticsState build() {
    // 期間変更に追従して再ロード。初回は build() 内で即時呼ぶ。
    _loadAnalytics(AnalyticsPeriod.week);
    return const AnalyticsState();
  }

  /// 期間を切り替えて再集計する。
  Future<void> setPeriod(AnalyticsPeriod period) async {
    state = state.copyWith(period: period, isLoading: true, error: null);
    await _loadAnalytics(period);
  }

  Future<void> _loadAnalytics(AnalyticsPeriod period) async {
    final dao = ref.read(analyticsDaoProvider);
    final fromMillis = period.fromMillis();
    try {
      final results = await Future.wait([
        dao.getTotalCount(fromMillis),
        dao.getPhotoCount(fromMillis),
        dao.getMemoCount(fromMillis),
        dao.getDailyRecordCounts(fromMillis),
        dao.getRecordTypeBreakdown(fromMillis),
        dao.getTopEventsByRecordCount(fromMillis),
      ]);
      state = state.copyWith(
        period: period,
        totalCount: results[0] as int,
        photoCount: results[1] as int,
        memoCount: results[2] as int,
        dailyCounts: results[3] as List<DailyRecordCount>,
        typeBreakdown: results[4] as List<RecordTypeCount>,
        topEvents: results[5] as List<EventRecordCount>,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 現在の期間で集計をリフレッシュする。
  Future<void> refresh() => _loadAnalytics(state.period);
}

final analyticsNotifierProvider =
    NotifierProvider<AnalyticsNotifier, AnalyticsState>(AnalyticsNotifier.new);
