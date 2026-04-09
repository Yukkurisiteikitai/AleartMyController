package com.example.aleartmycontroller.data.remote.toggl

import retrofit2.http.GET
import retrofit2.http.Query

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

    @retrofit2.http.POST("workspaces/{workspace_id}/time_entries")
    suspend fun createTimeEntry(
        @retrofit2.http.Path("workspace_id") workspaceId: Long,
        @retrofit2.http.Body request: TogglTimeEntryRequest
    ): TogglTimeEntry

    companion object {
        const val BASE_URL = "https://api.track.toggl.com/api/v9/"
    }
}
