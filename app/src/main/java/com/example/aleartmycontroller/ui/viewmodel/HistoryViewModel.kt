package com.example.aleartmycontroller.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.aleartmycontroller.data.local.entity.MemoEntity
import com.example.aleartmycontroller.data.local.entity.PhotoEntity
import com.example.aleartmycontroller.data.local.entity.RecordEntity
import com.example.aleartmycontroller.data.repository.RecordRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

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
        .observeAllRecords()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    private val _uiState = MutableStateFlow(HistoryUiState())
    val uiState: StateFlow<HistoryUiState> = _uiState.asStateFlow()

    fun toggleView() {
        _uiState.value = _uiState.value.copy(isRecordView = !_uiState.value.isRecordView)
    }

    fun loadAttachments(recordId: Long) {
        viewModelScope.launch {
            if (_uiState.value.photosByRecord.containsKey(recordId)) return@launch
            
            val photos = recordRepository.getPhotosForRecord(recordId)
            val memos = recordRepository.getMemosForRecord(recordId)
            _uiState.value = _uiState.value.copy(
                photosByRecord = _uiState.value.photosByRecord + (recordId to photos),
                memosByRecord  = _uiState.value.memosByRecord  + (recordId to memos)
            )
        }
    }
}
