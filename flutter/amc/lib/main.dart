import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

/// Supabase の接続情報は --dart-define で渡す。
///
///   flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///               --dart-define=SUPABASE_ANON_KEY=eyJ...
///
/// TODO(P0): CI / ローカル開発用の値供給方法を決める（dart-define-from-file 等）。
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

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
    // dart-define 未設定でもローカル UI 開発を止めないための警告。
    debugPrint(
      '[main] SUPABASE_URL / SUPABASE_ANON_KEY が未設定です。'
      'クラウド機能は無効のまま起動します。',
    );
  }

  runApp(const ProviderScope(child: AmcApp()));
}
