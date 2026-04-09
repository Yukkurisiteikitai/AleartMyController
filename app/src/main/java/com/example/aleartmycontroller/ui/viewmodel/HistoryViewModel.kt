package com.example.aleartmycontroller.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.aleartmycontroller.data.local.entity.MemoEntity
import com.example.aleartmycontroller.data.local.entity.PhotoEntity
import com.example.aleartmycontroller.data.local.entity.RecordEntity
import com.example.aleartmycontroller.data.repository.RecordRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

data class HistoryUiState(
    val photosByRecord: Map<Long, List<PhotoEntity>> = emptyMap(),
    val memosByRecord: Map<Long, List<MemoEntity>> = emptyMap(),
    val isRecordView: Boolean = false
)

@HiltViewModel
class HistoryViewModel @Inject constructor(
    private val recordRepository: RecordRepository
) : ViewModel() {

    val allRecords: StateFlow<List<RecordEntity>> = recordRepository
        .observeAllRecordsWithAttachments()
        .map { list -> list.map { it.record } }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    private val _uiState = MutableStateFlow(HistoryUiState())
    val uiState: StateFlow<HistoryUiState> = _uiState.asStateFlow()

    fun toggleView() {
        _uiState.value = _uiState.value.copy(isRecordView = !_uiState.value.isRecordView)
    }

    init {
        observeAttachments()
    }

    private fun observeAttachments() {
        viewModelScope.launch {
            recordRepository.observeAllRecordsWithAttachments().collectLatest { list ->
                val photos = list.associate { it.record.recordId to it.photos }
                val memos = list.associate { it.record.recordId to it.memos }
                _uiState.update { it.copy(photosByRecord = photos, memosByRecord = memos) }
            }
        }
    }
}
