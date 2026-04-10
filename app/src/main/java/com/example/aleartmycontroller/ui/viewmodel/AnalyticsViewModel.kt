package com.example.aleartmycontroller.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.aleartmycontroller.data.local.dao.DailyRecordCount
import com.example.aleartmycontroller.data.local.dao.EventRecordCount
import com.example.aleartmycontroller.data.local.dao.RecordTypeCount
import com.example.aleartmycontroller.data.repository.AnalyticsRepository
import com.example.aleartmycontroller.data.repository.AnalyticsSummary
import com.example.aleartmycontroller.data.repository.TogglDailyDuration
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

enum class AnalyticsPeriod(val days: Int) {
    WEEK(7),
    MONTH(30)
}

data class AnalyticsUiState(
    val period: AnalyticsPeriod = AnalyticsPeriod.WEEK,
    val isLoading: Boolean = false,
    val summary: AnalyticsSummary = AnalyticsSummary(0, 0, 0),
    val dailyCounts: List<DailyRecordCount> = emptyList(),
    val typeBreakdown: List<RecordTypeCount> = emptyList(),
    val topEvents: List<EventRecordCount> = emptyList(),
    val togglDaily: List<TogglDailyDuration> = emptyList(),
    val errorMessage: String? = null
)

@HiltViewModel
class AnalyticsViewModel @Inject constructor(
    private val analyticsRepository: AnalyticsRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(AnalyticsUiState())
    val uiState: StateFlow<AnalyticsUiState> = _uiState.asStateFlow()

    init {
        refresh()
    }

    fun setPeriod(period: AnalyticsPeriod) {
        _uiState.update { it.copy(period = period) }
        refresh()
    }

    private fun refresh() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, errorMessage = null) }
            val fromMillis = System.currentTimeMillis() -
                _uiState.value.period.days * 24L * 60 * 60 * 1000
            runCatching {
                val summary = analyticsRepository.getSummary(fromMillis)
                val daily = analyticsRepository.getDailyRecordCounts(fromMillis)
                val breakdown = analyticsRepository.getRecordTypeBreakdown(fromMillis)
                val topEvents = analyticsRepository.getTopEvents(fromMillis)
                val togglDaily = analyticsRepository.getTogglDailyDurations(fromMillis)
                _uiState.update { state ->
                    state.copy(
                        isLoading = false,
                        summary = summary,
                        dailyCounts = daily,
                        typeBreakdown = breakdown,
                        topEvents = topEvents,
                        togglDaily = togglDaily
                    )
                }
            }.onFailure { e ->
                _uiState.update { it.copy(isLoading = false, errorMessage = e.message) }
            }
        }
    }
}
