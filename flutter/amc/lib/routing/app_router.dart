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
