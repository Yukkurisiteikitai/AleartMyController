package com.example.aleartmycontroller.data.remote.toggl

import com.google.gson.annotations.SerializedName

data class TogglTimeEntryRequest(
    val description: String,
    @SerializedName("start") val start: String, // ISO8601
    @SerializedName("duration") val duration: Long, // -1 if running
    @SerializedName("workspace_id") val workspaceId: Long,
    @SerializedName("created_with") val createdWith: String = "AleartMyController",
    @SerializedName("tags") val tags: List<String> = emptyList()
)

data class TogglTimeEntry(
    val id: Long,
    @SerializedName("workspace_id") val workspaceId: Long,
    val description: String?,
    val start: String,
    val stop: String?,
    val duration: Long,
    val tags: List<String>?
)

data class TogglMe(
    @SerializedName("default_workspace_id") val defaultWorkspaceId: Long,
    val email: String
)
