package com.example.aleartmycontroller.data.repository

import com.example.aleartmycontroller.data.local.dao.MemoDao
import com.example.aleartmycontroller.data.local.dao.PhotoDao
import com.example.aleartmycontroller.data.local.dao.RecordDao
import com.example.aleartmycontroller.data.local.entity.MemoEntity
import com.example.aleartmycontroller.data.local.entity.PhotoEntity
import com.example.aleartmycontroller.data.local.entity.RecordEntity
import com.example.aleartmycontroller.data.local.entity.RecordType
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class RecordRepository @Inject constructor(
    private val recordDao: RecordDao,
    private val photoDao: PhotoDao,
    private val memoDao: MemoDao
) {
    fun observeRecordsByEvent(eventId: Long): Flow<List<RecordEntity>> =
        recordDao.observeByEvent(eventId)

    fun observeAllRecords(): Flow<List<RecordEntity>> =
        recordDao.observeAll()

    suspend fun findRecordById(recordId: Long): RecordEntity? =
        recordDao.findById(recordId)

    /** 写真記録を追加する (record + photo を同一トランザクション内で保存) */
    suspend fun addPhotoRecord(eventId: Long, filePath: String): Long {
        val record = RecordEntity(
            eventId = eventId,
            recordTime = System.currentTimeMillis(),
            recordType = RecordType.PHOTO
        )
        val recordId = recordDao.insert(record)
        photoDao.insert(PhotoEntity(recordId = recordId, filePath = filePath))
        return recordId
    }

    /** テキスト／音声メモ記録を追加する */
    suspend fun addMemoRecord(
        eventId: Long,
        text: String,
        isVoice: Boolean = false
    ): Long {
        val record = RecordEntity(
            eventId = eventId,
            recordTime = System.currentTimeMillis(),
            recordType = RecordType.MEMO
        )
        val recordId = recordDao.insert(record)
        memoDao.insert(MemoEntity(recordId = recordId, memoText = text, isVoiceMemo = isVoice))
        return recordId
    }

    suspend fun deleteRecord(record: RecordEntity) = recordDao.delete(record)

    suspend fun getPhotosForRecord(recordId: Long): List<PhotoEntity> =
        photoDao.findByRecord(recordId)

    suspend fun getMemosForRecord(recordId: Long): List<MemoEntity> =
        memoDao.findByRecord(recordId)

    suspend fun countPhotos(eventId: Long): Int =
        recordDao.countByType(eventId, RecordType.PHOTO)

    suspend fun countMemos(eventId: Long): Int =
        recordDao.countByType(eventId, RecordType.MEMO)
}
