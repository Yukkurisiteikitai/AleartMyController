package com.example.aleartmycontroller.ui.screen

import android.Manifest
import android.content.Intent
import android.net.Uri
import android.speech.RecognizerIntent
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.AudioFile
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.Notes
import androidx.compose.material.icons.filled.Send
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material3.*
import androidx.compose.material3.surfaceColorAtElevation
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.isGranted
import com.google.accompanist.permissions.rememberPermissionState
import com.example.aleartmycontroller.ui.viewmodel.AddRecordUiState
import com.example.aleartmycontroller.ui.viewmodel.AddRecordViewModel
import com.example.aleartmycontroller.ui.viewmodel.RecordingState
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class, ExperimentalPermissionsApi::class)
@Composable
fun AddRecordScreen(
    onBack: () -> Unit,
    viewModel: AddRecordViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val recordingState by viewModel.recordingState.collectAsStateWithLifecycle()
    var memoText by remember { mutableStateOf("") }

    LaunchedEffect(uiState) {
        if (uiState is AddRecordUiState.Success) {
            viewModel.resetState()
            onBack()
        }
    }

    val cameraPermission = rememberPermissionState(Manifest.permission.CAMERA)
    val audioPermission = rememberPermissionState(Manifest.permission.RECORD_AUDIO)
    val context = LocalContext.current

    var tempPhotoUri by remember { mutableStateOf<Uri?>(null) }
    val takePictureLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.TakePicture()
    ) { success ->
        if (success) {
            tempPhotoUri?.let { viewModel.addPhoto(it) }
        }
    }

    val pickImageLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        uri?.let { viewModel.addPhoto(it) }
    }

    val pickAudioLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        uri?.let { viewModel.selectAudioFile(context, it) }
    }

    val speechLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        val text = result.data
            ?.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)
            ?.firstOrNull() ?: return@rememberLauncherForActivityResult
        viewModel.addMemo(text, isVoice = true)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("記録を追加", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "戻る")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f)
                )
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(24.dp)
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            // ---- 写真セクション ----
            Surface(
                color = MaterialTheme.colorScheme.surfaceColorAtElevation(2.dp),
                shape = MaterialTheme.shapes.medium
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Default.CameraAlt, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                        Spacer(Modifier.width(8.dp))
                        Text("写真を追加", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                    }
                    Spacer(Modifier.height(16.dp))
                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        Button(
                            onClick = {
                                if (cameraPermission.status.isGranted) {
                                    val uri = com.example.aleartmycontroller.ui.util.CameraUtils.createImageUri(context)
                                    tempPhotoUri = uri
                                    takePictureLauncher.launch(uri)
                                } else {
                                    cameraPermission.launchPermissionRequest()
                                }
                            },
                            modifier = Modifier.weight(1f),
                            shape = MaterialTheme.shapes.small
                        ) {
                            Text("カメラで撮影")
                        }
                        OutlinedButton(
                            onClick = { pickImageLauncher.launch("image/*") },
                            modifier = Modifier.weight(1f),
                            shape = MaterialTheme.shapes.small
                        ) {
                            Text("ギャラリー")
                        }
                    }
                }
            }

            // ---- メモセクション ----
            Surface(
                color = MaterialTheme.colorScheme.surfaceColorAtElevation(1.dp),
                shape = MaterialTheme.shapes.medium,
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Default.Notes, contentDescription = null, tint = MaterialTheme.colorScheme.secondary)
                        Spacer(Modifier.width(8.dp))
                        Text("メモを記入", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                    }
                    Spacer(Modifier.height(12.dp))
                    OutlinedTextField(
                        value = memoText,
                        onValueChange = { memoText = it },
                        modifier = Modifier.fillMaxWidth(),
                        placeholder = { Text("今の状況を記録しましょう...") },
                        minLines = 4,
                        shape = MaterialTheme.shapes.medium,
                        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Send),
                        keyboardActions = KeyboardActions(onSend = {
                            viewModel.addMemo(memoText)
                            memoText = ""
                        }),
                        trailingIcon = {
                            IconButton(
                                onClick = {
                                    viewModel.addMemo(memoText)
                                    memoText = ""
                                },
                                enabled = memoText.isNotBlank()
                            ) {
                                Icon(Icons.Default.Send, contentDescription = "送信")
                            }
                        }
                    )
                    Spacer(Modifier.height(12.dp))
                    FilledTonalButton(
                        onClick = {
                            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                                putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.JAPANESE.toLanguageTag())
                                putExtra(RecognizerIntent.EXTRA_PROMPT, "話してください")
                            }
                            speechLauncher.launch(intent)
                        },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Icon(Icons.Default.Mic, contentDescription = null)
                        Spacer(Modifier.width(8.dp))
                        Text("音声で入力する")
                    }
                }
            }

            // ---- 音声録音セクション ----
            Surface(
                color = MaterialTheme.colorScheme.surfaceColorAtElevation(1.dp),
                shape = MaterialTheme.shapes.medium,
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Default.Mic, contentDescription = null, tint = MaterialTheme.colorScheme.tertiary)
                        Spacer(Modifier.width(8.dp))
                        Text("音声を録音する", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                    }
                    Spacer(Modifier.height(12.dp))
                    when (val rs = recordingState) {
                        is RecordingState.Idle -> {
                            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                Button(
                                    onClick = {
                                        if (audioPermission.status.isGranted) {
                                            viewModel.startRecording(context)
                                        } else {
                                            audioPermission.launchPermissionRequest()
                                        }
                                    },
                                    modifier = Modifier.weight(1f),
                                    colors = ButtonDefaults.buttonColors(
                                        containerColor = MaterialTheme.colorScheme.tertiary
                                    )
                                ) {
                                    Icon(Icons.Default.Mic, contentDescription = null)
                                    Spacer(Modifier.width(4.dp))
                                    Text("録音開始")
                                }
                                OutlinedButton(
                                    onClick = { pickAudioLauncher.launch("audio/*") },
                                    modifier = Modifier.weight(1f)
                                ) {
                                    Icon(Icons.Default.AudioFile, contentDescription = null)
                                    Spacer(Modifier.width(4.dp))
                                    Text("ファイルを選ぶ")
                                }
                            }
                        }
                        is RecordingState.Recording -> {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    CircularProgressIndicator(
                                        modifier = Modifier.size(20.dp),
                                        color = MaterialTheme.colorScheme.error,
                                        strokeWidth = 2.dp
                                    )
                                    Spacer(Modifier.width(8.dp))
                                    Text(
                                        text = formatDuration(rs.durationSeconds),
                                        style = MaterialTheme.typography.bodyLarge,
                                        fontWeight = FontWeight.Medium
                                    )
                                }
                                FilledTonalButton(
                                    onClick = { viewModel.stopRecording() },
                                    colors = ButtonDefaults.filledTonalButtonColors(
                                        containerColor = MaterialTheme.colorScheme.errorContainer
                                    )
                                ) {
                                    Icon(Icons.Default.Stop, contentDescription = null)
                                    Spacer(Modifier.width(4.dp))
                                    Text("停止")
                                }
                            }
                        }
                        is RecordingState.Recorded -> {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(
                                    Icons.Default.Check,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.tertiary
                                )
                                Spacer(Modifier.width(8.dp))
                                Text(
                                    text = "録音完了 (${formatDuration(rs.durationSeconds)})",
                                    style = MaterialTheme.typography.bodyMedium,
                                    modifier = Modifier.weight(1f)
                                )
                            }
                            Spacer(Modifier.height(8.dp))
                            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                Button(
                                    onClick = { viewModel.saveAudioMemo() },
                                    modifier = Modifier.weight(1f)
                                ) {
                                    Text("保存")
                                }
                                OutlinedButton(
                                    onClick = { viewModel.cancelRecording() },
                                    modifier = Modifier.weight(1f)
                                ) {
                                    Text("やり直し")
                                }
                            }
                        }
                    }
                }
            }

            // ---- エラー表示 ----
            if (uiState is AddRecordUiState.Error) {
                Text(
                    text = (uiState as AddRecordUiState.Error).message,
                    color = MaterialTheme.colorScheme.error
                )
            }

            // ---- ローディング ----
            if (uiState is AddRecordUiState.Loading) {
                LinearProgressIndicator(modifier = Modifier.fillMaxWidth())
            }
        }
    }
}

private fun formatDuration(seconds: Int): String {
    val m = seconds / 60
    val s = seconds % 60
    return "%02d:%02d".format(m, s)
}
