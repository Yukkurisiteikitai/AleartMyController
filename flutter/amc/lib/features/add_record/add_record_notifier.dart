import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../data/local/daos/record_dao.dart';
import '../../data/local/database.dart';
import '../../providers/repository_providers.dart';

// ---------------------------------------------------------------------------
// 状態
// ---------------------------------------------------------------------------

/// AddRecord 画面の UI 状態。
class AddRecordState {
  const AddRecordState({
    this.event,
    this.isLoading = false,
    this.isBusy = false,
    this.isListening = false,
    this.voiceText = '',
    this.errorMessage,
    this.records = const [],
  });

  /// 対象イベント（ロード完了後に非 null）。
  final Event? event;

  /// イベント初回ロード中。
  final bool isLoading;

  /// 写真撮影・メモ保存などの非同期処理中。
  final bool isBusy;

  /// 音声認識（STT）進行中。
  final bool isListening;

  /// 音声認識で蓄積中のテキスト。
  final String voiceText;

  /// エラーメッセージ（null = エラーなし）。
  final String? errorMessage;

  /// このイベントに紐づく記録の一覧（Stream 監視）。
  final List<RecordWithAttachments> records;

  AddRecordState copyWith({
    Event? event,
    bool? isLoading,
    bool? isBusy,
    bool? isListening,
    String? voiceText,
    Object? errorMessage = _sentinel,
    List<RecordWithAttachments>? records,
  }) {
    return AddRecordState(
      event: event ?? this.event,
      isLoading: isLoading ?? this.isLoading,
      isBusy: isBusy ?? this.isBusy,
      isListening: isListening ?? this.isListening,
      voiceText: voiceText ?? this.voiceText,
      errorMessage:
          errorMessage == _sentinel ? this.errorMessage : errorMessage as String?,
      records: records ?? this.records,
    );
  }
}

const _sentinel = Object();

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// 記録追加 Notifier（Android: AddRecordViewModel 相当、§6.2）。
///
/// - 写真: image_picker → flutter_image_compress（2048px / JPEG 85%）→ addPhotoRecord
/// - メモ: テキスト入力 → addMemoRecord（NFC 正規化は RecordRepository が担保）
/// - 音声: speech_to_text → addMemoRecord(isVoice: true)
/// - クラウド同期キュー: findOrCreate → getOrCreateDraftForEvent → appendRevision / queueAttachment
///
/// 不変条件(§9):
/// - obsEventId 解決順序: observationEventRepository.findOrCreate(event) →
///   amcDraftRepository.getOrCreateDraftForEvent(obsEventId)
/// - record + 添付は 1 トランザクション（addPhotoRecord / addMemoRecord が担保）
class AddRecordNotifier extends Notifier<AddRecordState> {
  late int _eventId;

  @override
  AddRecordState build() => const AddRecordState(isLoading: true);

  /// イベント ID を渡して初期化する（画面の initState 相当）。
  /// ルーターから渡された [eventId] は [Event.eventId]（events テーブルの PK）。
  void init(int eventId) {
    _eventId = eventId;
    _loadEvent();
    _watchRecords();
  }

  // ---- 初期化 ----

