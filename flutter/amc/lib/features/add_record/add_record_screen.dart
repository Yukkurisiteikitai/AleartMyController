import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/local/daos/record_dao.dart';
import '../../data/local/tables.dart';
import 'add_record_notifier.dart';

/// 記録追加画面（Android: AddRecordScreen / AddRecordViewModel 相当）。
///
/// 写真（カメラ/ギャラリー）・テキストメモ・音声メモの追加ができる。
/// 追加した記録はリスト形式で即時表示（Stream 監視）。
/// §9 不変条件: record+添付は 1 トランザクション（Notifier / Repository 層が担保）。
class AddRecordScreen extends ConsumerStatefulWidget {
  const AddRecordScreen({super.key, required this.eventId});

  final int eventId;

  @override
  ConsumerState<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends ConsumerState<AddRecordScreen> {
  final _memoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // ウィジェットツリー構築後に init を呼ぶ（build 中の state 変更を避ける）。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(addRecordNotifierProvider.notifier).init(widget.eventId);
    });
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addRecordNotifierProvider);
    final notifier = ref.read(addRecordNotifierProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    // エラー表示
    ref.listen<AddRecordState>(addRecordNotifierProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: '閉じる',
              onPressed: notifier.clearError,
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.event?.title ?? '記録を追加',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ---- 操作パネル ----
                _ActionPanel(
                  state: state,
                  memoController: _memoController,
                  notifier: notifier,
                ),
                const Divider(height: 1),
                // ---- 記録一覧 ----
                Expanded(
                  child: state.records.isEmpty
                      ? _EmptyRecordsView(
                          isListening: state.isListening,
                          voiceText: state.voiceText,
                        )
                      : _RecordList(
                          records: state.records,
                          isListening: state.isListening,
                          voiceText: state.voiceText,
                        ),
                ),
              ],
            ),
      // ---- FAB: 写真追加 ----
      floatingActionButton: state.event == null
          ? null
          : FloatingActionButton.extended(
              onPressed: state.isBusy ? null : () => _showPhotoMenu(context, notifier),
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('写真'),
              backgroundColor: state.isBusy
                  ? colorScheme.surfaceContainerHighest
                  : null,
            ),
    );
  }

  void _showPhotoMenu(
      BuildContext context, AddRecordNotifier notifier) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('カメラで撮影'),
              onTap: () {
                Navigator.pop(ctx);
                notifier.addPhotoFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('ギャラリーから選択'),
              onTap: () {
                Navigator.pop(ctx);
                notifier.addPhotoFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 操作パネル（テキスト入力 + 音声ボタン）
// ---------------------------------------------------------------------------

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.state,
    required this.memoController,
    required this.notifier,
  });

  final AddRecordState state;
  final TextEditingController memoController;
  final AddRecordNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: Row(
        children: [
          // テキスト入力フィールド
          Expanded(
            child: TextField(
              controller: memoController,
              enabled: !state.isBusy && !state.isListening,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: state.isListening
                    ? state.voiceText.isEmpty
                        ? '音声認識中...'
                        : state.voiceText
                    : 'メモを入力',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // 送信ボタン（テキストメモ）
          IconButton(
            icon: state.isBusy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
            tooltip: 'メモを追加',
            onPressed: (state.isBusy || state.isListening)
                ? null
                : () {
                    final text = memoController.text;
                    if (text.trim().isEmpty) return;
                    notifier.addTextMemo(text);
                    memoController.clear();
                  },
          ),
          // 音声メモボタン
          IconButton(
            icon: Icon(
              state.isListening
                  ? Icons.stop_circle_outlined
                  : Icons.mic_outlined,
              color: state.isListening ? theme.colorScheme.error : null,
            ),
            tooltip: state.isListening ? '音声認識を停止して保存' : '音声メモを開始',
            onPressed: state.isBusy
                ? null
                : () {
                    if (state.isListening) {
                      notifier.stopVoiceInputAndSave();
                    } else {
                      notifier.startVoiceInput();
                    }
                  },
          ),
          // 音声認識キャンセル
          if (state.isListening)
            IconButton(
              icon: const Icon(Icons.cancel_outlined),
              tooltip: 'キャンセル',
              onPressed: notifier.cancelVoiceInput,
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 記録一覧
// ---------------------------------------------------------------------------

class _RecordList extends StatelessWidget {
  const _RecordList({
    required this.records,
    required this.isListening,
    required this.voiceText,
  });

  final List<RecordWithAttachments> records;
  final bool isListening;
  final String voiceText;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 80), // FAB の下に隠れない余白
      itemCount: records.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
      itemBuilder: (context, index) {
        // 新しい順（末尾が最新）を上に表示するため逆順で取得
        final item = records[records.length - 1 - index];
        return _RecordItem(item: item);
      },
    );
  }
}

class _RecordItem extends StatelessWidget {
  const _RecordItem({required this.item});

  final RecordWithAttachments item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeLabel = DateFormat('HH:mm').format(
      DateTime.fromMillisecondsSinceEpoch(item.record.recordTime),
    );

    return ListTile(
      leading: _RecordTypeIcon(type: item.record.recordType),
      title: _buildTitle(context, item),
      subtitle: Text(timeLabel, style: theme.textTheme.bodySmall),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildTitle(BuildContext context, RecordWithAttachments item) {
    if (item.record.recordType == RecordType.photo) {
      final count = item.photos.length;
      return Text('写真 $count 枚');
    } else {
      final text = item.memos.isNotEmpty ? item.memos.first.memoText : '';
      final isVoice =
          item.memos.isNotEmpty && item.memos.first.isVoiceMemo;
      return Row(
        children: [
          if (isVoice) ...[
            const Icon(Icons.mic, size: 14),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }
  }
}

class _RecordTypeIcon extends StatelessWidget {
  const _RecordTypeIcon({required this.type});

  final RecordType type;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return CircleAvatar(
      backgroundColor: color.withAlpha(30),
      child: Icon(
        type == RecordType.photo
            ? Icons.photo_camera_outlined
            : Icons.text_snippet_outlined,
        color: color,
        size: 20,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 空状態
// ---------------------------------------------------------------------------

class _EmptyRecordsView extends StatelessWidget {
  const _EmptyRecordsView({required this.isListening, required this.voiceText});

  final bool isListening;
  final String voiceText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (isListening) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mic, size: 48),
            const SizedBox(height: 12),
            Text(
              voiceText.isEmpty ? '聞いています...' : voiceText,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.note_add_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withAlpha(128),
          ),
          const SizedBox(height: 12),
          Text(
            'まだ記録がありません',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '写真・メモ・音声で記録を追加できます',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
