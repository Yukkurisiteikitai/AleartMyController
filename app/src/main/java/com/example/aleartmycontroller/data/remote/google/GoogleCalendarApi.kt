package com.example.aleartmycontroller.data.remote.google

import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.PATCH
import retrofit2.http.POST
import retrofit2.http.Path
import retrofit2.http.Query

/**
 * Google Calendar REST API v3
 * https://developers.google.com/calendar/api/v3/reference
 *
 * 認証: API Key を query parameter として付与する。
 * OAuth2 が必要なユーザーカレンダーに対しては Bearer トークンが別途必要だが、
 * 初期版は calendarId=primary で API Key のみを使用する。
 */
interface GoogleCalendarApi {

    @GET("calendars/{calendarId}/events/{eventId}")
    suspend fun getEvent(
        @Path("calendarId") calendarId: String = "primary",
        @Path("eventId") eventId: String
    ): CalendarEvent

    /**
     * カレンダーのイベント一覧を取得する。
     *
     * @param calendarId  カレンダーID ("primary" でログインユーザーの予定)
     * @param apiKey      BuildConfig.GOOGLE_CALENDAR_API_KEY
     * @param timeMin     取得開始時刻 (RFC3339)
     * @param timeMax     取得終了時刻 (RFC3339)
     * @param singleEvents trueにするとrecurringイベントを展開
     * @param orderBy     startTime でソート
     * @param maxResults  最大取得件数
     */
    @GET("calendars/{calendarId}/events")
    suspend fun listEvents(
        @Path("calendarId") calendarId: String = "primary",
        @Query("timeMin") timeMin: String,
        @Query("timeMax") timeMax: String,
        @Query("singleEvents") singleEvents: Boolean = true,
        @Query("orderBy") orderBy: String = "startTime",
        @Query("maxResults") maxResults: Int = 100
    ): CalendarEventsResponse

    @POST("calendars/{calendarId}/events")
    suspend fun insertEvent(
        @Path("calendarId") calendarId: String = "primary",
        @Body body: CalendarEventUpsertRequest
    ): CalendarEvent

    @PATCH("calendars/{calendarId}/events/{eventId}")
    suspend fun patchEvent(
        @Path("calendarId") calendarId: String = "primary",
        @Path("eventId") eventId: String,
        @Body body: CalendarEventPatchRequest
    ): CalendarEvent

    companion object {
        const val BASE_URL = "https://www.googleapis.com/calendar/v3/"
    }
}
