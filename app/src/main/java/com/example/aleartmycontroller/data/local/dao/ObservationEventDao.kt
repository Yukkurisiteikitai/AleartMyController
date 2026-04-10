package com.example.aleartmycontroller.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.example.aleartmycontroller.data.local.entity.ObservationEventEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface ObservationEventDao {

    /**
     * 新しい ObservationEvent を挿入する。
     * googleEventId に UNIQUE 制約があるため、重複時は IGNORE（既存行を保持）。
     * 挿入された場合は生成された obsEventId、無視された場合は -1 を返す。
     */
    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insert(entity: ObservationEventEntity): Long

    @Query("SELECT * FROM observation_events WHERE googleEventId = :googleEventId")
    suspend fun findByGoogleEventId(googleEventId: String): ObservationEventEntity?

    @Query("SELECT * FROM observation_events WHERE obsEventId = :id")
    suspend fun findById(id: Long): ObservationEventEntity?

    /** 履歴画面・分析画面向け：全件を開始時刻降順で監視 */
    @Query("SELECT * FROM observation_events ORDER BY startTime DESC")
    fun observeAll(): Flow<List<ObservationEventEntity>>
}
