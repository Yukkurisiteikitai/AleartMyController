import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const _channelId = 'observation_reminders';
const _channelName = '観察リマインダー';
const _channelDesc = 'イベント記録中のリマインダー通知';
const _notificationId = 1001;

/// バックグラウンド通知タップ時のハンドラ（別 isolate で呼ばれる）。
///
/// タップ後はアプリが起動される。起動時に [NotificationService.getLaunchNotificationPayload]
/// で payload(eventId) を取得し deep link する（P5 で app_router と結線）。
@pragma('vm:entry-point')
void _onBackgroundNotification(NotificationResponse response) {
  // Background isolate では router に届けられないため、
  // 起動後の getLaunchNotificationPayload で処理する（§5.2 / P5）。
}

/// flutter_local_notifications ラッパ（migration_plan.md §5.2）。
///
/// チャンネル: observation_reminders
/// 通知タップ → payload = eventId (String)
/// フォアグラウンドタップは [onNotificationTapped] ストリームに流す（P5 で router 購読）。
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static final _tapController = StreamController<String>.broadcast();

  /// フォアグラウンドでの通知タップ payload ストリーム。payload = eventId。
  /// P5 で app_router / appLaunchProvider から購読して deep link する。
  static Stream<String> get onNotificationTapped => _tapController.stream;

  /// メインスレッドでの初期化（main.dart から呼ぶ）。
  static Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: iOS),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _tapController.add(payload);
        }
      },
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotification,
    );
  }

  /// バックグラウンド isolate（ReminderWorker）からも呼べる軽量初期化。
  /// タップ通知のルーティング不要で通知表示だけが目的の場合に使う。
  static Future<void> initializeForBackground() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: iOS),
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotification,
    );
  }

  /// 進行中イベントのリマインダー通知を表示する。
  /// payload = eventId.toString()（通知タップ時の deep link 用）。
  static Future<void> showReminderNotification({
    required int eventId,
    required String eventTitle,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _plugin.show(
      id: _notificationId,
      title: '記録中: $eventTitle',
      body: '記録を追加しますか？',
      notificationDetails: details,
      payload: eventId.toString(),
    );
  }

  /// アプリ起動時に通知タップ経由か確認し、payload(eventId) を返す。
  /// null なら通常起動。P5 で app_router の redirect ロジックに結線する。
  static Future<String?> getLaunchNotificationPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      return details?.notificationResponse?.payload;
    }
    return null;
  }
}
