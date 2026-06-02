package com.example.aleartmycontroller.data.repository

import com.example.aleartmycontroller.data.local.dao.MemoDao
import com.example.aleartmycontroller.data.local.dao.PhotoDao
import com.example.aleartmycontroller.data.local.dao.RecordDao
import com.example.aleartmycontroller.data.amc.AmcContentPolicy
import com.example.aleartmycontroller.data.local.entity.EventEntity
import com.example.aleartmycontroller.data.local.entity.MemoEntity
import com.example.aleartmycontroller.data.local.entity.PhotoEntity
import com.example.aleartmycontroller.data.local.entity.RecordEntity
import com.example.aleartmycontroller.data.local.entity.RecordType
import com.example.aleartmycontroller.data.local.entity.RecordWithAttachments
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class RecordRepository @Inject constructor(
    private val recordDao: RecordDao,
    private val photoDao: PhotoDao,
    private val memoDao: MemoDao,
    private val observationEventRepository: ObservationEventRepository
) {
    // ---- 監視（呼び出し側は引き続き EventEntity.eventId を渡せる） ----

    fun observeRecordsByEvent(eventId: Long): Flow<List<RecordEntity>> =
        recordDao.observeByEvent(eventId)

    fun observeRecordsByEventWithAttachments(eventId: Long): Flow<List<RecordWithAttachments>> =
        recordDao.observeByEventWithAttachments(eventId)

    fun observeAllRecords(): Flow<List<RecordEntity>> =
        recordDao.observeAll()

    fun observeAllRecordsWithAttachments(): Flow<List<RecordWithAttachments>> =
        recordDao.observeAllWithAttachments()

    suspend fun findRecordById(recordId: Long): RecordEntity? =
        recordDao.findById(recordId)

    // ---- 記録追加（EventEntity を受け取り、obsEventId を内部解決する） ----

    /** 写真記録を追加する（record + photo を同一トランザクション内で保存） */
    suspend fun addPhotoRecord(event: EventEntity, filePath: String): Long {
        val obsEventId = observationEventRepository.findOrCreate(event)
        val record = RecordEntity(
            obsEventId = obsEventId,
            recordTime = System.currentTimeMillis(),
            recordType = RecordType.PHOTO
        )
        val recordId = recordDao.insert(record)
        photoDao.insert(PhotoEntity(recordId = recordId, filePath = filePath))
        return recordId
    }

    /** テキスト／音声メモ記録を追加する */
    suspend fun addMemoRecord(
        event: EventEntity,
        text: String,
        isVoice: Boolean = false
    ): Long {
        val normalizedText = AmcContentPolicy.normalizeBodyForStorage(text)
        val obsEventId = observationEventRepository.findOrCreate(event)
        val record = RecordEntity(
            obsEventId = obsEventId,
            recordTime = System.currentTimeMillis(),
            recordType = RecordType.MEMO
        )
        val recordId = recordDao.insert(record)
        memoDao.insert(MemoEntity(recordId = recordId, memoText = normalizedText, isVoiceMemo = isVoice))
        return recordId
    }

    suspend fun deleteRecord(record: RecordEntity) = recordDao.delete(record)

    suspend fun getPhotosForRecord(recordId: Long): List<PhotoEntity> =
        photoDao.findByRecord(recordId)

    suspend fun getMemosForRecord(recordId: Long): List<MemoEntity> =
        memoDao.findByRecord(recordId)

    // ---- 集計（呼び出し側は引き続き EventEntity.eventId を渡せる） ----

    suspend fun countPhotos(eventId: Long): Int =
        recordDao.countByType(eventId, RecordType.PHOTO)

    suspend fun countMemos(eventId: Long): Int =
        recordDao.countByType(eventId, RecordType.MEMO)
}
