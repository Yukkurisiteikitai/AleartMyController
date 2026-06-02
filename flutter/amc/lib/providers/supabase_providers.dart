import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 初期化済み Supabase クライアントを公開する。
///
/// `Supabase.initialize()` は [main] で `runApp` 前に await 済みである前提
/// （migration_plan.md §1「Supabase 初期化の方針」/ §9 クラウド不変条件）。
/// これにより Android で起きた「Worker がセッション未ロードで retry ループ」する
/// 事故を構造的に回避する。
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// 認証状態の変化を購読する（サインイン/サインアウト）。
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});
