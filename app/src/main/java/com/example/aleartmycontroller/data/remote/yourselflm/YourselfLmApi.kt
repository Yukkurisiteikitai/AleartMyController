package com.example.aleartmycontroller.data.remote.yourselflm

import retrofit2.http.Body
import retrofit2.http.POST

data class YourSelfLmObservationRequest(
    val eventTitle: String,
    val eventStartTime: Long,
    val eventEndTime: Long,
    val recordTime: Long,
    val recordType: String,
    val recordText: String? = null,
    val attachmentCount: Int = 0,
    val source: String = "android"
)

data class YourSelfLmObservationResponse(
    val accepted: Boolean,
    val queued: Boolean = false,
    val message: String? = null
)

interface YourselfLmApi {
    @POST("api/android/observations")
    suspend fun submitObservation(@Body request: YourSelfLmObservationRequest): YourSelfLmObservationResponse
}
