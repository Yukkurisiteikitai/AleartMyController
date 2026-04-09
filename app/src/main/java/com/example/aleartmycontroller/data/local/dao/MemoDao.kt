package com.example.aleartmycontroller.data.local.dao

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.example.aleartmycontroller.data.local.entity.MemoEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface MemoDao {

    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insert(memo: MemoEntity): Long

    @Delete
    suspend fun delete(memo: MemoEntity)

    @Query("SELECT * FROM memos WHERE recordId = :recordId")
    fun observeByRecord(recordId: Long): Flow<List<MemoEntity>>

    @Query("SELECT * FROM memos WHERE recordId = :recordId")
    suspend fun findByRecord(recordId: Long): List<MemoEntity>
}
