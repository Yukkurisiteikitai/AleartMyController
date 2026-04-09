package com.example.aleartmycontroller.data.remote.toggl

import retrofit2.http.*

/**
 * Toggl Track REST API v9
 * https://developers.track.toggl.com/docs/api/time_entries
 *
 * 認証: HTTP Basic Auth (username=APIトークン, password="api_token")
 * OkHttp の BasicAuthInterceptor で付与する。
 */
interface TogglApi {

    /**
     * 指定期間の時間エントリを取得する。
     *
     * @param startDate  開始日 "YYYY-MM-DD" または ISO8601
     * @param endDate    終了日
     */
    @GET("me")
    suspend fun getMe(): TogglMe

    @GET("me/time_entries")
    suspend fun getTimeEntries(
        @Query("start_date") startDate: String,
        @Query("end_date") endDate: String
    ): List<TogglTimeEntry>

    @POST("workspaces/{workspace_id}/time_entries")
    suspend fun createTimeEntry(
        @Path("workspace_id") workspaceId: Long,
        @Body request: TogglTimeEntryRequest
    ): TogglTimeEntry

    @GET("me/time_entries/current")
    suspend fun getCurrentTimeEntry(): TogglTimeEntry?

    @PATCH("workspaces/{workspace_id}/time_entries/{time_entry_id}/stop")
    suspend fun stopTimeEntry(
        @Path("workspace_id") workspaceId: Long,
        @Path("time_entry_id") timeEntryId: Long
    ): TogglTimeEntry

    companion object {
        const val BASE_URL = "https://api.track.toggl.com/api/v9/"
    }
}
