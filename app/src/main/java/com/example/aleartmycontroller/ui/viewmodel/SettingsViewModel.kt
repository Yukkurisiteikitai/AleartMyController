package com.example.aleartmycontroller.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.aleartmycontroller.data.preferences.AppPreferences
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

/** 仕様書 §5, §6: プリセット一覧 (分, 0 = カスタム) */
val PRESET_OPTIONS: List<Int> = listOf(1, 3, 5, 10, 25, 30, 60, 0)

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val prefs: AppPreferences,
    private val authRepository: com.example.aleartmycontroller.data.repository.AuthRepository
) : ViewModel() {

    private val _userEmail = kotlinx.coroutines.flow.MutableStateFlow<String?>(null)
    val userEmail: StateFlow<String?> = _userEmail.asStateFlow()

    init {
        updateUserInfo()
    }

    fun updateUserInfo() {
        _userEmail.value = authRepository.getLastSignedInAccount()?.email
    }

    val intervalMinutes: StateFlow<Int> = prefs.intervalMinutes
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), 60)

    val presetOrder: StateFlow<List<Int>> = prefs.presetOrder
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), PRESET_OPTIONS)

    val notificationsEnabled: StateFlow<Boolean> = prefs.notificationsEnabled
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), true)

    val customIntervalMinutes: StateFlow<Int> = prefs.customIntervalMinutes
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), 30)

    val yourselfLmSyncEnabled: StateFlow<Boolean> = prefs.yourselfLmSyncEnabled
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), false)

    fun selectInterval(minutes: Int) {
        viewModelScope.launch { prefs.setIntervalMinutes(minutes) }
    }

    fun setPresetOrder(order: List<Int>) {
        viewModelScope.launch { prefs.setPresetOrder(order) }
    }

    fun toggleNotifications(enabled: Boolean) {
        viewModelScope.launch { prefs.setNotificationsEnabled(enabled) }
    }

    fun setCustomInterval(minutes: Int) {
        viewModelScope.launch {
            prefs.setCustomIntervalMinutes(minutes)
            prefs.setIntervalMinutes(minutes)
        }
    }

    fun toggleYourselfLmSync(enabled: Boolean) {
        viewModelScope.launch { prefs.setYourselfLmSyncEnabled(enabled) }
    }
}
