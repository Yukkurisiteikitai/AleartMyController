package com.example.aleartmycontroller.data.remote.google

import com.google.gson.annotations.SerializedName

// ---- レスポンスモデル ----

data class CalendarEventsResponse(
    val items: List<CalendarEvent>
)

data class CalendarEvent(
    val id: String,
    val summary: String?,
    val start: CalendarDateTime,
    val end: CalendarDateTime
)

data class CalendarDateTime(
    @SerializedName("dateTime") val dateTime: String?,
    @SerializedName("date") val date: String?
) {
    /** ISO8601文字列をそのまま返す。終日イベントなら date を使用 */
    val value: String get() = dateTime ?: "${date}T00:00:00+09:00"
}
