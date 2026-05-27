package com.example.aleartmycontroller.data.repository

import com.example.aleartmycontroller.data.local.dao.TogglPendingActionDao
import com.example.aleartmycontroller.data.local.dao.TogglSyncStateDao
import com.example.aleartmycontroller.data.local.dao.TogglTimeEntryCacheDao
import com.example.aleartmycontroller.data.local.entity.TogglPendingActionEntity
import com.example.aleartmycontroller.data.local.entity.TogglSyncStateEntity
import com.example.aleartmycontroller.data.local.entity.TogglTimeEntryCacheEntity
import com.example.aleartmycontroller.data.preferences.TogglTokenStore
import com.example.aleartmycontroller.data.remote.toggl.TogglApi
import com.example.aleartmycontroller.data.remote.toggl.TogglMe
import com.example.aleartmycontroller.data.remote.toggl.TogglTimeEntry
import com.example.aleartmycontroller.data.remote.toggl.TogglTimeEntryRequest
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import java.time.Instant
import java.time.LocalDate
import java.time.OffsetDateTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import javax.inject.Inject
import javax.inject.Singleton

sealed class TogglSyncOutcome {
    data object NoToken : TogglSyncOutcome()
    data object NoPendingAction : TogglSyncOutcome()
    data object Success : TogglSyncOutcome()
    data class Failure(val message: String) : TogglSyncOutcome()
}

