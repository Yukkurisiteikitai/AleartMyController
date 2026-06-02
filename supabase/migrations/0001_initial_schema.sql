-- AMC (Aleart My Controller) 初期スキーマ
-- Supabase PostgreSQL

-- ============================================================
-- ユーザープロファイル（auth.users と 1:1）
-- ============================================================
CREATE TABLE IF NOT EXISTS profiles (
    id uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
    google_subject text UNIQUE NOT NULL,
    display_name text,
    avatar_url text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- ============================================================
-- AMC レコード（正本）
-- ============================================================
CREATE TABLE IF NOT EXISTS amc_records (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    current_revision uuid,  -- amc_record_revisions.id（後述の FK を後から追加）
    current_body text NOT NULL DEFAULT '',
    visibility text NOT NULL DEFAULT 'PRIVATE'
        CHECK (visibility IN ('PRIVATE','SPECIFIC_USERS','FRIENDS','PUBLIC','LIMITED_PUBLIC')),
    google_calendar_event_id text,
    synced_at timestamptz,
    deleted_at timestamptz,
    deleted_by_user_id uuid REFERENCES profiles(id),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_amc_records_owner ON amc_records(owner_user_id);
CREATE INDEX idx_amc_records_visibility ON amc_records(visibility);
CREATE INDEX idx_amc_records_google_event ON amc_records(google_calendar_event_id)
    WHERE google_calendar_event_id IS NOT NULL;

-- ============================================================
-- リビジョン履歴（append-only）
-- ============================================================
CREATE TABLE IF NOT EXISTS amc_record_revisions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    record_id uuid NOT NULL REFERENCES amc_records(id) ON DELETE CASCADE,
    editor_user_id uuid NOT NULL REFERENCES profiles(id),
    body text NOT NULL,
    source text NOT NULL DEFAULT 'ANDROID'
        CHECK (source IN ('ANDROID','FLUTTER','WEB')),
    idempotency_key text UNIQUE NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_amc_record_revisions_record ON amc_record_revisions(record_id);

-- current_revision FK（循環参照のため DEFERRABLE）
ALTER TABLE amc_records
    ADD CONSTRAINT fk_amc_records_current_revision
    FOREIGN KEY (current_revision)
    REFERENCES amc_record_revisions(id)
    DEFERRABLE INITIALLY DEFERRED;

-- ============================================================
-- 添付ファイルメタデータ（Supabase Storage のパスを保持）
-- ============================================================
CREATE TABLE IF NOT EXISTS amc_attachments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    record_id uuid NOT NULL REFERENCES amc_records(id) ON DELETE CASCADE,
    uploader_user_id uuid NOT NULL REFERENCES profiles(id),
    type text NOT NULL CHECK (type IN ('IMAGE','AUDIO')),
    mime_type text NOT NULL,
    storage_path text NOT NULL,   -- Supabase Storage: {owner_user_id}/{record_id}/{attachment_id}.{ext}
    file_size_bytes bigint,
    checksum text,
    status text NOT NULL DEFAULT 'PENDING'
        CHECK (status IN ('PENDING','READY','FAILED','PURGED')),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_amc_attachments_record ON amc_attachments(record_id);
CREATE INDEX idx_amc_attachments_status ON amc_attachments(status);

-- ============================================================
-- 共有リンク（入口トークン: c=... パラメータ）
-- ============================================================
CREATE TABLE IF NOT EXISTS share_links (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    record_id uuid NOT NULL REFERENCES amc_records(id) ON DELETE CASCADE,
    token text UNIQUE NOT NULL,
    created_by uuid NOT NULL REFERENCES profiles(id),
    expires_at timestamptz,
    revoked_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_share_links_record ON share_links(record_id);
CREATE INDEX idx_share_links_token ON share_links(token);

-- ============================================================
-- 共有 ACL（恒久付与）
-- ============================================================
CREATE TABLE IF NOT EXISTS share_grants (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    record_id uuid NOT NULL REFERENCES amc_records(id) ON DELETE CASCADE,
    granted_to uuid NOT NULL REFERENCES profiles(id),
    granted_by uuid NOT NULL REFERENCES profiles(id),
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (record_id, granted_to)
);

CREATE INDEX idx_share_grants_record ON share_grants(record_id);
CREATE INDEX idx_share_grants_granted_to ON share_grants(granted_to);

-- ============================================================
-- RLS（Row Level Security）有効化
-- ============================================================
ALTER TABLE profiles        ENABLE ROW LEVEL SECURITY;
ALTER TABLE amc_records     ENABLE ROW LEVEL SECURITY;
ALTER TABLE amc_record_revisions ENABLE ROW LEVEL SECURITY;
ALTER TABLE amc_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE share_links     ENABLE ROW LEVEL SECURITY;
ALTER TABLE share_grants    ENABLE ROW LEVEL SECURITY;

-- ---- profiles ----
CREATE POLICY profiles_select_own ON profiles
    FOR SELECT USING (id = auth.uid());

CREATE POLICY profiles_insert_own ON profiles
    FOR INSERT WITH CHECK (id = auth.uid());

CREATE POLICY profiles_update_own ON profiles
    FOR UPDATE USING (id = auth.uid());

-- ---- amc_records ----
-- owner: full access
CREATE POLICY records_owner_all ON amc_records
    FOR ALL USING (owner_user_id = auth.uid());

-- share_grants で付与されたユーザー: read
CREATE POLICY records_shared_select ON amc_records
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM share_grants
            WHERE share_grants.record_id = amc_records.id
              AND share_grants.granted_to = auth.uid()
        )
    );

-- PUBLIC レコード: read
CREATE POLICY records_public_select ON amc_records
    FOR SELECT USING (visibility = 'PUBLIC' AND deleted_at IS NULL);

-- ---- amc_record_revisions ----
CREATE POLICY revisions_select ON amc_record_revisions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM amc_records
            WHERE amc_records.id = amc_record_revisions.record_id
              AND (
                  amc_records.owner_user_id = auth.uid()
                  OR EXISTS (
                      SELECT 1 FROM share_grants
                      WHERE share_grants.record_id = amc_records.id
                        AND share_grants.granted_to = auth.uid()
                  )
              )
        )
    );

CREATE POLICY revisions_insert_own ON amc_record_revisions
    FOR INSERT WITH CHECK (editor_user_id = auth.uid());

-- ---- amc_attachments ----
CREATE POLICY attachments_owner_all ON amc_attachments
    FOR ALL USING (uploader_user_id = auth.uid());

CREATE POLICY attachments_shared_select ON amc_attachments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM share_grants
            WHERE share_grants.record_id = amc_attachments.record_id
              AND share_grants.granted_to = auth.uid()
        )
    );

-- ---- share_links ----
CREATE POLICY share_links_owner_all ON share_links
    FOR ALL USING (created_by = auth.uid());

-- ---- share_grants ----
CREATE POLICY share_grants_owner_all ON share_grants
    FOR ALL USING (granted_by = auth.uid());

CREATE POLICY share_grants_grantee_select ON share_grants
    FOR SELECT USING (granted_to = auth.uid());

-- ============================================================
-- updated_at 自動更新トリガー
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_amc_records_updated_at
    BEFORE UPDATE ON amc_records
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_amc_attachments_updated_at
    BEFORE UPDATE ON amc_attachments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