  Future<void> _loadEvent() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final event = await ref
          .read(eventRepositoryProvider)
          .findById(_eventId);
      if (event == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'イベントが見つかりませんでした（id=$_eventId）',
        );
        return;
      }
      state = state.copyWith(event: event, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'イベントの読み込みに失敗しました: $e',
      );
    }
  }

  void _watchRecords() {
    ref
        .read(recordRepositoryProvider)
        .watchRecordsByEventWithAttachments(_eventId)
        .listen(
          (records) => state = state.copyWith(records: records),
        );
  }

  // ---- 写真追加 ----

  /// カメラで写真を撮影して記録に追加する。
  Future<void> addPhotoFromCamera() =>
      _pickAndAddPhoto(ImageSource.camera);

  /// ギャラリーから写真を選択して記録に追加する。
  Future<void> addPhotoFromGallery() =>
      _pickAndAddPhoto(ImageSource.gallery);

  Future<void> _pickAndAddPhoto(ImageSource source) async {
    final event = state.event;
    if (event == null || state.isBusy) return;

    state = state.copyWith(isBusy: true, errorMessage: null);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 85, // JPEG 85% 初期品質（再圧縮で確実に 2048px / 85% にする）
      );
      if (picked == null) {
        state = state.copyWith(isBusy: false);
        return;
      }

      // §5.3: 2048px / JPEG 85% に圧縮して documents ディレクトリへ保存
      final compressedPath = await _compressAndSave(picked.path);

      // ローカル DB に保存（record + photo を 1 トランザクション、§9）
      await ref
          .read(recordRepositoryProvider)
          .addPhotoRecord(event, compressedPath);

      // クラウド同期キュー登録（§9: findOrCreate → getOrCreateDraft → queueAttachment）
      await _enqueuePhotoForSync(event, compressedPath);

      state = state.copyWith(isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, errorMessage: '写真の追加に失敗しました: $e');
    }
  }

  /// 圧縮して documents/photos/ 配下に保存し、絶対パスを返す（§5.3）。
  Future<String> _compressAndSave(String sourcePath) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(docsDir.path, 'photos'));
    if (!photosDir.existsSync()) {
      photosDir.createSync(recursive: true);
    }
    final fileName =
        'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final destPath = p.join(photosDir.path, fileName);

    final result = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      destPath,
      minWidth: 2048,
      minHeight: 2048,
      quality: 85,
      format: CompressFormat.jpeg,
    );
    // 圧縮結果が null の場合（プラットフォーム非対応等）は元ファイルをコピー
    if (result == null) {
      await File(sourcePath).copy(destPath);
    }
    return destPath;
  }

  /// 写真を AMC 添付キューに登録する（§4.2）。
  Future<void> _enqueuePhotoForSync(Event event, String filePath) async {
    try {
      final obsEventId =
          await ref.read(observationEventRepositoryProvider).findOrCreate(event);
      final draftRecordId = await ref
          .read(amcDraftRepositoryProvider)
          .getOrCreateDraftForEvent(obsEventId);
      await ref.read(amcDraftRepositoryProvider).queueAttachment(
            draftRecordId: draftRecordId,
            localUri: filePath,
            mimeType: 'image/jpeg',
          );
    } catch (_) {
      // クラウド同期キュー登録の失敗はローカル保存の成功に影響させない
    }
  }

  // ---- テキストメモ追加 ----

  /// テキストメモを追加する。
  ///
  /// [text] は NFC 正規化を [RecordRepository.addMemoRecord] が担保する（§9）。
  Future<void> addTextMemo(String text) async {
    if (text.trim().isEmpty) return;
    final event = state.event;
    if (event == null || state.isBusy) return;

    state = state.copyWith(isBusy: true, errorMessage: null);
    try {
      await ref
          .read(recordRepositoryProvider)
          .addMemoRecord(event, text);

      // クラウド同期: revision を積む（§4.3 / §9）
      await _enqueueTextForSync(event, text);

      state = state.copyWith(isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, errorMessage: 'メモの追加に失敗しました: $e');
    }
  }

  Future<void> _enqueueTextForSync(Event event, String text) async {
    try {
      final obsEventId =
          await ref.read(observationEventRepositoryProvider).findOrCreate(event);
      final draftRecordId = await ref
          .read(amcDraftRepositoryProvider)
          .getOrCreateDraftForEvent(obsEventId);
      await ref
          .read(amcDraftRepositoryProvider)
          .appendRevision(draftRecordId, text);
    } catch (_) {
      // クラウド同期キュー登録の失敗はローカル保存の成功に影響させない
    }
  }

  // ---- 音声メモ ----

  final SpeechToText _stt = SpeechToText();

  /// 音声認識を開始する。
  Future<void> startVoiceInput() async {
    if (state.isListening) return;
    final available = await _stt.initialize(
      onError: (e) => state = state.copyWith(
        isListening: false,
        errorMessage: '音声認識エラー: ${e.errorMsg}',
      ),
    );
    if (!available) {
      state = state.copyWith(errorMessage: '音声認識が利用できません');
      return;
    }
    state = state.copyWith(isListening: true, voiceText: '');
    await _stt.listen(
      onResult: (result) {
        state = state.copyWith(voiceText: result.recognizedWords);
      },
      localeId: 'ja_JP',
    );
  }

  /// 音声認識を停止し、認識テキストをメモとして保存する。
  Future<void> stopVoiceInputAndSave() async {
    if (!state.isListening) return;
    await _stt.stop();
    final text = state.voiceText;
    state = state.copyWith(isListening: false, voiceText: '');
    if (text.trim().isEmpty) return;

    final event = state.event;
    if (event == null) return;

    state = state.copyWith(isBusy: true, errorMessage: null);
    try {
      await ref
          .read(recordRepositoryProvider)
          .addMemoRecord(event, text, isVoice: true);
      await _enqueueTextForSync(event, text);
      state = state.copyWith(isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, errorMessage: '音声メモの保存に失敗しました: $e');
    }
  }

  /// 音声認識を中断する（保存しない）。
  Future<void> cancelVoiceInput() async {
    if (!state.isListening) return;
    await _stt.cancel();
    state = state.copyWith(isListening: false, voiceText: '');
  }

  // ---- エラークリア ----

  void clearError() => state = state.copyWith(errorMessage: null);
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// [AddRecordNotifier] のプロバイダー。
///
/// 画面側で `ref.read(addRecordNotifierProvider.notifier).init(eventId)` を
/// 呼んでから使う（画面ごとにスコープされるため `autoDispose` を使用）。
final addRecordNotifierProvider =
    NotifierProvider.autoDispose<AddRecordNotifier, AddRecordState>(
  AddRecordNotifier.new,
);
