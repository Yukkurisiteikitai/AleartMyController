/// Supabase テーブルへの書き込み用 DTO（migration_plan.md §4.3）。
///
/// amc_records / amc_record_revisions / amc_attachments の
/// Postgrest 直接書き込みに使うシンプルな Map ラッパ。
library;

class AmcRecordInsertDto {
  const AmcRecordInsertDto({
    required this.ownerUserId,
    required this.currentBody,
    required this.visibility,
  });

  final String ownerUserId;
  final String currentBody;
  final String visibility;

  Map<String, dynamic> toJson() => {
        'owner_user_id': ownerUserId,
        'current_body': currentBody,
        'visibility': visibility,
      };
}

class AmcRecordPatchDto {
  const AmcRecordPatchDto({
    required this.currentBody,
    required this.visibility,
    this.currentRevisionId,
  });

  final String currentBody;
  final String visibility;
  final String? currentRevisionId;

  Map<String, dynamic> toJson() => {
        'current_body': currentBody,
        'visibility': visibility,
        'updated_at': DateTime.now().toIso8601String(),
        if (currentRevisionId != null) 'current_revision_id': currentRevisionId,
      };
}

class AmcRevisionInsertDto {
  const AmcRevisionInsertDto({
    required this.recordId,
    required this.body,
    required this.idempotencyKey,
  });

  final String recordId;
  final String body;
  final String idempotencyKey;

  Map<String, dynamic> toJson() => {
        'record_id': recordId,
        'body': body,
        'idempotency_key': idempotencyKey,
      };
}

class AmcAttachmentInsertDto {
  const AmcAttachmentInsertDto({
    required this.recordId,
    required this.storagePath,
    required this.mimeType,
    this.checksum,
  });

  final String recordId;
  final String storagePath;
  final String mimeType;
  final String? checksum;

  Map<String, dynamic> toJson() => {
        'record_id': recordId,
        'storage_path': storagePath,
        'mime_type': mimeType,
        if (checksum != null) 'checksum': checksum,
      };
}
