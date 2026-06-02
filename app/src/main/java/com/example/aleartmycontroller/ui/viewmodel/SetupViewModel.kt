package com.example.aleartmycontroller.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.aleartmycontroller.data.preferences.AppPreferences
import com.example.aleartmycontroller.data.preferences.TogglTokenStore
import com.example.aleartmycontroller.data.repository.AuthRepository
import com.example.aleartmycontroller.data.repository.TogglRepository
import com.example.aleartmycontroller.data.repository.TogglSyncOutcome
import com.example.aleartmycontroller.data.repository.TogglSyncOutcome.Failure
import com.example.aleartmycontroller.data.repository.TogglSyncOutcome.NoPendingAction
import com.example.aleartmycontroller.data.repository.TogglSyncOutcome.NoToken
import com.example.aleartmycontroller.data.repository.TogglSyncOutcome.Success
import com.google.android.gms.auth.api.signin.GoogleSignInAccount
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

data class SetupUiState(
    val googleEmail: String? = null,
    val togglTokenConfigured: Boolean = false,
    val togglSyncStatus: String = "UNCONFIGURED",
    val togglPendingCount: Int = 0,
    val togglLastError: String? = null,
    val tokenInput: String = ""
)

@HiltViewModel
class SetupViewModel @Inject constructor(
    private val authRepository: AuthRepository,
    private val togglTokenStore: TogglTokenStore,
    private val togglRepository: TogglRepository,
    private val prefs: AppPreferences
) : ViewModel() {

    private val _googleEmail = MutableStateFlow(authRepository.getLastSignedInAccount()?.email)
    val googleEmail: StateFlow<String?> = _googleEmail.asStateFlow()

    val uiState: StateFlow<SetupUiState> = combine(
        togglRepository.observeSyncState(),
        togglRepository.observePendingCount(),
        googleEmail
    ) { syncState, pendingCount, email ->
        SetupUiState(
            googleEmail = email,
            togglTokenConfigured = togglTokenStore.hasToken(),
            togglSyncStatus = syncState.syncStatus,
            togglPendingCount = pendingCount,
            togglLastError = syncState.lastErrorMessage
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), SetupUiState())

    fun refreshGoogleState() {
        _googleEmail.value = authRepository.getLastSignedInAccount()?.email
    }

    fun handleSignIn(account: GoogleSignInAccount) {
        _googleEmail.value = account.email
        viewModelScope.launch { authRepository.signInWithSupabase(account) }
    }

    fun updateTokenInput(value: String) {
        _tokenInput = value
    }

    private var _tokenInput: String = ""
        set(value) {
            field = value
        }

    fun currentTokenInput(): String = _tokenInput

    fun saveToken(token: String) {
        viewModelScope.launch {
            togglRepository.saveToken(token)
            _tokenInput = ""
        }
    }

    fun clearToken() {
        viewModelScope.launch {
            togglRepository.clearToken()
        }
    }

    fun startInitialSync(onResult: (TogglSyncOutcome) -> Unit) {
        viewModelScope.launch {
            val result = togglRepository.startInitialSync()
            onResult(result)
        }
    }

    fun markSetupComplete() {
        viewModelScope.launch {
            prefs.setFirstRunSetupComplete(true)
        }
    }

    fun skipSetup() {
        markSetupComplete()
    }
}
