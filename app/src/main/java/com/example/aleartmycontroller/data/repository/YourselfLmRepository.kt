package com.example.aleartmycontroller.data.repository

import com.example.aleartmycontroller.BuildConfig
import com.example.aleartmycontroller.data.local.entity.EventEntity
import com.example.aleartmycontroller.data.local.entity.MemoEntity
import com.example.aleartmycontroller.data.local.entity.PhotoEntity
import com.example.aleartmycontroller.data.local.entity.RecordEntity
import com.example.aleartmycontroller.data.remote.yourselflm.YourSelfLmObservationResponse
import com.example.aleartmycontroller.data.remote.yourselflm.YourselfLmApi
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class YourselfLmRepository @Inject constructor(
    private val yourselfLmApi: YourselfLmApi
) {
    suspend fun submitRecord(
        event: EventEntity,
        record: RecordEntity,
        photos: List<PhotoEntity> = emptyList(),
        memos: List<MemoEntity> = emptyList(),
        source: String = "android"
    ): Result<YourSelfLmObservationResponse?> {
        if (BuildConfig.YOURSELF_LM_API_BASE_URL.isBlank()) return Result.success(null)
        if (BuildConfig.YOURSELF_LM_API_TOKEN.isBlank()) return Result.success(null)

        val request = com.example.aleartmycontroller.data.remote.yourselflm.YourSelfLmObservationRequest(
            eventTitle = event.title,
            eventStartTime = event.startTime,
            eventEndTime = event.endTime,
            recordTime = record.recordTime,
            recordType = record.recordType.name,
            recordText = memos.firstOrNull()?.memoText,
            attachmentCount = photos.size,
            source = source
        )

        return runCatching { yourselfLmApi.submitObservation(request) }
    }
}
