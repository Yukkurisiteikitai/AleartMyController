import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/repository_providers.dart';
import '../../providers/supabase_providers.dart';

// ---------------------------------------------------------------------------
// Keys（migration_plan.md §6.3）
// ---------------------------------------------------------------------------
const _kIntervalMinutes = 'interval_minutes';
const _kPresetOrder = 'preset_order';
const _kNotificationsEnabled = 'notifications_enabled';
const _kCustomIntervalMinutes = 'custom_interval_minutes';
const _kCloudSyncEnabled = 'cloud_sync_enabled';

const _defaultIntervalMinutes = 60;
const _defaultPresetOrder = '1,3,5,10,25,30,60,0';
const _defaultNotificationsEnabled = true;
const _defaultCustomIntervalMinutes = 0;
const _defaultCloudSyncEnabled = true;

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------
class SettingsState {
  const SettingsState({
    this.intervalMinutes = _defaultIntervalMinutes,
    this.presetOrder = _defaultPresetOrder,
    this.notificationsEnabled = _defaultNotificationsEnabled,
    this.customIntervalMinutes = _defaultCustomIntervalMinutes,
    this.cloudSyncEnabled = _defaultCloudSyncEnabled,
    this.isSignedIn = false,
    this.isSigningIn = false,
    this.signInError,
    this.unsyncedCount = 0,
  });

  final int intervalMinutes;
  final String presetOrder;
  final bool notificationsEnabled;
  final int customIntervalMinutes;
  final bool cloudSyncEnabled;
  final bool isSignedIn;
  final bool isSigningIn;
  final String? signInError;
  final int unsyncedCount;

  SettingsState copyWith({
    int? intervalMinutes,
    String? presetOrder,
    bool? notificationsEnabled,
    int? customIntervalMinutes,
    bool? cloudSyncEnabled,
    bool? isSignedIn,
    bool? isSigningIn,
    Object? signInError = _sentinel,
    int? unsyncedCount,
  }) {
    return SettingsState(
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      presetOrder: presetOrder ?? this.presetOrder,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      customIntervalMinutes:
          customIntervalMinutes ?? this.customIntervalMinutes,
      cloudSyncEnabled: cloudSyncEnabled ?? this.cloudSyncEnabled,
      isSignedIn: isSignedIn ?? this.isSignedIn,
      isSigningIn: isSigningIn ?? this.isSigningIn,
      signInError:
          signInError == _sentinel ? this.signInError : signInError as String?,
      unsyncedCount: unsyncedCount ?? this.unsyncedCount,
    );
  }
}

// Sentinel for optional-null copyWith pattern.
const _sentinel = Object();

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// 設定画面の状態管理（Android: SettingsViewModel 相当、migration_plan.md §6.2）。
///
/// - `cloud_sync_enabled` は shared_preferences で永続化する（§9 不変条件）。
/// - Supabase 未サインイン時は再試行導線（`signInWithSupabase()`）を表示する。
/// - サインイン失敗時は throw をキャッチしてエラー表示。クラッシュさせない。
/// - ローカルキュー要約: `amcDraftRepository.watchUnsyncedCount()` を watch する。
class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    // Watch unsynced count from the draft repository.
    final unsyncedSub = ref
        .watch(amcDraftRepositoryProvider)
        .watchUnsyncedCount()
        .listen((count) {
      // Only update if we're still alive.
      state = state.copyWith(unsyncedCount: count);
    });
    ref.onDispose(unsyncedSub.cancel);

    // Watch auth state to react to sign-in/sign-out changes.
    ref.listen(authStateProvider, (_, next) {
      next.whenData((_) {
        final isSignedIn =
            ref.read(authRepositoryProvider).isSupabaseAuthenticated();
        state = state.copyWith(isSignedIn: isSignedIn, signInError: null);
      });
    });

    // Load initial values asynchronously.
    _loadPreferences();

    final isSignedIn =
        ref.read(authRepositoryProvider).isSupabaseAuthenticated();
    return SettingsState(isSignedIn: isSignedIn);
  }

  // -------------------------------------------------------------------------
  // Load / save
  // -------------------------------------------------------------------------

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      intervalMinutes:
          prefs.getInt(_kIntervalMinutes) ?? _defaultIntervalMinutes,
      presetOrder: prefs.getString(_kPresetOrder) ?? _defaultPresetOrder,
      notificationsEnabled:
          prefs.getBool(_kNotificationsEnabled) ?? _defaultNotificationsEnabled,
      customIntervalMinutes:
          prefs.getInt(_kCustomIntervalMinutes) ?? _defaultCustomIntervalMinutes,
      cloudSyncEnabled:
          prefs.getBool(_kCloudSyncEnabled) ?? _defaultCloudSyncEnabled,
    );
  }

  // -------------------------------------------------------------------------
  // Public mutations
  // -------------------------------------------------------------------------

  Future<void> setIntervalMinutes(int minutes) async {
    state = state.copyWith(intervalMinutes: minutes);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kIntervalMinutes, minutes);
  }

  Future<void> setCustomIntervalMinutes(int minutes) async {
    state = state.copyWith(customIntervalMinutes: minutes);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kCustomIntervalMinutes, minutes);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotificationsEnabled, enabled);
  }

  /// クラウド同期 ON/OFF トグル（§9 不変条件: shared_preferences で永続化）。
  Future<void> setCloudSyncEnabled(bool enabled) async {
    state = state.copyWith(cloudSyncEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kCloudSyncEnabled, enabled);
  }

  /// Supabase 再サインイン導線（§9 不変条件: 失敗時はエラー表示、クラッシュしない）。
  Future<void> retrySignIn() async {
    state = state.copyWith(isSigningIn: true, signInError: null);
    try {
      await ref.read(authRepositoryProvider).signInWithSupabase();
      final isSignedIn =
          ref.read(authRepositoryProvider).isSupabaseAuthenticated();
      state = state.copyWith(isSignedIn: isSignedIn, isSigningIn: false);
    } catch (e) {
      state = state.copyWith(
        isSigningIn: false,
        signInError: e.toString(),
      );
    }
  }
}

final settingsNotifierProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
