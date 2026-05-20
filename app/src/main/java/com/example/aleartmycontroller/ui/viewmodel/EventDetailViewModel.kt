package com.example.aleartmycontroller.ui.viewmodel

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.aleartmycontroller.data.local.entity.EventEntity
import com.example.aleartmycontroller.data.repository.EventRepository
import com.example.aleartmycontroller.data.repository.RecordRepository
import com.example.aleartmycontroller.ui.model.DomainRecord
import com.example.aleartmycontroller.ui.model.toDomainModel
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

/** イベント詳細画面のUI状態 */
data class EventDetailUiState(
    val event: EventEntity? = null
)

@HiltViewModel
class EventDetailViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val eventRepository: EventRepository,
    private val recordRepository: RecordRepository
) : ViewModel() {

    private val eventId: Long = checkNotNull(savedStateHandle["eventId"])

    val records: StateFlow<List<DomainRecord>> = recordRepository
        .observeRecordsByEventWithAttachments(eventId)
        .map { list -> list.map { it.toDomainModel() } }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    private val _uiState = MutableStateFlow(EventDetailUiState())
    val uiState: StateFlow<EventDetailUiState> = _uiState.asStateFlow()

    init {
        loadEvent()
    }

    private fun loadEvent() {
        viewModelScope.launch {
            val event = eventRepository.findById(eventId)
            _uiState.update { it.copy(event = event) }
        }
    }
}
