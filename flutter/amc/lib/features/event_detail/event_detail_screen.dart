import 'package:flutter/material.dart';

/// イベント詳細画面（Android: EventDetailScreen / EventDetailViewModel 相当）。
///
/// P0 スタブ。Wave 2「event_detail」エージェントが本文を実装する。
class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final int eventId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('イベント詳細')),
      body: Center(
        child: Text('EventDetailScreen(eventId=$eventId) — TODO (Wave 2: event_detail)'),
      ),
    );
  }
}
