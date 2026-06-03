import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 初期化済み Supabase クライアント。**未初期化なら null を返す（throw しない）**。
///
/// `Supabase.initialize()` は通常 [main] で runApp 前に await 済みだが、
/// dart-define 未設定のローカル/UI 開発・Web などでは初期化をスキップして
/// 起動できる設計（migration_plan.md §1）。その場合でもホーム/ローカル系画面が
/// クラッシュしないよう、ここでは例外を握りつぶして null を返す。
/// クラウド機能は呼び出し点（AuthRepository / AmcStorageRepository）で
/// 明示的にエラーにする。
final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  try {
    return Supabase.instance.client;
  } catch (_) {
    return null; // 未初期化
  }
});

/// 認証状態の変化を購読する。未初期化時は空ストリーム。
final authStateProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return const Stream<AuthState>.empty();
  return client.auth.onAuthStateChange;
});
