package com.example.aleartmycontroller.data.repository

import com.example.aleartmycontroller.BuildConfig
import com.example.aleartmycontroller.data.remote.toggl.TogglApi
import com.example.aleartmycontroller.data.remote.toggl.TogglTimeEntry
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class TogglRepository @Inject constructor(
    private val togglApi: TogglApi
) {
    private val dateFormatter: DateTimeFormatter = DateTimeFormatter.ISO_LOCAL_DATE

    /**
     * 今日の時間エントリを取得する。
     */
    suspend fun getTodayEntries(): List<com.example.aleartmycontroller.data.remote.toggl.TogglTimeEntry> {
        if (BuildConfig.TOGGL_API_TOKEN.isBlank()) return emptyByNull()
        val today = LocalDate.now().format(dateFormatter)
        return runCatching { togglApi.getTimeEntries(startDate = today, endDate = today) }.getOrDefault(emptyList())
    }

    /**
     * 指定期間の時間エントリを取得する。
     */
    suspend fun getEntriesForRange(startDate: String, endDate: String): List<com.example.aleartmycontroller.data.remote.toggl.TogglTimeEntry> {
        if (BuildConfig.TOGGL_API_TOKEN.isBlank()) return emptyByNull()
        return runCatching { togglApi.getTimeEntries(startDate = startDate, endDate = endDate) }.getOrDefault(emptyList())
    }

    private fun emptyByNull() = emptyList<com.example.aleartmycontroller.data.remote.toggl.TogglTimeEntry>()

    /**
     * 指定された内容で時間エントリを作成する。
     */
    suspend fun createEntry(description: String, tags: List<String> = emptyList()) {
        if (BuildConfig.TOGGL_API_TOKEN.isBlank()) return
        runCatching {
            val me = togglApi.getMe()
            val request = com.example.aleartmycontroller.data.remote.toggl.TogglTimeEntryRequest(
                description = description,
                start = java.time.OffsetDateTime.now().format(java.time.format.DateTimeFormatter.ISO_OFFSET_DATE_TIME),
                duration = -1, // 進行中として作成
                workspaceId = me.defaultWorkspaceId,
                tags = tags
            )
            togglApi.createTimeEntry(me.defaultWorkspaceId, request)
        }
    }

    /**
     * 現在進行中のエントリを停止する。
     */
    suspend fun stopCurrentRunningEntry() {
        if (BuildConfig.TOGGL_API_TOKEN.isBlank()) return
        runCatching {
            val current = togglApi.getCurrentTimeEntry() ?: return@runCatching
            togglApi.stopTimeEntry(current.workspaceId, current.id)
        }
    }
}
