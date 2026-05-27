package com.example.aleartmycontroller.ui.screen

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.aleartmycontroller.ui.viewmodel.PRESET_OPTIONS
import com.example.aleartmycontroller.ui.viewmodel.SettingsViewModel

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.common.api.Scope
import androidx.compose.ui.platform.LocalContext

import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.Icons
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    onBack: () -> Unit,
    onOpenSetup: () -> Unit,
    viewModel: SettingsViewModel = hiltViewModel()
) {
    val context = LocalContext.current
    val selectedInterval by viewModel.intervalMinutes.collectAsStateWithLifecycle()
    val notificationsEnabled by viewModel.notificationsEnabled.collectAsStateWithLifecycle()
    val customInterval by viewModel.customIntervalMinutes.collectAsStateWithLifecycle()
    val userEmail by viewModel.userEmail.collectAsStateWithLifecycle()
    val amcQueueSummary by viewModel.amcQueueSummary.collectAsStateWithLifecycle()
    var showCustomDialog by remember { mutableStateOf(false) }

    // Google Sign-In Launcher
    val googleSignInLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) {
        viewModel.updateUserInfo()
    }

    if (showCustomDialog) {
        CustomIntervalDialog(
            initialValue = customInterval,
            onConfirm = { minutes ->
                viewModel.setCustomInterval(minutes)
                showCustomDialog = false
            },
            onDismiss = { showCustomDialog = false }
        )
    }

    Scaffold(
        topBar = { 
            TopAppBar(
                title = { Text("設定", fontWeight = androidx.compose.ui.text.font.FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "戻る")
                    }
                }
            ) 
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
            contentPadding = PaddingValues(vertical = 8.dp)
        ) {
            // ---- アカウント連携 ----
            item {
                Text(
                    "アカウント連携",
                    style = MaterialTheme.typography.titleSmall,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                )
            }
            item {
                ListItem(
                    headlineContent = { Text(userEmail ?: "Google未連携") },
                    supportingContent = { Text("カレンダー同期にはログインが必要です") },
                    trailingContent = {
                        Button(onClick = {
                            val gso = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
                                .requestEmail()
                                .requestScopes(Scope("https://www.googleapis.com/auth/calendar.events"))
                                .build()
                            val client = GoogleSignIn.getClient(context, gso)
                            googleSignInLauncher.launch(client.signInIntent)
                        }) {
                            Text(if (userEmail == null) "ログイン" else "変更")
                        }
                    }
                )
            }

            item { HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp)) }

            item {
                // ---- 撮影インターバル ----
                Text(
                    "撮影インターバル",
                    style = MaterialTheme.typography.titleSmall,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                )
            }
            item {
                PresetGrid(
                    presets = PRESET_OPTIONS,
                    selectedMinutes = selectedInterval,
                    onPresetSelected = { minutes ->
                        if (minutes == 0) showCustomDialog = true
                        else viewModel.selectInterval(minutes)
                    }
                )
            }

            item { HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp)) }

            item {
                ListItem(
                    headlineContent = { Text("初回セットアップ") },
                    supportingContent = { Text("Google 連携と Toggl token を順番に再設定できます") },
                    trailingContent = {
                        Button(onClick = onOpenSetup) {
                            Text("開く")
                        }
                    }
                )
            }

            item { HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp)) }

            // ---- AMC 状態 ----
            item {
                Text(
                    "AMC",
                    style = MaterialTheme.typography.titleSmall,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                )
            }
            item {
                ListItem(
                    headlineContent = { Text("ローカルキュー") },
                    supportingContent = { Text(amcQueueSummary) }
                )
            }

            item { HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp)) }

            // ---- 通知設定 ----
            item {
                ListItem(
                    headlineContent = { Text("通知を有効にする") },
                    trailingContent = {
                        Switch(
                            checked = notificationsEnabled,
                            onCheckedChange = viewModel::toggleNotifications
                        )
                    }
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun PresetGrid(
    presets: List<Int>,
    selectedMinutes: Int,
    onPresetSelected: (Int) -> Unit
) {
    // 2列グリッド風にChipを並べる
    Column(
        modifier = Modifier.padding(horizontal = 12.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        presets.chunked(3).forEach { row ->
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                row.forEach { minutes ->
                    val label = if (minutes == 0) "カスタム" else intervalLabel(minutes)
                    val selected = selectedMinutes == minutes ||
                            (minutes == 0 && presets.none { it == selectedMinutes && it != 0 })
                    FilterChip(
                        selected = selectedMinutes == minutes,
                        onClick = { onPresetSelected(minutes) },
                        label = { Text(label) },
                        modifier = Modifier.weight(1f)
                    )
                }
                // 行の端が空の場合は Spacer で埋める
                repeat(3 - row.size) {
                    Spacer(modifier = Modifier.weight(1f))
                }
            }
        }
    }
}

private fun intervalLabel(minutes: Int): String = when {
    minutes >= 60 -> "${minutes / 60}時間"
    else -> "${minutes}分"
}

@Composable
private fun CustomIntervalDialog(
    initialValue: Int,
    onConfirm: (Int) -> Unit,
    onDismiss: () -> Unit
) {
    var sliderValue by remember { mutableFloatStateOf(initialValue.toFloat().coerceIn(1f, 120f)) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("カスタムインターバル") },
        text = {
            Column {
                Text("${sliderValue.toInt()} 分", style = MaterialTheme.typography.headlineMedium)
                Spacer(Modifier.height(8.dp))
                Slider(
                    value = sliderValue,
                    onValueChange = { sliderValue = it },
                    valueRange = 1f..120f,
                    steps = 118
                )
            }
        },
        confirmButton = {
            TextButton(onClick = { onConfirm(sliderValue.toInt()) }) { Text("設定") }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("キャンセル") }
        }
    )
}
