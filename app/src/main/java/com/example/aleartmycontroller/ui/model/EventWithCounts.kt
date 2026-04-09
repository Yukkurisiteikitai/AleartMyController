package com.example.aleartmycontroller.ui.model

import com.example.aleartmycontroller.data.local.entity.EventEntity

/**
 * イベント情報とそれに紐づく記録数のサマリー。
 * イベント一覧画面でのバッジ表示に使用。
 */
data class EventWithCounts(
    val event: EventEntity,
    val photoCount: Int = 0,
    val memoCount: Int = 0
)
