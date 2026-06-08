import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart' show ExistingPeriodicWorkPolicy, Workmanager;

import '../data/local/daos/event_dao.dart';
import '../data/local/database.dart';
import 'notification_service.dart';

const _taskUniqueName = 'reminder_periodic';
const _taskName = 'reminder';

/// 進行中イベントのリマインダー worker（migration_plan.md §5.2）。
///
/// 15 分周期で進行中イベントを確認し、あれば通知を発行する。
/// Web では workmanager 非対応のためスキップ（kIsWeb ガード）。
/// workmanager コールバック（別 isolate）から [run] を呼ぶ。
class ReminderWorker {
  const ReminderWorker._();

  static Future<bool> run() async {
    if (kIsWeb) return true;

    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('notifications_enabled') ?? true)) return true;

    await NotificationService.initializeForBackground();

    final db = AppDatabase();
    try {
      final eventDao = EventDao(db);
      final now = DateTime.now().millisecondsSinceEpoch;
      final ongoing = await eventDao.findOngoing(now);
      if (ongoing != null) {
        await NotificationService.showReminderNotification(
          eventId: ongoing.eventId,
          eventTitle: ongoing.title,
        );
      }
      return true;
    } finally {
      await db.close();
    }
  }

  /// 15 分周期タスクを登録する（main.dart から呼ぶ、非 Web のみ）。
  static Future<void> registerPeriodicTask() async {
    if (kIsWeb) return;
    await Workmanager().registerPeriodicTask(
      _taskUniqueName,
      _taskName,
      frequency: const Duration(minutes: 15),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }
}
