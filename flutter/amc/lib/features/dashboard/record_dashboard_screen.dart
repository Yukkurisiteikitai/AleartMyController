import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/local/database.dart';
import '../../data/local/tables.dart';
import 'record_dashboard_notifier.dart';

/// 記録ダッシュボード画面（Android: RecordDashboardScreen / RecordDashboardViewModel 相当）。
///
/// - 進行中イベント結合と記録一覧の表示
/// - Stream.periodic(1s) タイマーによる経過時間表示（§9）
/// - 長押し → 停止確認モード、指を離す → 停止確定（§9）
/// - ダブルタップ → 即時停止（§9）
class RecordDashboardScreen extends ConsumerStatefulWidget {
  const RecordDashboardScreen({super.key, this.eventId, this.draftTitle});

  final int? eventId;
  final String? draftTitle;

  @override
  ConsumerState<RecordDashboardScreen> createState() =>
      _RecordDashboardScreenState();
}

class _RecordDashboardScreenState
    extends ConsumerState<RecordDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Notifier に eventId を渡して初期化。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recordDashboardProvider.notifier).init(widget.eventId);
    });
  }

  @override
  Widget build(BuildContext context) {
    // メッセージ（SnackBar）を購読して表示する。
    ref.listen<RecordDashboardState>(recordDashboardProvider, (prev, next) {
      final msg = next.message;
      if (msg != null && msg.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
        ref.read(recordDashboardProvider.notifier).consumeMessage();
      }
    });

    final state = ref.watch(recordDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(state.event?.title ?? widget.draftTitle ?? '記録ダッシュボード'),
        actions: [
          // 記録追加ボタン（eventId がある場合）
          if (state.event != null)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: '記録を追加',
              onPressed: () {
                context.push('/add-record/${state.event!.eventId}');
              },
            ),
        ],
      ),
      body: state.event == null
          ? _NoEventBody(draftTitle: widget.draftTitle)
          : _DashboardBody(state: state),
    );
  }
}

// ============================================================
//  イベントなし
// ============================================================

class _NoEventBody extends StatelessWidget {
  const _NoEventBody({this.draftTitle});

  final String? draftTitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_busy, size: 64,
                color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              draftTitle != null
                  ? '「$draftTitle」を読み込み中...'
                  : '進行中のイベントはありません',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
//  メインボディ
// ============================================================

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.state});

  final RecordDashboardState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(recordDashboardProvider.notifier);

    return Column(
      children: [
        // ---- タイマー + 停止ボタン ----
        _TimerSection(
          event: state.event!,
          elapsedSeconds: state.elapsedSeconds,
          isStopping: state.isStopping,
          onLongPressStart: notifier.onLongPressStart,
          onLongPressCancel: notifier.onLongPressCancel,
          onLongPressEnd: notifier.onLongPressEnd,
          onDoubleTap: notifier.onDoubleTap,
        ),

        const Divider(height: 1),

        // ---- 記録一覧 ----
        Expanded(
          child: state.records.isEmpty
              ? const _EmptyRecords()
              : _RecordList(records: state.records),
        ),
      ],
    );
  }
}

// ============================================================
//  タイマーセクション
// ============================================================

class _TimerSection extends StatelessWidget {
  const _TimerSection({
    required this.event,
    required this.elapsedSeconds,
    required this.isStopping,
    required this.onLongPressStart,
    required this.onLongPressCancel,
    required this.onLongPressEnd,
    required this.onDoubleTap,
  });

  final Event event;
  final int elapsedSeconds;
  final bool isStopping;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressCancel;
  final Future<void> Function() onLongPressEnd;
  final Future<void> Function() onDoubleTap;

  String _formatElapsed(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final stopColor =
        isStopping ? colorScheme.error : colorScheme.primaryContainer;
    final stopLabel = isStopping ? '離して停止' : '長押しで停止 / ダブルタップで即停止';

    return Container(
      color: colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        children: [
          // 経過時間
          Text(
            _formatElapsed(elapsedSeconds),
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            event.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),

          // 停止ボタン（§9: GestureDetector で長押し + ダブルタップ）
          GestureDetector(
            onLongPressStart: (_) => onLongPressStart(),
            onLongPressEnd: (_) => onLongPressEnd(),
            onLongPressCancel: onLongPressCancel,
            onDoubleTap: () => onDoubleTap(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
              decoration: BoxDecoration(
                color: stopColor,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Text(
                stopLabel,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isStopping
                          ? colorScheme.onError
                          : colorScheme.onPrimaryContainer,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  記録一覧
// ============================================================

class _EmptyRecords extends StatelessWidget {
  const _EmptyRecords();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.note_add_outlined,
                size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              'まだ記録がありません\n右上の＋ボタンから追加できます',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordList extends StatelessWidget {
  const _RecordList({required this.records});

  final List<Record> records;

  @override
  Widget build(BuildContext context) {
    // 最新順（recordTime 降順）に並べる。
    final sorted = [...records]
      ..sort((a, b) => b.recordTime.compareTo(a.recordTime));

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
      itemBuilder: (context, index) {
        return _RecordTile(record: sorted[index]);
      },
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record});

  final Record record;

  @override
  Widget build(BuildContext context) {
    final isPhoto = record.recordType == RecordType.photo;
    final time = DateTime.fromMillisecondsSinceEpoch(record.recordTime);
    final timeLabel =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return ListTile(
      leading: Icon(
        isPhoto ? Icons.photo_outlined : Icons.text_snippet_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(isPhoto ? '写真' : 'メモ'),
      subtitle: Text(timeLabel),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        context.push('/record/${record.recordId}');
      },
    );
  }
}
