import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/database.dart';
import 'repository_providers.dart';

/// 全イベントをstartTime降順で監視するStream。
/// 履歴画面などで過去イベントのタイトル参照に使う。
final allEventsProvider = StreamProvider<List<Event>>((ref) {
  return ref.watch(eventRepositoryProvider).watchAllEvents();
});
