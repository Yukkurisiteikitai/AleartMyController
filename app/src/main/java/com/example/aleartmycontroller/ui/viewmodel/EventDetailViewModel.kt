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
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

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
        .observeRecordsByEvent(eventId)
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    private val _uiState = MutableStateFlow(EventDetailUiState())
    val uiState: StateFlow<EventDetailUiState> = _uiState.asStateFlow()

    init {
        loadEvent()
    }

    private fun loadEvent() {
        viewModelScope.launch {
            val event = eventRepository.findById(eventId)
            _uiState.value = _uiState.value.copy(event = event)
        }
    }

    fun loadAttachments(recordId: Long) {
        viewModelScope.launch {
            val photos = recordRepository.getPhotosForRecord(recordId)
            val memos = recordRepository.getMemosForRecord(recordId)
            _uiState.value = _uiState.value.copy(
                photosByRecord = _uiState.value.photosByRecord + (recordId to photos),
                memosByRecord  = _uiState.value.memosByRecord  + (recordId to memos)
            )
        }
    }
}
