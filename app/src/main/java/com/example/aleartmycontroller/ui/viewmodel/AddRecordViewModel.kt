package com.example.aleartmycontroller.ui.viewmodel

import android.content.Context
import android.media.MediaRecorder
import android.net.Uri
import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.aleartmycontroller.data.preferences.AppPreferences
import com.example.aleartmycontroller.data.repository.RecordRepository
import com.example.aleartmycontroller.data.repository.YourselfLmRepository
import com.example.aleartmycontroller.ui.util.AudioUtils
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import java.io.File
import javax.inject.Inject

sealed interface AddRecordUiState {
    data object Idle : AddRecordUiState
    data object Loading : AddRecordUiState
    data object Success : AddRecordUiState
    data class Error(val message: String) : AddRecordUiState
}

sealed interface RecordingState {
    data object Idle : RecordingState
    data class Recording(val durationSeconds: Int) : RecordingState
    data class Recorded(val filePath: String, val durationSeconds: Int) : RecordingState
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

    private val _recordingState = MutableStateFlow<RecordingState>(RecordingState.Idle)
    val recordingState: StateFlow<RecordingState> = _recordingState.asStateFlow()

    private var mediaRecorder: MediaRecorder? = null
    private var currentAudioFile: File? = null
    private var timerJob: Job? = null

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

    fun selectAudioFile(context: Context, uri: android.net.Uri) {
        viewModelScope.launch {
            runCatching { AudioUtils.copyToAppStorage(context, uri) }
                .onSuccess { file ->
                    currentAudioFile = file
                    _recordingState.value = RecordingState.Recorded(file.absolutePath, 0)
                }
                .onFailure {
                    _uiState.value = AddRecordUiState.Error(it.localizedMessage ?: "ファイルの読み込みに失敗しました")
                }
        }
    }

    fun startRecording(context: Context) {
        val file = AudioUtils.createAudioFile(context)
        currentAudioFile = file
        val recorder = AudioUtils.createRecorder(context)
        mediaRecorder = recorder
        runCatching {
            AudioUtils.startRecording(recorder, file.absolutePath)
            _recordingState.value = RecordingState.Recording(0)
            timerJob = viewModelScope.launch {
                var seconds = 0
                while (true) {
                    delay(1000)
                    seconds++
                    _recordingState.value = RecordingState.Recording(seconds)
                }
            }
        }.onFailure {
            mediaRecorder = null
            currentAudioFile = null
            _recordingState.value = RecordingState.Idle
        }
    }

    fun stopRecording() {
        timerJob?.cancel()
        timerJob = null
        val duration = (_recordingState.value as? RecordingState.Recording)?.durationSeconds ?: 0
        runCatching { mediaRecorder?.let { AudioUtils.stopRecording(it) } }
        mediaRecorder = null
        val path = currentAudioFile?.absolutePath
        if (path != null) {
            _recordingState.value = RecordingState.Recorded(path, duration)
        } else {
            _recordingState.value = RecordingState.Idle
        }
    }

    fun cancelRecording() {
        timerJob?.cancel()
        timerJob = null
        runCatching { mediaRecorder?.let { AudioUtils.stopRecording(it) } }
        mediaRecorder = null
        currentAudioFile?.delete()
        currentAudioFile = null
        _recordingState.value = RecordingState.Idle
    }

    fun saveAudioMemo() {
        val state = _recordingState.value as? RecordingState.Recorded ?: return
        viewModelScope.launch {
            _uiState.value = AddRecordUiState.Loading
            runCatching {
                val event = eventRepository.findById(eventId)
                    ?: error("Event not found: $eventId")
                val recordId = recordRepository.addAudioMemoRecord(event, state.filePath)
                runCatching { syncToYourselfLm(recordId) }
                logToToggl("VoiceMemo")
            }
                .onSuccess {
                    _recordingState.value = RecordingState.Idle
                    currentAudioFile = null
                    _uiState.value = AddRecordUiState.Success
                }
                .onFailure { _uiState.value = AddRecordUiState.Error(it.localizedMessage ?: "Unknown error") }
        }
    }

    fun resetState() {
        _uiState.value = AddRecordUiState.Idle
    }

    override fun onCleared() {
        super.onCleared()
        timerJob?.cancel()
        runCatching { mediaRecorder?.let { AudioUtils.stopRecording(it) } }
        mediaRecorder = null
    }
}
