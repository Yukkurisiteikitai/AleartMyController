package com.example.aleartmycontroller.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.aleartmycontroller.data.local.entity.MemoEntity
import com.example.aleartmycontroller.data.local.entity.PhotoEntity
import com.example.aleartmycontroller.data.local.entity.RecordEntity
import com.example.aleartmycontroller.data.repository.RecordRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import com.example.aleartmycontroller.ui.model.DomainRecord
import com.example.aleartmycontroller.ui.model.toDomainModel
import kotlinx.coroutines.flow.*

data class HistoryUiState(
    val isRecordView: Boolean = false
)

@HiltViewModel
class HistoryViewModel @Inject constructor(
    private val recordRepository: RecordRepository
) : ViewModel() {

    val allRecords: StateFlow<List<DomainRecord>> = recordRepository
        .observeAllRecordsWithAttachments()
        .map { list -> list.map { it.toDomainModel() } }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    private val _uiState = MutableStateFlow(HistoryUiState())
    val uiState: StateFlow<HistoryUiState> = _uiState.asStateFlow()

    fun toggleView() {
        _uiState.value = _uiState.value.copy(isRecordView = !_uiState.value.isRecordView)
    }
}
