-- amc-media バケット作成（private）
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'amc-media',
    'amc-media',
    false,
    10485760,  -- 10MB
    ARRAY[
        'image/jpeg',              -- 汎用性最優先（JPEG は全プラットフォーム対応）
        'audio/mp4', 'audio/aac'   -- AAC/M4A（Android MediaRecorder デフォルト）
    ]
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- storage.objects RLS
-- パス規則: {owner_user_id}/{record_id}/{attachment_id}.{ext}
--   foldername(name)[1] = owner_user_id
--   foldername(name)[2] = record_id
-- ============================================================

-- ---- アップロード（INSERT）: 自分のフォルダのみ ----
CREATE POLICY "storage_upload_own" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'amc-media'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- ---- 更新（UPDATE）: 自分のファイルのみ ----
CREATE POLICY "storage_update_own" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'amc-media'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- ---- 削除（DELETE）: 自分のファイルのみ ----
CREATE POLICY "storage_delete_own" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'amc-media'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- ---- 読み取り（SELECT）: owner ----
CREATE POLICY "storage_select_own" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'amc-media'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- ---- 読み取り（SELECT）: share_grants で付与されたユーザー ----
-- パスの第2セグメント (record_id) を使って share_grants を参照
CREATE POLICY "storage_select_shared" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'amc-media'
        AND EXISTS (
            SELECT 1 FROM share_grants
            WHERE share_grants.record_id::text = (storage.foldername(name))[2]
              AND share_grants.granted_to = auth.uid()
        )
    );

-- ---- 読み取り（SELECT）: PUBLIC レコードの添付ファイル ----
CREATE POLICY "storage_select_public_records" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'amc-media'
        AND EXISTS (
            SELECT 1 FROM amc_records
            WHERE amc_records.id::text = (storage.foldername(name))[2]
              AND amc_records.visibility = 'PUBLIC'
              AND amc_records.deleted_at IS NULL
        )
    );
