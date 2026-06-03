import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';

import 'app.dart';
import 'services/amc_attachment_upload_worker.dart';
import 'services/amc_record_sync_worker.dart';
import 'services/notification_service.dart';
import 'services/reminder_worker.dart';

/// Supabase の接続情報は --dart-define で渡す。
///
///   flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///               --dart-define=SUPABASE_ANON_KEY=eyJ...
///
/// TODO(P0): CI / ローカル開発用の値供給方法を決める（dart-define-from-file 等）。
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

/// workmanager コールバック（別 isolate で呼ばれる）。
///
/// isolate 内で Supabase / drift / Repository を再初期化してから各 Worker.run() を呼ぶ。
/// Web では workmanager を使わないため、この関数は native 専用（§4.2/§4.3/§5.2）。
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    switch (taskName) {
      case 'amc_attachment_upload':
        return AmcAttachmentUploadWorker.run();
      case 'amc_record_sync':
        return AmcRecordSyncWorker.run();
      case 'reminder':
        return ReminderWorker.run();
      default:
        return true;
    }
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // migration_plan.md §1 / §9: Supabase はセッション自動復元を含めて
  // runApp 前に初期化を await 完了させる（Worker がセッション未ロードで走る事故の回避）。
  if (_supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
  } else {
    debugPrint(
      '[main] SUPABASE_URL / SUPABASE_ANON_KEY が未設定です。'
      'クラウド機能は無効のまま起動します。',
    );
  }

  // 通知 + workmanager は Web 非対応のため native のみ初期化（§8）。
  if (!kIsWeb) {
    await NotificationService.initialize();
    await Workmanager().initialize(callbackDispatcher);
    await ReminderWorker.registerPeriodicTask();
  }

  runApp(const ProviderScope(child: AmcApp()));
}
