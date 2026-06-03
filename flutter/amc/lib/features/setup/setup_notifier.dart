import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/repository_providers.dart';

// ---------------------------------------------------------------------------
// Keys
// ---------------------------------------------------------------------------

/// オンボーディング完了フラグのキー（migration_plan.md §6.3）。
const _kFirstRunSetupComplete = 'first_run_setup_complete';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

/// セットアップ画面の状態。
class SetupState {
  const SetupState({
    this.isComplete = false,
    this.isLoading = false,
    this.isSigningIn = false,
    this.error,
  });

  /// `first_run_setup_complete` フラグが立った → ルートリダイレクト用。
  final bool isComplete;

  /// 初期フラグ読み込み中。
  final bool isLoading;

  /// Supabase サインイン処理中。
  final bool isSigningIn;

  final String? error;

  SetupState copyWith({
    bool? isComplete,
    bool? isLoading,
    bool? isSigningIn,
    Object? error = _sentinel,
  }) {
    return SetupState(
      isComplete: isComplete ?? this.isComplete,
      isLoading: isLoading ?? this.isLoading,
      isSigningIn: isSigningIn ?? this.isSigningIn,
      error: error == _sentinel ? this.error : error as String?,
    );
  }
}

const _sentinel = Object();

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// オンボーディング画面の状態管理（Android: SetupViewModel 相当、migration_plan.md §6.2）。
///
/// 不変条件（§9）:
/// - `first_run_setup_complete` フラグで完了判定。
/// - 完了済みなら `isComplete = true` → 呼び出し元（SetupScreen）がルートリダイレクト。
/// - 完了時に `authRepository.signInWithSupabase()` を呼ぶ（失敗はキャッチしてスキップ可）。
class SetupNotifier extends Notifier<SetupState> {
  @override
  SetupState build() {
    _checkAlreadyComplete();
    return const SetupState(isLoading: true);
  }

  /// 起動時にフラグを確認し、完了済みなら即 `isComplete = true` をセットする。
  Future<void> _checkAlreadyComplete() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool(_kFirstRunSetupComplete) ?? false;
    state = state.copyWith(isLoading: false, isComplete: done);
  }

  /// セットアップを完了する。
  ///
  /// 1. `first_run_setup_complete = true` を SharedPreferences に書く。
  /// 2. Supabase サインインを試みる（失敗は無視してセットアップ完了扱いにする）。
  /// 3. `isComplete = true` をセット → UI が /events へリダイレクトする。
  Future<void> completeSetup() async {
    state = state.copyWith(isSigningIn: true, error: null);

    // Supabase サインイン（失敗許容）
    try {
      await ref.read(authRepositoryProvider).signInWithSupabase();
    } catch (_) {
      // §9: 失敗はキャッチしてスキップ可。セットアップ自体は完了させる。
    }

    // フラグを永続化
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kFirstRunSetupComplete, true);

    state = state.copyWith(isSigningIn: false, isComplete: true, error: null);
  }
}

final setupNotifierProvider =
    NotifierProvider<SetupNotifier, SetupState>(SetupNotifier.new);

// ---------------------------------------------------------------------------
// appLaunchProvider — GoRouter の redirect で参照する（migration_plan.md §6.2）。
// ---------------------------------------------------------------------------

/// アプリ起動時の `first_run_setup_complete` フラグを返す Provider。
///
/// GoRouter の redirect 条件:
/// - `false` → `/setup` へリダイレクト
/// - `true`  → そのまま（`/events` へ進む）
///
/// SharedPreferences は非同期のため AsyncNotifier で包む。
final appLaunchProvider = AsyncNotifierProvider<AppLaunchNotifier, bool>(
  AppLaunchNotifier.new,
);

class AppLaunchNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kFirstRunSetupComplete) ?? false;
  }

  /// SetupNotifier が完了を呼んだ後に状態を同期させる用。
  Future<void> markComplete() async {
    state = const AsyncData(true);
  }
}
