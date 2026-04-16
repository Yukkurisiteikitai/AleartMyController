package com.example.aleartmycontroller.ui.viewmodel

import android.net.Uri
import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.aleartmycontroller.data.preferences.AppPreferences
import com.example.aleartmycontroller.data.repository.RecordRepository
import com.example.aleartmycontroller.data.repository.YourselfLmRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import javax.inject.Inject

sealed interface AddRecordUiState {
    data object Idle : AddRecordUiState
    data object Loading : AddRecordUiState
    data object Success : AddRecordUiState
    data class Error(val message: String) : AddRecordUiState
}

@HiltViewModel
class AddRecordViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val recordRepository: RecordRepository,
    private val eventRepository: com.example.aleartmycontroller.data.repository.EventRepository,
    private val togglRepository: com.example.aleartmycontroller.data.repository.TogglRepository,
    private val yourselfLmRepository: YourselfLmRepository,
    private val prefs: AppPreferences
) : ViewModel() {

    private val eventId: Long = checkNotNull(savedStateHandle["eventId"])

    private val _uiState = MutableStateFlow<AddRecordUiState>(AddRecordUiState.Idle)
    val uiState: StateFlow<AddRecordUiState> = _uiState.asStateFlow()

    private suspend fun logToToggl(tag: String) {
        val event = eventRepository.findById(eventId) ?: return
        togglRepository.createEntry(
            description = event.title,
            tags = listOf(tag, "Observation")
        )
    }

    private suspend fun syncToYourselfLm(recordId: Long) {
        if (!prefs.yourselfLmSyncEnabled.first()) return

        val event = eventRepository.findById(eventId) ?: return
        val record = recordRepository.findRecordById(recordId) ?: return
        val photos = recordRepository.getPhotosForRecord(recordId)
        val memos = recordRepository.getMemosForRecord(recordId)
        yourselfLmRepository.submitRecord(
            event = event,
            record = record,
            photos = photos,
            memos = memos
        )
    }

    fun addPhoto(uri: Uri) {
        viewModelScope.launch {
            _uiState.value = AddRecordUiState.Loading
            runCatching {
                val event = eventRepository.findById(eventId)
                    ?: error("Event not found: $eventId")
                val recordId = recordRepository.addPhotoRecord(event, uri.toString())
                runCatching { syncToYourselfLm(recordId) }
                logToToggl("Photo")
            }
                .onSuccess { _uiState.value = AddRecordUiState.Success }
                .onFailure { _uiState.value = AddRecordUiState.Error(it.localizedMessage ?: "Unknown error") }
        }
    }

    fun addMemo(text: String, isVoice: Boolean = false) {
        if (text.isBlank()) return
        viewModelScope.launch {
            _uiState.value = AddRecordUiState.Loading
            runCatching {
                val event = eventRepository.findById(eventId)
                    ?: error("Event not found: $eventId")
                val recordId = recordRepository.addMemoRecord(event, text, isVoice)
                runCatching { syncToYourselfLm(recordId) }
                logToToggl(if (isVoice) "VoiceMemo" else "TextMemo")
            }
                .onSuccess { _uiState.value = AddRecordUiState.Success }
                .onFailure { _uiState.value = AddRecordUiState.Error(it.localizedMessage ?: "Unknown error") }
        }
    }

    fun resetState() {
        _uiState.value = AddRecordUiState.Idle
    }
}
