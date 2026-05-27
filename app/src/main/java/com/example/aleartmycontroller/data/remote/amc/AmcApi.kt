package com.example.aleartmycontroller.data.remote.amc

import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.POST
import retrofit2.http.Path
import retrofit2.http.Query

interface AmcApi {
    @POST("api/amc/records/init")
    suspend fun initRecord(@Body body: AmcRecordInitRequest): AmcRecordInitResponse

    @POST("api/amc/records/{id}")
    suspend fun saveRecord(
        @Path("id") recordId: String,
        @Body body: AmcRecordUpsertRequest
    ): AmcRecordResponse

    @POST("api/amc/records/{id}/revisions")
    suspend fun appendRevision(
        @Path("id") recordId: String,
        @Body body: AmcRecordRevisionCreateRequest
    ): AmcRecordRevisionResponse

    @POST("api/amc/records/{id}/attachments/init")
    suspend fun initAttachment(
        @Path("id") recordId: String,
        @Body body: AmcAttachmentInitRequest
    ): AmcAttachmentInitResponse

    @POST("api/amc/records/{id}/attachments/complete")
    suspend fun completeAttachment(
        @Path("id") recordId: String,
        @Body body: AmcAttachmentCompleteRequest
    ): AmcAttachmentResponse

    @GET("connect/app/amc/share")
    suspend fun resolveShare(
        @Query("c") code: String
    ): AmcShareResolutionResponse

    @POST("api/amc/share-links/{id}/revoke")
    suspend fun revokeShareLink(@Path("id") shareLinkId: String)

    @GET("api/amc/records/{id}/access")
    suspend fun getRecordAccess(
        @Path("id") recordId: String
    ): AmcRecordAccessResponse
}

