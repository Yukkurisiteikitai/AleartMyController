import 'package:flutter/material.dart';

/// 記録追加画面（Android: AddRecordScreen / AddRecordViewModel 相当）。
///
/// P0 スタブ。Wave 2「add_record」エージェントが本文を実装する。
/// 写真/テキスト/音声の追加 + 下書き作成 → 同期 worker 起動。
class AddRecordScreen extends StatelessWidget {
  const AddRecordScreen({super.key, required this.eventId});

  final int eventId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('記録を追加')),
      body: Center(
        child: Text('AddRecordScreen(eventId=$eventId) — TODO (Wave 2: add_record)'),
      ),
    );
  }
}
