import 'package:flutter/material.dart';

/// オンボーディング画面（Android: SetupScreen / SetupViewModel 相当）。
///
/// P0 スタブ。Wave 2「setup」エージェントが本文を実装する。
/// 完了時に first_run_setup_complete を立て、Supabase サインインを行う。
class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('セットアップ')),
      body: const Center(child: Text('SetupScreen — TODO (Wave 2: setup)')),
    );
  }
}
