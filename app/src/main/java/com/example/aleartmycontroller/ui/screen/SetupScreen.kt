package com.example.aleartmycontroller.ui.screen

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.aleartmycontroller.data.repository.TogglSyncOutcome
import com.example.aleartmycontroller.ui.viewmodel.SetupViewModel
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.common.api.Scope
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SetupScreen(
    onSkip: () -> Unit,
    onFinished: () -> Unit,
    onBack: (() -> Unit)? = null,
    viewModel: SetupViewModel = hiltViewModel()
) {
    val context = LocalContext.current
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()
    var tokenInput by remember { mutableStateOf("") }
    var showSuccessDialog by remember { mutableStateOf(false) }

    val launcher = rememberLauncherForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) {
        viewModel.refreshGoogleState()
    }

    if (showSuccessDialog) {
        AlertDialog(
            onDismissRequest = { showSuccessDialog = false },
            title = { Text("初回同期が完了しました") },
            text = { Text("Toggl の連携と同期準備が整いました。") },
            confirmButton = {
                TextButton(onClick = {
                    showSuccessDialog = false
                    onFinished()
                }) { Text("続ける") }
            }
        )
    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text("初回セットアップ", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    if (onBack != null) {
                        IconButton(onClick = onBack) {
                            Icon(Icons.Default.ArrowBack, contentDescription = "戻る")
                        }
                    }
                },
                actions = {
                    TextButton(onClick = {
                        viewModel.skipSetup()
                        onSkip()
                    }) {
                        Text("スキップ")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 16.dp)
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("1. Google カレンダー連携", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                    Text(
                        text = uiState.googleEmail ?: "未連携です。まず Google ログインを行ってください。",
                        style = MaterialTheme.typography.bodyMedium
                    )
                    Button(onClick = {
                        val gso = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
                            .requestEmail()
                            .requestScopes(Scope("https://www.googleapis.com/auth/calendar.events"))
                            .build()
                        val client = GoogleSignIn.getClient(context, gso)
                        launcher.launch(client.signInIntent)
                    }) {
                        Text(if (uiState.googleEmail == null) "Google ログイン" else "Google 連携を更新")
                    }
                }
            }

            Card(modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("2. Toggl token", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                    Text(
                        text = if (uiState.googleEmail != null) {
                            if (uiState.togglTokenConfigured) "Token は設定済みです。" else "Google 連携後に token を設定してください。"
                        } else {
                            "Google 連携の後に設定してください。"
                        }
                    )
                    OutlinedTextField(
                        value = tokenInput,
                        onValueChange = { tokenInput = it },
                        enabled = uiState.googleEmail != null,
                        label = { Text("Toggl API token") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true
                    )
                    Button(
                        onClick = {
                            if (tokenInput.isNotBlank()) {
                                viewModel.saveToken(tokenInput)
                                tokenInput = ""
                            }
                        },
                        enabled = uiState.googleEmail != null && tokenInput.isNotBlank()
                    ) {
                        Text("Token を保存")
                    }
                    if (uiState.togglTokenConfigured) {
                        Text("同期状態: ${uiState.togglSyncStatus}")
                    }
                    if (!uiState.togglLastError.isNullOrBlank()) {
                        Text(
                            text = "前回エラー: ${uiState.togglLastError}",
                            color = MaterialTheme.colorScheme.error
                        )
                    }
                }
            }

            Card(modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("3. 初回同期", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                    Text("未送信キュー: ${uiState.togglPendingCount} 件")
                    Button(
                        onClick = {
                            viewModel.startInitialSync { outcome ->
                                when (outcome) {
                                    is TogglSyncOutcome.Success, is TogglSyncOutcome.NoPendingAction -> {
                                        scope.launch { snackbarHostState.showSnackbar("初回同期が完了しました") }
                                        showSuccessDialog = true
                                    }
                                    is TogglSyncOutcome.NoToken -> {
                                        scope.launch { snackbarHostState.showSnackbar("Toggl token が未設定です") }
                                    }
                                    is TogglSyncOutcome.Failure -> {
                                        scope.launch { snackbarHostState.showSnackbar(outcome.message) }
                                    }
                                }
                            }
                        },
                        enabled = uiState.togglTokenConfigured
                    ) {
                        Text("同期を開始")
                    }
                }
            }

            HorizontalDivider()

            Text(
                text = "この画面はスキップできます。後から設定画面で再表示できます。",
                style = MaterialTheme.typography.bodySmall
            )
            Spacer(modifier = Modifier.height(12.dp))
        }
    }
}
