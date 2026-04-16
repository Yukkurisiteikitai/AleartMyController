package com.example.aleartmycontroller.data.preferences

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

/** DataStore シングルトン */
private val Context.dataStore: DataStore<Preferences>
    by preferencesDataStore(name = "app_settings")

/**
 * アプリ設定の永続化。
 * 撮影インターバル（分単位）・プリセット順序・通知有効フラグを保持する。
 */
@Singleton
class AppPreferences @Inject constructor(
    @ApplicationContext private val context: Context
) {
    companion object {
        /** 撮影インターバル（分）: デフォルト 60 分 */
        val KEY_INTERVAL_MINUTES = intPreferencesKey("interval_minutes")

        /**
         * プリセット順序: カンマ区切りの分数リスト文字列
         * 例: "1,3,5,10,25,30,60,0"  (0 = カスタム)
         */
        val KEY_PRESET_ORDER = stringPreferencesKey("preset_order")

        /** 通知の有効フラグ (1=有効, 0=無効) */
        val KEY_NOTIFICATIONS_ENABLED = intPreferencesKey("notifications_enabled")

        /** カスタムインターバル（分） */
        val KEY_CUSTOM_INTERVAL_MINUTES = intPreferencesKey("custom_interval_minutes")

        /** AI サービスへの自動同期有効フラグ */
        val KEY_YOURSELF_LM_SYNC_ENABLED = booleanPreferencesKey("yourself_lm_sync_enabled")

        val DEFAULT_PRESET_ORDER = "1,3,5,10,25,30,60,0"
        const val DEFAULT_INTERVAL_MINUTES = 60
    }

    val intervalMinutes: Flow<Int> = context.dataStore.data.map { prefs ->
        prefs[KEY_INTERVAL_MINUTES] ?: DEFAULT_INTERVAL_MINUTES
    }

    val presetOrder: Flow<List<Int>> = context.dataStore.data.map { prefs ->
        val raw = prefs[KEY_PRESET_ORDER] ?: DEFAULT_PRESET_ORDER
        raw.split(",").mapNotNull { it.trim().toIntOrNull() }
    }

    val notificationsEnabled: Flow<Boolean> = context.dataStore.data.map { prefs ->
        (prefs[KEY_NOTIFICATIONS_ENABLED] ?: 1) == 1
    }

    val customIntervalMinutes: Flow<Int> = context.dataStore.data.map { prefs ->
        prefs[KEY_CUSTOM_INTERVAL_MINUTES] ?: 30
    }

    val yourselfLmSyncEnabled: Flow<Boolean> = context.dataStore.data.map { prefs ->
        prefs[KEY_YOURSELF_LM_SYNC_ENABLED] ?: false
    }

    suspend fun setIntervalMinutes(minutes: Int) {
        context.dataStore.edit { it[KEY_INTERVAL_MINUTES] = minutes }
    }

    suspend fun setPresetOrder(order: List<Int>) {
        context.dataStore.edit { it[KEY_PRESET_ORDER] = order.joinToString(",") }
    }

    suspend fun setNotificationsEnabled(enabled: Boolean) {
        context.dataStore.edit { it[KEY_NOTIFICATIONS_ENABLED] = if (enabled) 1 else 0 }
    }

    suspend fun setCustomIntervalMinutes(minutes: Int) {
        context.dataStore.edit { it[KEY_CUSTOM_INTERVAL_MINUTES] = minutes }
    }

    suspend fun setYourselfLmSyncEnabled(enabled: Boolean) {
        context.dataStore.edit { it[KEY_YOURSELF_LM_SYNC_ENABLED] = enabled }
    }
}
