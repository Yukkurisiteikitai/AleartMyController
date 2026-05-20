package com.example.aleartmycontroller.data.remote.google

import com.google.gson.annotations.SerializedName

// ---- レスポンスモデル ----

data class CalendarEventsResponse(
    val items: List<CalendarEvent>
)

data class CalendarEvent(
    val id: String,
    val summary: String?,
    val description: String? = null,
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

data class CalendarEventDateTimeRequest(
    @SerializedName("dateTime") val dateTime: String,
    @SerializedName("timeZone") val timeZone: String? = null
)

data class CalendarEventUpsertRequest(
    val summary: String,
    val description: String? = null,
    val start: CalendarEventDateTimeRequest,
    val end: CalendarEventDateTimeRequest
)

data class CalendarEventPatchRequest(
    val summary: String? = null,
    val description: String? = null,
    val start: CalendarEventDateTimeRequest? = null,
    val end: CalendarEventDateTimeRequest? = null
)
