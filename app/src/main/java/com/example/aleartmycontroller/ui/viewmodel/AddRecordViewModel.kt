package com.example.aleartmycontroller.ui.viewmodel

import android.content.Context
import android.net.Uri
import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.aleartmycontroller.data.amc.AmcAttachmentType
import com.example.aleartmycontroller.data.local.entity.isLocalDraft
import com.example.aleartmycontroller.data.repository.AmcDraftRepository
import com.example.aleartmycontroller.data.repository.AuthRepository
import com.example.aleartmycontroller.data.repository.RecordRepository
import com.example.aleartmycontroller.ui.util.CameraUtils
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

sealed interface AddRecordUiState {
    data object Idle : AddRecordUiState
    data object Loading : AddRecordUiState
    data object Success : AddRecordUiState
    data class Error(val message: String) : AddRecordUiState
}

sealed interface AddRecordUiEvent {
    data class ShowWarning(val message: String) : AddRecordUiEvent
}

@HiltViewModel
class AddRecordViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    @ApplicationContext private val context: Context,
    private val recordRepository: RecordRepository,
    private val eventRepository: com.example.aleartmycontroller.data.repository.EventRepository,
    private val togglRepository: com.example.aleartmycontroller.data.repository.TogglRepository,
    private val amcDraftRepository: AmcDraftRepository,
    private val authRepository: AuthRepository
) : ViewModel() {

    private val eventId: Long = checkNotNull(savedStateHandle["eventId"])

    private val _uiState = MutableStateFlow<AddRecordUiState>(AddRecordUiState.Idle)
    val uiState: StateFlow<AddRecordUiState> = _uiState.asStateFlow()
    private val _uiEvent = Channel<AddRecordUiEvent>(Channel.BUFFERED)
    val uiEvent = _uiEvent.receiveAsFlow()

    private suspend fun logToToggl(tag: String) {
        val event = eventRepository.findById(eventId) ?: return
        runCatching {
            togglRepository.queueCreateEntry(
                description = event.title,
                tags = listOf(tag, "Observation")
            )
        }
    }

    fun addPhoto(uri: Uri) {
        viewModelScope.launch {
            _uiState.value = AddRecordUiState.Loading
            runCatching {
                val event = eventRepository.findById(eventId)
                    ?: error("Event not found: $eventId")
                val jpegFile = withContext(Dispatchers.IO) {
                    CameraUtils.compressToJpeg(context, uri)
                }
                val jpegUri = Uri.fromFile(jpegFile)
                recordRepository.addPhotoRecord(event, jpegUri.toString())
                logToToggl("Photo")

                val userId = authRepository.currentSupabaseUserId()
                val draftId = amcDraftRepository.getOrCreateDraftForEvent(eventId, userId)
                amcDraftRepository.queueAttachment(
                    draftRecordId = draftId,
                    type = AmcAttachmentType.IMAGE,
                    localUri = jpegUri.toString(),
                    mimeType = "image/jpeg",
                    sizeBytes = jpegFile.length()
                )
            }
                .onSuccess { _uiState.value = AddRecordUiState.Success }
                .onFailure { _uiState.value = AddRecordUiState.Error(it.localizedMessage ?: "Unknown error") }
        }
    }

    fun addMemo(text: String, isVoice: Boolean = false) {
        if (text.isBlank()) return
        viewModelScope.launch {
            _uiState.value = AddRecordUiState.Loading
            val event = eventRepository.findById(eventId)
                ?: run {
                    _uiState.value = AddRecordUiState.Error("Event not found: $eventId")
                    return@launch
                }

            runCatching {
                recordRepository.addMemoRecord(event, text, isVoice)
                logToToggl(if (isVoice) "VoiceMemo" else "TextMemo")

                val userId = authRepository.currentSupabaseUserId()
                val draftId = amcDraftRepository.getOrCreateDraftForEvent(eventId, userId)
                amcDraftRepository.appendRevision(draftId, text, userId)
            }
                .onSuccess {
                    if (!isVoice && !event.isLocalDraft()) {
                        runCatching {
                            eventRepository.appendMemoToGoogleEvent(event, text)
                        }.onFailure {
                            _uiEvent.send(
                                AddRecordUiEvent.ShowWarning(
                                    "Google カレンダーへのメモ追記に失敗しました"
                                )
                            )
                        }
                    }
                    _uiState.value = AddRecordUiState.Success
                }
                .onFailure { _uiState.value = AddRecordUiState.Error(it.localizedMessage ?: "Unknown error") }
        }
    }

    fun resetState() {
        _uiState.value = AddRecordUiState.Idle
    }
}