@Singleton
class TogglRepository @Inject constructor(
    private val togglApi: TogglApi,
    private val tokenStore: TogglTokenStore,
    private val syncStateDao: TogglSyncStateDao,
    private val pendingActionDao: TogglPendingActionDao,
    private val cacheDao: TogglTimeEntryCacheDao
) {
    private val dateFormatter = DateTimeFormatter.ISO_LOCAL_DATE
    private val isoFormatter = DateTimeFormatter.ISO_OFFSET_DATE_TIME
    private val zoneId = ZoneId.systemDefault()
    private val syncMutex = Mutex()
    private val networkSpacingMutex = Mutex()
    private var lastNetworkCallAtMillis = 0L

    fun observeSyncState(): Flow<TogglSyncStateEntity> {
        return syncStateDao.observeState().map { it ?: defaultState(tokenStore.hasToken()) }
    }

    fun observePendingCount(): Flow<Int> = pendingActionDao.observePendingCount()

    suspend fun isConfigured(): Boolean = tokenStore.hasToken()

    suspend fun saveToken(token: String) {
        tokenStore.setToken(token)
        ensureState().let { current ->
            syncStateDao.upsert(
                current.copy(
                    syncStatus = if (current.autoSyncEnabled) STATUS_SYNCED else STATUS_READY,
                    lastErrorMessage = null
                )
            )
        }
    }

    suspend fun clearToken() {
        tokenStore.clearToken()
        val current = ensureState()
        syncStateDao.upsert(
            current.copy(
                autoSyncEnabled = false,
                syncStatus = STATUS_UNCONFIGURED,
                lastErrorMessage = null,
                defaultWorkspaceId = null
            )
        )
    }

    suspend fun markInitialSetupCompleted() {
        val current = ensureState()
        syncStateDao.upsert(current.copy(syncStatus = if (tokenStore.hasToken()) STATUS_READY else STATUS_UNCONFIGURED))
    }

    suspend fun queueCreateEntry(description: String, tags: List<String> = emptyList()) {
        pendingActionDao.insert(
            TogglPendingActionEntity(
                actionType = TogglPendingActionEntity.ACTION_CREATE,
                description = description,
                tagsCsv = tags.joinToString(",")
            )
        )
        updateQueuedState()
        if (shouldAutoSync()) {
            syncPendingActions(manualTrigger = false)
        }
    }

    suspend fun queueStopCurrentEntry() {
        pendingActionDao.insert(
            TogglPendingActionEntity(
                actionType = TogglPendingActionEntity.ACTION_STOP
            )
        )
        updateQueuedState()
        if (shouldAutoSync()) {
            syncPendingActions(manualTrigger = false)
        }
    }

    suspend fun startInitialSync(): TogglSyncOutcome {
        return syncPendingActions(manualTrigger = true)
    }

    suspend fun syncPendingActions(manualTrigger: Boolean = false): TogglSyncOutcome = syncMutex.withLock {
        if (!tokenStore.hasToken()) {
            updateState(
                syncStatus = STATUS_UNCONFIGURED,
                lastErrorMessage = "Toggl token が未設定です"
            )
            return TogglSyncOutcome.NoToken
        }

        ensureState()
        updateState(
            syncStatus = STATUS_SYNCING,
            lastAttemptAtMillis = System.currentTimeMillis(),
            lastErrorMessage = null
        )

        val pending = pendingActionDao.getAllPending()
        if (pending.isEmpty()) {
            if (manualTrigger) {
                refreshCacheFromNetwork(defaultDays = 30)
                enableAutoSyncIfNeeded()
                updateState(
                    syncStatus = STATUS_SYNCED,
                    lastSyncedAtMillis = System.currentTimeMillis(),
                    lastErrorMessage = null
                )
                return TogglSyncOutcome.Success
            }

            updateState(syncStatus = STATUS_READY)
            return TogglSyncOutcome.NoPendingAction
        }

        for (action in pending) {
            val result = runCatching { executeAction(action) }
            result.onFailure { error ->
                pendingActionDao.markFailed(
                    actionId = action.actionId,
                    attemptCount = action.attemptCount + 1,
                    lastAttemptAtMillis = System.currentTimeMillis(),
                    lastErrorMessage = error.localizedMessage ?: "同期に失敗しました"
                )
                updateState(
                    syncStatus = STATUS_FAILED,
                    lastAttemptAtMillis = System.currentTimeMillis(),
                    lastErrorMessage = error.localizedMessage ?: "同期に失敗しました"
                )
                return TogglSyncOutcome.Failure(error.localizedMessage ?: "同期に失敗しました")
            }
            pendingActionDao.deleteById(action.actionId)
        }

        refreshCacheFromNetwork(defaultDays = 30)
        if (manualTrigger) {
            enableAutoSyncIfNeeded()
        }
        updateState(
            syncStatus = STATUS_SYNCED,
            lastSyncedAtMillis = System.currentTimeMillis(),
            lastErrorMessage = null
        )
        TogglSyncOutcome.Success
    }

    suspend fun getTodayEntries(): List<TogglTimeEntry> {
        val today = LocalDate.now().format(dateFormatter)
        return getEntriesForRange(today, today)
    }

    suspend fun getEntriesForRange(startDate: String, endDate: String): List<TogglTimeEntry> {
        val start = parseLocalDate(startDate)
        val end = parseLocalDate(endDate)
        return if (tokenStore.hasToken()) {
            runCatching {
                val response = withRateLimit {
                    togglApi.getTimeEntries(startDate = startDate, endDate = endDate)
                }
                cacheTimeEntries(response)
                response
            }.getOrElse {
                loadCachedEntries(start, end).map { it.toApiModel() }
            }
        } else {
            loadCachedEntries(start, end).map { it.toApiModel() }
        }
    }

    suspend fun getEntriesForRange(fromMillis: Long, toMillis: Long): List<TogglTimeEntry> {
        val startDate = Instant.ofEpochMilli(fromMillis).atZone(zoneId).toLocalDate().format(dateFormatter)
        val endDate = Instant.ofEpochMilli(toMillis).atZone(zoneId).toLocalDate().format(dateFormatter)
        return getEntriesForRange(startDate, endDate)
    }

    suspend fun createEntry(description: String, tags: List<String> = emptyList()) {
        queueCreateEntry(description, tags)
    }

    suspend fun stopCurrentRunningEntry() {
        queueStopCurrentEntry()
    }

    private suspend fun executeAction(action: TogglPendingActionEntity) {
        when (action.actionType) {
            TogglPendingActionEntity.ACTION_CREATE -> {
                val me = getMe()
                val request = TogglTimeEntryRequest(
                    description = action.description.orEmpty(),
                    start = OffsetDateTime.now().format(DateTimeFormatter.ISO_OFFSET_DATE_TIME),
                    duration = -1,
                    workspaceId = me.defaultWorkspaceId,
                    tags = action.tagsCsv.split(",").mapNotNull { it.trim().takeIf(String::isNotBlank) }
                )
                withRateLimit {
                    togglApi.createTimeEntry(me.defaultWorkspaceId, request)
                }
                updateWorkspaceId(me.defaultWorkspaceId)
            }

            TogglPendingActionEntity.ACTION_STOP -> {
                val current = withRateLimit { togglApi.getCurrentTimeEntry() }
                current?.let {
                    withRateLimit { togglApi.stopTimeEntry(it.workspaceId, it.id) }
                }
            }

            else -> error("Unknown Toggl action: ${action.actionType}")
        }
    }

    private suspend fun getMe(): TogglMe {
        val currentState = ensureState()
        currentState.defaultWorkspaceId?.let { workspaceId ->
            return TogglMe(defaultWorkspaceId = workspaceId, email = "")
        }
        val me = withRateLimit { togglApi.getMe() }
        updateWorkspaceId(me.defaultWorkspaceId)
        return me
    }

    private suspend fun updateWorkspaceId(workspaceId: Long) {
        val current = ensureState()
        syncStateDao.upsert(current.copy(defaultWorkspaceId = workspaceId))
    }

    private suspend fun refreshCacheFromNetwork(defaultDays: Int) {
        if (!tokenStore.hasToken()) return
        val end = LocalDate.now()
        val start = end.minusDays(defaultDays.toLong())
        val entries = runCatching {
            withRateLimit {
                togglApi.getTimeEntries(
                    startDate = start.format(dateFormatter),
                    endDate = end.format(dateFormatter)
                )
            }
        }.getOrNull() ?: return
        cacheTimeEntries(entries)
    }

    private suspend fun cacheTimeEntries(entries: List<TogglTimeEntry>) {
        if (entries.isEmpty()) return
        cacheDao.upsertAll(entries.mapNotNull { it.toCacheEntity() })
    }

    private suspend fun loadCachedEntries(start: LocalDate, end: LocalDate): List<TogglTimeEntryCacheEntity> {
        val fromMillis = start.atStartOfDay(zoneId).toInstant().toEpochMilli()
        val toMillis = end.plusDays(1).atStartOfDay(zoneId).toInstant().toEpochMilli() - 1
        return cacheDao.getBetween(fromMillis, toMillis)
    }

    private suspend fun enableAutoSyncIfNeeded() {
        val current = ensureState()
        if (!current.autoSyncEnabled) {
            syncStateDao.upsert(
                current.copy(
                    autoSyncEnabled = true,
                    syncStatus = STATUS_SYNCED,
                    lastErrorMessage = null
                )
            )
        }
    }

    private suspend fun shouldAutoSync(): Boolean {
        return tokenStore.hasToken() && (ensureState().autoSyncEnabled)
    }

    private suspend fun updateQueuedState() {
        val current = ensureState()
        syncStateDao.upsert(
            current.copy(
                syncStatus = if (tokenStore.hasToken()) STATUS_QUEUED else STATUS_READY,
                lastErrorMessage = null
            )
        )
    }

    private suspend fun updateState(
        syncStatus: String? = null,
        lastSyncedAtMillis: Long? = null,
        lastAttemptAtMillis: Long? = null,
        lastErrorMessage: String? = null
    ) {
        val current = ensureState()
        syncStateDao.upsert(
            current.copy(
                syncStatus = syncStatus ?: current.syncStatus,
                lastSyncedAtMillis = lastSyncedAtMillis ?: current.lastSyncedAtMillis,
                lastAttemptAtMillis = lastAttemptAtMillis ?: current.lastAttemptAtMillis,
                lastErrorMessage = lastErrorMessage,
                autoSyncEnabled = current.autoSyncEnabled,
                defaultWorkspaceId = current.defaultWorkspaceId
            )
        )
    }

    private suspend fun ensureState(): TogglSyncStateEntity {
        return syncStateDao.getState() ?: defaultState(tokenStore.hasToken()).also { syncStateDao.upsert(it) }
    }

    private fun defaultState(tokenConfigured: Boolean = false): TogglSyncStateEntity {
        return TogglSyncStateEntity(
            autoSyncEnabled = false,
            syncStatus = if (tokenConfigured) STATUS_READY else STATUS_UNCONFIGURED
        )
    }

    private suspend fun <T> withRateLimit(block: suspend () -> T): T {
        return networkSpacingMutex.withLock {
            val now = System.currentTimeMillis()
            val elapsed = now - lastNetworkCallAtMillis
            if (lastNetworkCallAtMillis > 0 && elapsed < NETWORK_MIN_INTERVAL_MS) {
                delay(NETWORK_MIN_INTERVAL_MS - elapsed)
            }
            val result = block()
            lastNetworkCallAtMillis = System.currentTimeMillis()
            result
        }
    }

    private fun parseLocalDate(value: String): LocalDate {
        return runCatching { LocalDate.parse(value, dateFormatter) }.getOrElse {
            LocalDate.parse(value)
        }
    }

    private fun TogglTimeEntry.toCacheEntity(): TogglTimeEntryCacheEntity? {
        val startMillis = runCatching {
            OffsetDateTime.parse(start, isoFormatter).toInstant().toEpochMilli()
        }.getOrElse {
            runCatching { Instant.parse(start).toEpochMilli() }.getOrNull() ?: return null
        }
        return TogglTimeEntryCacheEntity(
            remoteId = id,
            workspaceId = workspaceId,
            description = description,
            startMillis = startMillis,
            durationSeconds = duration,
            tagsCsv = tags.orEmpty().joinToString(",")
        )
    }

    private fun TogglTimeEntryCacheEntity.toApiModel(): TogglTimeEntry {
        val start = OffsetDateTime.ofInstant(Instant.ofEpochMilli(startMillis), zoneId).format(isoFormatter)
        return TogglTimeEntry(
            id = remoteId,
            workspaceId = workspaceId,
            description = description,
            start = start,
            stop = null,
            duration = durationSeconds,
            tags = tagsCsv.split(",").mapNotNull { it.trim().takeIf(String::isNotBlank) }
        )
    }

    companion object {
        private const val NETWORK_MIN_INTERVAL_MS = 1_000L

        const val STATUS_UNCONFIGURED = "UNCONFIGURED"
        const val STATUS_READY = "READY"
        const val STATUS_SYNCING = "SYNCING"
        const val STATUS_FAILED = "FAILED"
        const val STATUS_SYNCED = "SYNCED"
        const val STATUS_QUEUED = "QUEUED"
    }
}
