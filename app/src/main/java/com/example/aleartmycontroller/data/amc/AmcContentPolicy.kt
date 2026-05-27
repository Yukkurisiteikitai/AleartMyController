package com.example.aleartmycontroller.data.amc

import java.text.Normalizer

object AmcContentPolicy {
    val allowedImageMimeTypes = setOf(
        "image/jpeg",
        "image/png",
        "image/webp",
        "image/heic",
        "image/heif"
    )

    val allowedAudioMimeTypes = setOf(
        "audio/mpeg",
        "audio/mp4",
        "audio/aac",
        "audio/ogg",
        "audio/wav",
        "audio/webm"
    )

    val allowedAttachmentMimeTypes: Set<String> = allowedImageMimeTypes + allowedAudioMimeTypes

    fun isAllowedAttachmentMime(mimeType: String): Boolean =
        allowedAttachmentMimeTypes.contains(mimeType.lowercase())

    fun normalizeBodyForStorage(value: String): String =
        Normalizer.normalize(value.trim(), Normalizer.Form.NFC)

    /**
     * Google Calendar description 用の軽量ミラー本文を構築する。
     * 長文時は先頭要約 + 参照 URL に退避する。
     */
    fun buildCalendarMirrorBody(
        currentBody: String,
        referenceUrl: String? = null,
        maxDescriptionLength: Int = 3000,
        summaryLength: Int = 240
    ): String {
        val normalized = normalizeBodyForStorage(currentBody)
        if (normalized.length <= maxDescriptionLength) return normalized

        val summary = normalized.take(summaryLength).trimEnd()
        val fallbackUrl = referenceUrl?.takeIf { it.isNotBlank() }
        return buildString {
            append(summary)
            append("\n\n")
            append("本文は YourselfLM で閲覧してください")
            if (fallbackUrl != null) {
                append("\n")
                append(fallbackUrl)
            }
        }
    }
}

