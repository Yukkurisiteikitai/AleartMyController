import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/add_record/add_record_screen.dart';
import '../features/analytics/analytics_screen.dart';
import '../features/dashboard/record_dashboard_screen.dart';
import '../features/event_detail/event_detail_screen.dart';
import '../features/event_list/event_list_screen.dart';
import '../features/history/history_screen.dart';
import '../features/record_detail/record_detail_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/setup/setup_screen.dart';

/// アプリ全体のルート定義（Android: Screen.kt / AppNavHost 相当）。
///
/// P0 で全ルートを「スタブ画面」付きで先に確定させる。Wave 2 の各機能エージェントは
/// ここを編集せず、対応する features/*/ の画面本文だけを差し替える。
///
/// ボトムバー（ホーム / 履歴 / 分析）+ 中央 FAB（突発下書き開始）は
/// StatefulShellRoute.indexedStack で再現する。
class AppRouter {
  AppRouter._();

  static final _rootKey = GlobalKey<NavigatorState>();

  // TODO(P3/setup): onboarding 完了フラグ(first_run_setup_complete)で
  // /setup ↔ /events を redirect 制御する（AppNavHost.onboardingComplete 相当）。
  static final GoRouter router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/events',
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
}

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
      floatingActionButton: FloatingActionButton(
        // 突発下書き開始（Android: 中央 FAB → 下書きダイアログ → ダッシュボード）。
        // TODO(P3/dashboard): 下書き作成ダイアログを挟む。今は直接 /dashboard へ。
        onPressed: () => context.push('/dashboard'),
        tooltip: '突発記録を開始',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavButton(
              icon: Icons.home_outlined,
              label: 'ホーム',
              selected: navigationShell.currentIndex == 0,
              onTap: () => _goBranch(0),
            ),
            const SizedBox(width: 48), // 中央 FAB のためのスペース
            _NavButton(
              icon: Icons.history,
              label: '履歴',
              selected: navigationShell.currentIndex == 1,
              onTap: () => _goBranch(1),
            ),
            _NavButton(
              icon: Icons.bar_chart_outlined,
              label: '分析',
              selected: navigationShell.currentIndex == 2,
              onTap: () => _goBranch(2),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            Text(label, style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
