import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'routing/app_router.dart';
import 'services/notification_service.dart';

/// アプリのルートウィジェット。go_router + Material 3 テーマ。
///
/// - [routerProvider] で GoRouter を取得（appLaunchProvider の setup redirect 込み）。
/// - フォアグラウンド通知タップ: [NotificationService.onNotificationTapped] を
///   listen して /add-record/:eventId へナビゲート（P5, §5.2）。
/// - バックグラウンド/killed 状態からの通知タップ: 起動後の初回フレームで
///   [NotificationService.getLaunchNotificationPayload] を確認してナビゲート。
class AmcApp extends ConsumerStatefulWidget {
  const AmcApp({super.key});

  @override
  ConsumerState<AmcApp> createState() => _AmcAppState();
}

class _AmcAppState extends ConsumerState<AmcApp> {
  StreamSubscription<String>? _notifSubscription;

  @override
  void initState() {
    super.initState();

    if (!kIsWeb) {
      // フォアグラウンドでの通知タップを listen する。
      _notifSubscription =
          NotificationService.onNotificationTapped.listen(_onNotificationTap);

      // killed/バックグラウンド状態からの通知タップ (launch payload) を確認する。
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final payload =
              await NotificationService.getLaunchNotificationPayload();
          if (payload != null && mounted) {
            ref.read(routerProvider).go('/add-record/$payload');
          }
        } catch (_) {
          // テスト環境など通知プラグインが未初期化の場合は無視する。
        }
      });
    }
  }

  @override
  void dispose() {
    _notifSubscription?.cancel();
    super.dispose();
  }

  void _onNotificationTap(String eventId) {
    ref.read(routerProvider).go('/add-record/$eventId');
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Aleart My Controller',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
