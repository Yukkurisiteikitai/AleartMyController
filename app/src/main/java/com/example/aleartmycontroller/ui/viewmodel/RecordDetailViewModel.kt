package com.example.aleartmycontroller.ui.viewmodel

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.aleartmycontroller.data.local.entity.MemoEntity
import com.example.aleartmycontroller.data.local.entity.ObservationEventEntity
import com.example.aleartmycontroller.data.local.entity.PhotoEntity
import com.example.aleartmycontroller.data.local.entity.RecordEntity
import com.example.aleartmycontroller.data.repository.ObservationEventRepository
import com.example.aleartmycontroller.data.repository.RecordRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class RecordDetailUiState(
    val record: RecordEntity? = null,
    val event: ObservationEventEntity? = null,
    val photos: List<PhotoEntity> = emptyList(),
    val memos: List<MemoEntity> = emptyList(),
    val isLoading: Boolean = false,
    val isDeleted: Boolean = false,
    val errorMessage: String? = null
)

@HiltViewModel
class RecordDetailViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val recordRepository: RecordRepository,
    private val observationEventRepository: ObservationEventRepository
) : ViewModel() {

    private val recordId: Long = checkNotNull(savedStateHandle["recordId"])

    private val _uiState = MutableStateFlow(RecordDetailUiState(isLoading = true))
    val uiState: StateFlow<RecordDetailUiState> = _uiState.asStateFlow()

    init {
        loadRecordDetails()
    }

    private fun loadRecordDetails() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true)
            runCatching {
                val record = recordRepository.findRecordById(recordId)
                    ?: throw IllegalArgumentException("レコードが見つかりません")
                val event = observationEventRepository.findById(record.obsEventId)
                val photos = recordRepository.getPhotosForRecord(recordId)
                val memos = recordRepository.getMemosForRecord(recordId)

                _uiState.value = _uiState.value.copy(
                    record = record,
                    event = event,
                    photos = photos,
                    memos = memos,
                    isLoading = false
                )
            }.onFailure { e ->
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    errorMessage = e.localizedMessage ?: "詳細の読み込みに失敗しました"
                )
            }
        }
    }

    fun deleteRecord() {
        val record = _uiState.value.record ?: return
        viewModelScope.launch {
            runCatching {
                recordRepository.deleteRecord(record)
            }.onSuccess {
                _uiState.value = _uiState.value.copy(isDeleted = true)
            }.onFailure { e ->
                _uiState.value = _uiState.value.copy(
                    errorMessage = e.localizedMessage ?: "削除に失敗しました"
                )
            }
        }
    }

    fun dismissError() {
        _uiState.value = _uiState.value.copy(errorMessage = null)
    }
}
