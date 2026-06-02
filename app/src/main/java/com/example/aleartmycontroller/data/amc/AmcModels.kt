package com.example.aleartmycontroller.data.amc

enum class AmcVisibility {
    PRIVATE,
    SPECIFIC_USERS,
    FRIENDS,
    PUBLIC,
    LIMITED_PUBLIC
}

enum class AmcAttachmentType {
    IMAGE,
    AUDIO
}

enum class AmcAttachmentStatus {
    PENDING,
    UPLOADING,
    NEEDS_RETRY,
    READY,
    FAILED,
    EXPIRED,
    PURGED
}

enum class AmcAttachmentClientResult {
    UPLOADED,
    UPLOAD_FAILED
}

enum class AmcSyncState {
    DRAFT,
    QUEUED,
    SYNCING,
    SYNCED,
    FAILED
}

enum class AmcSource {
    LOCAL_DRAFT,
    LOCAL_MIGRATED,
    NATIVE_SERVER
}

enum class AmcOutboxJobType {
    CREATE_RECORD,
    UPDATE_RECORD,
    APPEND_REVISION,
    INIT_ATTACHMENT,
    COMPLETE_ATTACHMENT,
    MIRROR_CALENDAR
}

enum class AmcOutboxJobState {
    PENDING,
    RUNNING,
    SUCCEEDED,
    FAILED
}
