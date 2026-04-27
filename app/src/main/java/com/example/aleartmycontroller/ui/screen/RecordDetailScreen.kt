package com.example.aleartmycontroller.ui.screen

import android.media.MediaPlayer
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Event
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import coil.compose.AsyncImage
import com.example.aleartmycontroller.data.local.entity.MemoEntity
import com.example.aleartmycontroller.ui.util.toLocalDate
import com.example.aleartmycontroller.ui.util.toLocalTime
import com.example.aleartmycontroller.ui.viewmodel.RecordDetailViewModel
import java.io.File

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RecordDetailScreen(
    onBack: () -> Unit,
    viewModel: RecordDetailViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    LaunchedEffect(uiState.isDeleted) {
        if (uiState.isDeleted) {
            onBack()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("記録詳細") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "戻る")
                    }
                },
                actions = {
                    IconButton(onClick = viewModel::deleteRecord) {
                        Icon(Icons.Default.Delete, contentDescription = "削除", tint = MaterialTheme.colorScheme.error)
                    }
                }
            )
        }
    ) { padding ->
        Box(modifier = Modifier.padding(padding).fillMaxSize()) {
            if (uiState.isLoading) {
                CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
            } else {
                val record = uiState.record
                if (record != null) {
                    Column(
                        modifier = Modifier
                            .fillMaxSize()
                            .verticalScroll(rememberScrollState())
                            .padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        // ---- 写真セクション ----
                        if (uiState.photos.isNotEmpty()) {
                            uiState.photos.forEach { photo ->
                                Card(
                                    shape = MaterialTheme.shapes.large,
                                    modifier = Modifier.fillMaxWidth()
                                ) {
                                    AsyncImage(
                                        model = photo.filePath,
                                        contentDescription = "記録写真",
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .heightIn(max = 400.dp)
                                            .clip(MaterialTheme.shapes.large),
                                        contentScale = ContentScale.Fit
                                    )
                                }
                            }
                        }

                        // ---- コンテンツセクション ----
                        Surface(
                            tonalElevation = 1.dp,
                            shape = MaterialTheme.shapes.medium,
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Column(modifier = Modifier.padding(16.dp)) {
                                if (uiState.memos.isNotEmpty()) {
                                    uiState.memos.forEach { memo ->
                                        if (memo.audioFilePath != null) {
                                            AudioPlayerRow(memo)
                                        } else {
                                            if (memo.memoText.isNotBlank()) {
                                                Text(
                                                    text = memo.memoText,
                                                    style = MaterialTheme.typography.bodyLarge,
                                                    modifier = Modifier.padding(bottom = 12.dp)
                                                )
                                            }
                                            if (memo.isVoiceMemo) {
                                                SuggestionChip(
                                                    onClick = {},
                                                    label = { Text("音声入力") },
                                                    enabled = false
                                                )
                                            }
                                        }
                                    }
                                }

                                HorizontalDivider(modifier = Modifier.padding(vertical = 12.dp))

                                MetadataRow(
                                    icon = Icons.Default.Schedule,
                                    label = "記録時刻",
                                    value = "${record.recordTime.toLocalDate()} ${record.recordTime.toLocalTime()}"
                                )
                                Spacer(Modifier.height(8.dp))
                                uiState.event?.let { event ->
                                    MetadataRow(
                                        icon = Icons.Default.Event,
                                        label = "関連イベント",
                                        value = event.title
                                    )
                                }
                            }
                        }
                    }
                }
            }

            if (uiState.errorMessage != null) {
                AlertDialog(
                    onDismissRequest = viewModel::dismissError,
                    confirmButton = {
                        TextButton(onClick = viewModel::dismissError) { Text("OK") }
                    },
                    title = { Text("エラー") },
                    text = { Text(uiState.errorMessage!!) }
                )
            }
        }
    }
}

@Composable
private fun AudioPlayerRow(memo: MemoEntity) {
    val filePath = memo.audioFilePath ?: return
    var isPlaying by remember { mutableStateOf(false) }
    val mediaPlayer = remember { MediaPlayer() }

    DisposableEffect(filePath) {
        runCatching {
            mediaPlayer.setDataSource(filePath)
            mediaPlayer.prepare()
        }
        mediaPlayer.setOnCompletionListener { isPlaying = false }
        onDispose {
            mediaPlayer.release()
        }
    }

    Surface(
        tonalElevation = 3.dp,
        shape = MaterialTheme.shapes.small,
        modifier = Modifier.fillMaxWidth().padding(bottom = 12.dp)
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                Icons.Default.Mic,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.tertiary,
                modifier = Modifier.size(20.dp)
            )
            Spacer(Modifier.width(8.dp))
            Text(
                text = "録音メモ",
                style = MaterialTheme.typography.bodyMedium,
                modifier = Modifier.weight(1f)
            )
            IconButton(
                onClick = {
                    if (isPlaying) {
                        mediaPlayer.pause()
                        isPlaying = false
                    } else {
                        if (mediaPlayer.currentPosition == mediaPlayer.duration) {
                            mediaPlayer.seekTo(0)
                        }
                        mediaPlayer.start()
                        isPlaying = true
                    }
                }
            ) {
                Icon(
                    imageVector = if (isPlaying) Icons.Default.Pause else Icons.Default.PlayArrow,
                    contentDescription = if (isPlaying) "一時停止" else "再生"
                )
            }
            IconButton(
                onClick = {
                    mediaPlayer.pause()
                    mediaPlayer.seekTo(0)
                    isPlaying = false
                }
            ) {
                Icon(Icons.Default.Stop, contentDescription = "停止")
            }
        }
    }
}

@Composable
private fun MetadataRow(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    value: String
) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            modifier = Modifier.size(16.dp),
            tint = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(Modifier.width(8.dp))
        Text(
            text = "$label: ",
            style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodySmall,
            fontWeight = FontWeight.Medium
        )
    }
}
