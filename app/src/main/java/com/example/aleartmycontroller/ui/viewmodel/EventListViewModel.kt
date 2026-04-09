package com.example.aleartmycontroller.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.aleartmycontroller.data.local.dao.RecordDao
import com.example.aleartmycontroller.data.local.entity.EventEntity
import com.example.aleartmycontroller.data.repository.EventRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.mapLatest
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

data class EventListUiState(
    val isLoading: Boolean = false,
    val errorMessage: String? = null
)

@HiltViewModel
class EventListViewModel @Inject constructor(
    private val eventRepository: EventRepository,
    private val recordDao: RecordDao
) : ViewModel() {

    private val _uiState = MutableStateFlow(EventListUiState())
    val uiState: StateFlow<EventListUiState> = _uiState.asStateFlow()

    /**
     * イベント一覧を監視し、それぞれの記録数（写真・メモ）を付加して UI 用モデルに変換する。
     */
    @OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)
    val events: StateFlow<List<com.example.aleartmycontroller.ui.model.EventWithCounts>> = eventRepository
        .observeUpcomingEvents()
        .mapLatest { eventList ->
            if (eventList.isEmpty()) return@mapLatest emptyList()

            // 集計データを一括取得
            val ids = eventList.map { it.eventId }
            val countsMap = recordDao.countByEvents(ids).associateBy { it.eventId }

            eventList.map { event ->
                val counts = countsMap[event.eventId]
                com.example.aleartmycontroller.ui.model.EventWithCounts(
                    event = event,
                    photoCount = counts?.photoCount ?: 0,
                    memoCount = counts?.memoCount ?: 0
                )
            }
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    init {
        syncCalendar()
    }

    fun syncCalendar() {
        viewModelScope.launch {
            _uiState.value = EventListUiState(isLoading = true)
            runCatching { eventRepository.syncFromCalendar() }
                .onFailure { e ->
                    _uiState.value = EventListUiState(
                        isLoading = false,
                        errorMessage = e.localizedMessage
                    )
                }
                .onSuccess {
                    _uiState.value = EventListUiState(isLoading = false)
                }
        }
    }

    fun dismissError() {
        _uiState.value = _uiState.value.copy(errorMessage = null)
    }
}
