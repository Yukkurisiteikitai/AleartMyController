package com.example.aleartmycontroller.data.amc

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class AmcContentPolicyTest {
    @Test
    fun normalizeBodyForStorage_trimsAndNormalizes() {
        val input = "  cafe\u0301  "
        assertEquals("café", AmcContentPolicy.normalizeBodyForStorage(input))
    }

    @Test
    fun buildCalendarMirrorBody_fallsBackToSummaryWhenTooLong() {
        val input = buildString {
            repeat(4_000) { append("あ") }
        }
        val output = AmcContentPolicy.buildCalendarMirrorBody(input, referenceUrl = "https://example.com")

        assertTrue(output.contains("本文は YourselfLM で閲覧してください"))
        assertTrue(output.contains("https://example.com"))
        assertTrue(output.length < input.length)
    }

    @Test
    fun allowedMimeTypes_includeCommonImageAndAudioFormats() {
        assertTrue(AmcContentPolicy.isAllowedAttachmentMime("image/jpeg"))
        assertTrue(AmcContentPolicy.isAllowedAttachmentMime("audio/mpeg"))
        assertTrue(!AmcContentPolicy.isAllowedAttachmentMime("application/pdf"))
    }
}

