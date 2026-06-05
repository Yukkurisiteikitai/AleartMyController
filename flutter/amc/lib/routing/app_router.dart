import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/add_record/add_record_screen.dart';
import '../features/analytics/analytics_screen.dart';
import '../features/dashboard/record_dashboard_screen.dart';
import '../features/event_detail/event_detail_screen.dart';
import '../features/event_list/event_list_screen.dart';
import '../features/history/history_screen.dart';
import '../features/record_detail/record_detail_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/setup/setup_notifier.dart';
import '../features/setup/setup_screen.dart';

/// GoRouter + Riverpod 統合用 ChangeNotifier。
///
/// appLaunchProvider の変化を listen してルーターにリフレッシュを通知し、
/// redirect でオンボーディング完了フラグを参照する（migration_plan.md §6.2）。
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen(appLaunchProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    // Web はオンボーディング不要のため redirect をスキップする（§8）。
    if (kIsWeb) return null;
    final setupDone = _ref.read(appLaunchProvider).asData?.value ?? false;
    final isSetup = state.matchedLocation == '/setup';
    if (!setupDone && !isSetup) return '/setup';
    if (setupDone && isSetup) return '/events';
    return null;
  }
}

final _rootKey = GlobalKey<NavigatorState>();

/// GoRouter インスタンス provider。
///
/// appLaunchProvider を refreshListenable で監視し、セットアップ完了時に
/// /setup ↔ /events の redirect を自動再評価する。
/// app.dart で `ref.watch(routerProvider)` して MaterialApp.router に渡す。
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/events',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/setup',
        builder: (context, state) => const SetupScreen(),
      ),

      // ボトムバー付きシェル（ホーム / 履歴 / 分析）
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/events',
                builder: (context, state) => const EventListScreen(),
                routes: [
                  GoRoute(
                    path: ':eventId',
                    parentNavigatorKey: _rootKey,
                    builder: (context, state) => EventDetailScreen(
                      eventId: int.parse(state.pathParameters['eventId']!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/analytics',
                builder: (context, state) => const AnalyticsScreen(),
              ),
            ],
          ),
        ],
      ),

      // シェル外のトップレベルルート
      GoRoute(
        path: '/add-record/:eventId',
        builder: (context, state) => AddRecordScreen(
          eventId: int.parse(state.pathParameters['eventId']!),
        ),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) {
          final eventIdRaw = state.uri.queryParameters['eventId'];
          return RecordDashboardScreen(
            eventId: eventIdRaw == null ? null : int.tryParse(eventIdRaw),
            draftTitle: state.uri.queryParameters['draftTitle'],
          );
        },
      ),
      GoRoute(
        path: '/record/:recordId',
        builder: (context, state) => RecordDetailScreen(
          recordId: int.parse(state.pathParameters['recordId']!),
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );

  ref.onDispose(() {
    notifier.dispose();
    router.dispose();
  });

  return router;
});

/// ボトムナビゲーション + 中央 FAB（突発下書き開始）のシェル。
/// Android の `Scaffold(bottomBar, FAB)` 相当。
class _ScaffoldWithNavBar extends StatelessWidget {
  const _ScaffoldWithNavBar({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      // 突発記録ボタン: Material3 NavigationBar との共存のため endFloat に配置。
      // TODO(P3/dashboard): 下書き作成ダイアログを挟む。今は直接 /dashboard へ。
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/dashboard'),
        tooltip: '突発記録を開始',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _goBranch,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'ホーム',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: '履歴',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: '分析',
          ),
        ],
      ),
    );
  }
}

