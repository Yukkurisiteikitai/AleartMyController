package com.example.aleartmycontroller.data.repository

import com.example.aleartmycontroller.data.local.dao.ObservationEventDao
import com.example.aleartmycontroller.data.local.entity.EventEntity
import com.example.aleartmycontroller.data.local.entity.ObservationEventEntity
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ObservationEventRepository @Inject constructor(
    private val dao: ObservationEventDao
) {
    /**
     * EventEntity に対応する ObservationEvent の obsEventId を返す。
     * 既存行があればその ID を返し、なければスナップショットを新規挿入して ID を返す。
     *
     * INSERT OR IGNORE の仕様上、既存行が無視された場合は -1 が返るため、
     * その場合は改めて SELECT で取得する。
     */
    suspend fun findOrCreate(event: EventEntity): Long {
        val inserted = dao.insert(
            ObservationEventEntity(
                googleEventId = event.googleEventId,
                title = event.title,
                startTime = event.startTime,
                endTime = event.endTime
            )
        )
        if (inserted != -1L) return inserted
        return dao.findByGoogleEventId(event.googleEventId)!!.obsEventId
    }

    suspend fun findById(obsEventId: Long): ObservationEventEntity? =
        dao.findById(obsEventId)
}
