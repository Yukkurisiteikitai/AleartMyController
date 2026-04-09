package com.example.aleartmycontroller.ui.screen

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Event
import androidx.compose.material.icons.filled.Schedule
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
import com.example.aleartmycontroller.ui.util.toLocalDate
import com.example.aleartmycontroller.ui.util.toLocalTime
import com.example.aleartmycontroller.ui.viewmodel.RecordDetailViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RecordDetailScreen(
    onBack: () -> Unit,
    viewModel: RecordDetailViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    // 削除成功時に戻る
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
                                        Text(
                                            text = memo.memoText,
                                            style = MaterialTheme.typography.bodyLarge,
                                            modifier = Modifier.padding(bottom = 12.dp)
                                        )
                                        if (memo.isVoiceMemo) {
                                            SuggestionChip(
                                                onClick = {},
                                                label = { Text("音声入力") },
                                                enabled = false
                                            )
                                        }
                                    }
                                }
                                
                                HorizontalDivider(modifier = Modifier.padding(vertical = 12.dp))
                                
                                // メタデータ
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

            // エラー表示
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
