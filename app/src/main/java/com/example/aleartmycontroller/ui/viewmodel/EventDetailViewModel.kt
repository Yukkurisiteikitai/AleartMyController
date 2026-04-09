package com.example.aleartmycontroller.ui.viewmodel

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.aleartmycontroller.data.local.entity.EventEntity
import com.example.aleartmycontroller.data.local.entity.MemoEntity
import com.example.aleartmycontroller.data.local.entity.PhotoEntity
import com.example.aleartmycontroller.data.local.entity.RecordEntity
import com.example.aleartmycontroller.data.repository.EventRepository
import com.example.aleartmycontroller.data.repository.RecordRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

/** イベント詳細画面のUI状態 */
data class EventDetailUiState(
    val event: EventEntity? = null,
    val photosByRecord: Map<Long, List<PhotoEntity>> = emptyMap(),
    val memosByRecord: Map<Long, List<MemoEntity>> = emptyMap()
)

@HiltViewModel
class EventDetailViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val eventRepository: EventRepository,
    private val recordRepository: RecordRepository
) : ViewModel() {

    private val eventId: Long = checkNotNull(savedStateHandle["eventId"])

    val records: StateFlow<List<RecordEntity>> = recordRepository
        .observeRecordsByEventWithAttachments(eventId)
        .map { list -> list.map { it.record } }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    private val _uiState = MutableStateFlow(EventDetailUiState())
    val uiState: StateFlow<EventDetailUiState> = _uiState.asStateFlow()

    init {
        loadEvent()
        observeAttachments()
    }

    private fun loadEvent() {
        viewModelScope.launch {
            val event = eventRepository.findById(eventId)
            _uiState.update { it.copy(event = event) }
        }
    }

    private fun observeAttachments() {
        viewModelScope.launch {
            recordRepository.observeRecordsByEventWithAttachments(eventId).collectLatest { list ->
                val photos = list.associate { it.record.recordId to it.photos }
                val memos = list.associate { it.record.recordId to it.memos }
                _uiState.update { it.copy(photosByRecord = photos, memosByRecord = memos) }
            }
        }
    }
}
