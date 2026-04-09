package com.example.aleartmycontroller.data.local.dao

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.example.aleartmycontroller.data.local.entity.PhotoEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface PhotoDao {

    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insert(photo: PhotoEntity): Long

    @Delete
    suspend fun delete(photo: PhotoEntity)

    @Query("SELECT * FROM photos WHERE recordId = :recordId")
    fun observeByRecord(recordId: Long): Flow<List<PhotoEntity>>

    @Query("SELECT * FROM photos WHERE recordId = :recordId")
    suspend fun findByRecord(recordId: Long): List<PhotoEntity>
}
