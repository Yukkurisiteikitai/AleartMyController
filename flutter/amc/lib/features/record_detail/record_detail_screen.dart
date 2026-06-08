import 'package:flutter/material.dart';

/// 記録詳細画面（Android: RecordDetailScreen / RecordDetailViewModel 相当）。
///
/// P0 スタブ。Wave 2「record_detail」エージェントが本文を実装する。
class RecordDetailScreen extends StatelessWidget {
  const RecordDetailScreen({super.key, required this.recordId});

  final int recordId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('記録詳細')),
      body: Center(
        child: Text('RecordDetailScreen(recordId=$recordId) — TODO (Wave 2: record_detail)'),
      ),
    );
  }
}
