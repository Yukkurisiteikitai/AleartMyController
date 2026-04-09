package com.example.aleartmycontroller.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.aleartmycontroller.data.local.entity.EventEntity
import com.example.aleartmycontroller.data.local.entity.MemoEntity
import com.example.aleartmycontroller.data.local.entity.PhotoEntity
import com.example.aleartmycontroller.data.local.entity.RecordEntity
import com.example.aleartmycontroller.data.repository.EventRepository
import com.example.aleartmycontroller.data.repository.RecordRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class RecordDashboardUiState(
    val currentEvent: EventEntity? = null,
    val observationRule: String = "",
    val nextCaptureLabel: String = "",
    val progress: Float = 0f,
    val recentRecords: List<RecordEntity> = emptyList(),
    val photosByRecord: Map<Long, List<PhotoEntity>> = emptyMap(),
    val memosByRecord: Map<Long, List<MemoEntity>> = emptyMap(),
    val isLoading: Boolean = false,
    val isTimerRunning: Boolean = false,
    val elapsedTimeText: String = "00:00:00",
    val currentObservationNote: String = ""
)

@HiltViewModel
class RecordDashboardViewModel @Inject constructor(
    private val eventRepository: EventRepository,
    private val recordRepository: RecordRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(RecordDashboardUiState())
    val uiState: StateFlow<RecordDashboardUiState> = _uiState.asStateFlow()

    init {
        observeCurrentEvent()
    }

    @OptIn(ExperimentalCoroutinesApi::class)
    private fun observeCurrentEvent() {
        viewModelScope.launch {
            eventRepository.observeOngoingEvent().collectLatest { event ->
                val now = System.currentTimeMillis()
                val rule = if (event != null) {
                    val durationMs = event.endTime - event.startTime
                    if (durationMs < 60 * 60 * 1000) "1時間未満: 終了時に証拠を記録"
                    else "1時間以上: 1時間ごとに証拠を記録"
                } else ""
                
                val progress = if (event != null) {
                    val durationMs = event.endTime - event.startTime
                    if (durationMs > 0) {
                        ((now - event.startTime).toFloat() / durationMs).coerceIn(0f, 1f)
                    } else 0f
                } else 0f

                _uiState.update { it.copy(
                    currentEvent = event,
                    observationRule = rule,
                    progress = progress
                ) }
            }
        }

        // 進行中イベントのレコードを監視 (N+1問題を回避したクエリを使用)
        viewModelScope.launch {
            eventRepository.observeOngoingEvent()
                .flatMapLatest { event ->
                    if (event != null) {
                        recordRepository.observeRecordsByEventWithAttachments(event.eventId)
                    } else {
                        flowOf(emptyList())
                    }
                }
                .collect { recordWithAttachments ->
                    _uiState.update { state ->
                        state.copy(
                            recentRecords = recordWithAttachments.map { it.record }.reversed(),
                            photosByRecord = recordWithAttachments.associate { it.record.recordId to it.photos },
                            memosByRecord = recordWithAttachments.associate { it.record.recordId to it.memos }
                        )
                    }
                }
        }
    }


    private var timerJob: kotlinx.coroutines.Job? = null
    private var startTimeMillis: Long = 0

    fun toggleTimer() {
        val newState = !_uiState.value.isTimerRunning
        _uiState.update { it.copy(isTimerRunning = newState) }
        
        if (newState) {
            startTimeMillis = System.currentTimeMillis()
            startTicker()
        } else {
            timerJob?.cancel()
            // タイマー停止時に経過時間をリセットし、もしノートがあればそれを保存する等の処理を検討可能
            _uiState.update { it.copy(elapsedTimeText = "00:00:00") }
        }
    }

    fun updateNote(newNote: String) {
        _uiState.update { it.copy(currentObservationNote = newNote) }
    }

    fun manualStartEvent(eventId: Long) {
        viewModelScope.launch {
            // Note: DBを監視しているため、eventIdを指定して開始しても
            // observeOngoingEvent() が更新を検知して自動的にUIが切り替わるはず
            val event = eventRepository.findById(eventId)
            if (event != null) {
                _uiState.update { it.copy(currentEvent = event, isTimerRunning = true) }
                startTimeMillis = System.currentTimeMillis()
                startTicker()
            }
        }
    }

    private fun startTicker() {
        timerJob?.cancel()
        timerJob = viewModelScope.launch {
            while (true) {
                val elapsed = System.currentTimeMillis() - startTimeMillis
                val hours = (elapsed / 3600000)
                val minutes = (elapsed % 3600000) / 60000
                val seconds = (elapsed % 60000) / 1000
                _uiState.update { 
                    it.copy(elapsedTimeText = String.format("%02d:%02d:%02d", hours, minutes, seconds))
                }
                kotlinx.coroutines.delay(1000)
            }
        }
    }
}
