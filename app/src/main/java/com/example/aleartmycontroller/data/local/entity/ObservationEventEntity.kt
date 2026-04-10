package com.example.aleartmycontroller.data.local.entity

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

/**
 * ユーザー観察セッションのスナップショット。
 *
 * EventEntity（Google Calendar キャッシュ）とは独立した永続エンティティ。
 * カレンダー同期による EventEntity の削除があっても、このエンティティと
 * そこに紐づく RecordEntity（写真・メモ）は保持される。
 *
 * googleEventId は元の Calendar イベントへのソフト参照（外部キー制約なし）。
 * カレンダー側のイベントが削除されても NULL にはならず、文字列として残る。
 *
 * title / startTime / endTime は観察開始時点のスナップショット。
 * カレンダー側で後からイベント名や時間が変更されても影響を受けない。
 */
@Entity(
    tableName = "observation_events",
    indices = [Index(value = ["googleEventId"], unique = true)]
)
data class ObservationEventEntity(
    @PrimaryKey(autoGenerate = true) val obsEventId: Long = 0,
    val googleEventId: String?,  // soft reference — no FK to events table
    val title: String,
    val startTime: Long,         // epoch millis, snapshot at session start
    val endTime: Long            // epoch millis, snapshot at session start
)
