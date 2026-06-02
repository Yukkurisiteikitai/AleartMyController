import 'package:flutter/material.dart';

/// 記録ダッシュボード画面（Android: RecordDashboardScreen / RecordDashboardViewModel 相当）。
///
/// P0 スタブ。Wave 2「dashboard」エージェントが本文を実装する。
/// 進行中イベント結合、タイマー(Stream.periodic(1s))、長押し/ダブルタップ停止、下書き確定。
class RecordDashboardScreen extends StatelessWidget {
  const RecordDashboardScreen({super.key, this.eventId, this.draftTitle});

  final int? eventId;
  final String? draftTitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('記録ダッシュボード')),
      body: Center(
        child: Text(
          'RecordDashboardScreen(eventId=$eventId, draftTitle=$draftTitle)'
          ' — TODO (Wave 2: dashboard)',
        ),
      ),
    );
  }
}
