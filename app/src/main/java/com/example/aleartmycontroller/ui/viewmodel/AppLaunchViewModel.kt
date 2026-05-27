package com.example.aleartmycontroller.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.aleartmycontroller.data.preferences.AppPreferences
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class AppLaunchViewModel @Inject constructor(
    private val prefs: AppPreferences
) : ViewModel() {

    val onboardingComplete: StateFlow<Boolean> = prefs.firstRunSetupComplete
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), false)

    fun setOnboardingComplete(completed: Boolean) {
        viewModelScope.launch {
            prefs.setFirstRunSetupComplete(completed)
        }
    }
}
