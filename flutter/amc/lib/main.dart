import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';

import 'app.dart';
import 'services/amc_attachment_upload_worker.dart';
import 'services/amc_record_sync_worker.dart';
import 'services/notification_service.dart';
import 'services/reminder_worker.dart';

/// Supabase の接続情報。
///
/// --dart-define-from-file=dart_defines.json（make run / make run-web）で上書き可能。
/// defaultValue はプロジェクトの公開 anon key（Supabase の RLS がアクセス制御を担保）。
const _supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://zsbizfmloonyhytomblh.supabase.co',
);
const _supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpzYml6Zm1sb29ueWh5dG9tYmxoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAyOTA4NzAsImV4cCI6MjA5NTg2Njg3MH0.oSO30x0iw2ioxwKiMlTIjtM5qfw4OwQFBjQM9Ug_6C8',
);

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
  await initializeDateFormatting('ja');

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
