import 'package:shared_preferences/shared_preferences.dart';

/// shared_preferences キー定数 + Worker から呼べる静的アクセスヘルパ。
///
/// SettingsNotifier も同じキーを直接使う（migration_plan.md §6.3）。
/// Worker isolate からも呼べるよう静的 API のみを提供する。
class AppPreferences {
  const AppPreferences._();

  static const kCloudSyncEnabled = 'cloud_sync_enabled';
  static const kNotificationsEnabled = 'notifications_enabled';
  static const kFirstRunSetupComplete = 'first_run_setup_complete';

  static Future<bool> getCloudSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kCloudSyncEnabled) ?? true;
  }

  static Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kNotificationsEnabled) ?? true;
  }

  static Future<bool> isFirstRunSetupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kFirstRunSetupComplete) ?? false;
  }

  static Future<void> setFirstRunSetupComplete(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kFirstRunSetupComplete, value);
  }
}
