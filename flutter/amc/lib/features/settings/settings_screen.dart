import 'package:flutter/material.dart';

/// 設定画面（Android: SettingsScreen / SettingsViewModel 相当）。
///
/// P0 スタブ。Wave 2「settings」エージェントが本文を実装する。
/// インターバル/通知 ON-OFF/Supabase サインイン再試行/クラウド同期トグル/ローカルキュー要約。
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: const Center(child: Text('SettingsScreen — TODO (Wave 2: settings)')),
    );
  }
}
