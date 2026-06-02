import 'package:unorm_dart/unorm_dart.dart' as unorm;

/// 本文整形ポリシー（Android: AmcContentPolicy の本文整形のみ移植、§2/§9）。
/// クラウド送信ロジックは含まない。
class AmcContentPolicy {
  AmcContentPolicy._();

  static const Set<String> allowedImageMimeTypes = {'image/jpeg'};
  static const Set<String> allowedAudioMimeTypes = {'audio/mp4', 'audio/aac'};

  static Set<String> get allowedAttachmentMimeTypes =>
      {...allowedImageMimeTypes, ...allowedAudioMimeTypes};

  static bool isAllowedAttachmentMime(String mimeType) =>
      allowedAttachmentMimeTypes.contains(mimeType.toLowerCase());

  /// 保存前の本文正規化（§9: NFC 正規化 + trim）。
  static String normalizeBodyForStorage(String value) =>
      unorm.nfc(value.trim());

  /// Google Calendar description 用の軽量ミラー本文を構築する。
  /// 長文時は先頭要約 + 参照 URL に退避する。
  static String buildCalendarMirrorBody(
    String currentBody, {
    String? referenceUrl,
    int maxDescriptionLength = 3000,
    int summaryLength = 240,
  }) {
    final normalized = normalizeBodyForStorage(currentBody);
    if (normalized.length <= maxDescriptionLength) return normalized;

    final summary = normalized.substring(0, summaryLength).trimRight();
    final fallbackUrl =
        (referenceUrl != null && referenceUrl.isNotEmpty) ? referenceUrl : null;
    final buffer = StringBuffer()
      ..write(summary)
      ..write('\n\n')
      ..write('本文は YourselfLM で閲覧してください');
    if (fallbackUrl != null) {
      buffer
        ..write('\n')
        ..write(fallbackUrl);
    }
    return buffer.toString();
  }
}
