package com.example.aleartmycontroller.ui.screen

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.EventNote
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.Notes
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
import com.example.aleartmycontroller.data.local.entity.EventEntity
import com.example.aleartmycontroller.data.local.entity.RecordEntity
import com.example.aleartmycontroller.data.local.entity.RecordType
import com.example.aleartmycontroller.ui.util.toLocalDate
import com.example.aleartmycontroller.ui.util.toLocalTime
import com.example.aleartmycontroller.ui.viewmodel.EventListViewModel
import com.example.aleartmycontroller.ui.viewmodel.HistoryViewModel

/**
 * 履歴画面: 過去のログを「イベント」または「記録（タイムライン）」単位で表示する。
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HistoryScreen(
    onEventClick: (Long) -> Unit,
    onRecordClick: (Long) -> Unit,
    isRecordViewInitial: Boolean = false,
    eventViewModel: EventListViewModel = hiltViewModel(),
    historyViewModel: HistoryViewModel = hiltViewModel()
) {
    // 初期表示の設定
    LaunchedEffect(isRecordViewInitial) {
        if (historyViewModel.uiState.value.isRecordView != isRecordViewInitial) {
            historyViewModel.toggleView()
        }
    }

    val events by eventViewModel.events.collectAsStateWithLifecycle()
    val records by historyViewModel.allRecords.collectAsStateWithLifecycle()
    val uiState by historyViewModel.uiState.collectAsStateWithLifecycle()

    Scaffold(
        topBar = {
            Column {
                TopAppBar(title = { Text("履歴", fontWeight = FontWeight.Bold) })
                val tabs = listOf("イベント", "記録")
                TabRow(selectedTabIndex = if (uiState.isRecordView) 1 else 0) {
                    tabs.forEachIndexed { index, title ->
                        Tab(
                            selected = (if (uiState.isRecordView) 1 else 0) == index,
                            onClick = { if ((if (uiState.isRecordView) 1 else 0) != index) historyViewModel.toggleView() },
                            text = { Text(title) }
                        )
                    }
                }
            }
        }
    ) { padding ->
        Box(modifier = Modifier.padding(padding)) {
            if (uiState.isRecordView) {
                // 記録タイムライン表示
                if (records.isEmpty()) {
                    EmptyHistoryPlaceholder("まだ記録がありません")
                } else {
                    GlobalRecordTimeline(
                        records = records,
                        photosByRecord = uiState.photosByRecord,
                        memosByRecord = uiState.memosByRecord,
                        onRecordClick = onRecordClick
                    )
                }
            } else {
                // イベント履歴表示
                if (events.isEmpty()) {
                    EmptyHistoryPlaceholder("イベントの履歴がありません")
                } else {
                    LazyColumn(contentPadding = PaddingValues(vertical = 8.dp)) {
                        items(events, key = { it.event.eventId }) { item ->
                            HistoryEventItem(event = item.event, onClick = { onEventClick(item.event.eventId) })
                            HorizontalDivider(thickness = 0.5.dp, modifier = Modifier.padding(horizontal = 16.dp))
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun EmptyHistoryPlaceholder(message: String) {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Icon(Icons.Default.History, contentDescription = null, modifier = Modifier.size(48.dp), tint = MaterialTheme.colorScheme.outline)
            Spacer(Modifier.height(16.dp))
            Text(message, style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.outline)
        }
    }
}

@Composable
private fun HistoryEventItem(event: EventEntity, onClick: () -> Unit) {
    ListItem(
        modifier = Modifier.clickable(onClick = onClick),
        overlineContent = {
            Text(event.startTime.toLocalDate(), style = MaterialTheme.typography.labelSmall)
        },
        headlineContent = { Text(event.title, fontWeight = FontWeight.SemiBold) },
        supportingContent = {
            Text("${event.startTime.toLocalTime()} – ${event.endTime.toLocalTime()}")
        },
        leadingContent = {
            Icon(Icons.Default.EventNote, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
        }
    )
}

@Composable
private fun GlobalRecordTimeline(
    records: List<RecordEntity>,
    photosByRecord: Map<Long, List<com.example.aleartmycontroller.data.local.entity.PhotoEntity>>,
    memosByRecord: Map<Long, List<com.example.aleartmycontroller.data.local.entity.MemoEntity>>,
    onRecordClick: (Long) -> Unit
) {
    LazyColumn(
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        items(records, key = { it.recordId }) { record ->
            HistoryRecordItem(
                record = record,
                photos = photosByRecord[record.recordId] ?: emptyList(),
                memos = memosByRecord[record.recordId] ?: emptyList(),
                onClick = { onRecordClick(record.recordId) }
            )
        }
    }
}

@Composable
private fun HistoryRecordItem(
    record: RecordEntity,
    photos: List<com.example.aleartmycontroller.data.local.entity.PhotoEntity>,
    memos: List<com.example.aleartmycontroller.data.local.entity.MemoEntity>,
    onClick: () -> Unit
) {
    val icon = when (record.recordType) {
        RecordType.PHOTO -> Icons.Default.CameraAlt
        RecordType.MEMO  -> Icons.Default.Notes
    }

    Card(
        onClick = onClick,
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(modifier = Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(MaterialTheme.shapes.small)
                    .background(MaterialTheme.colorScheme.primaryContainer),
                contentAlignment = Alignment.Center
            ) {
                if (record.recordType == RecordType.PHOTO && photos.isNotEmpty()) {
                    AsyncImage(
                        model = photos.first().filePath,
                        contentDescription = null,
                        contentScale = ContentScale.Crop
                    )
                } else {
                    Icon(icon, contentDescription = null, tint = MaterialTheme.colorScheme.onPrimaryContainer)
                }
            }
            
            Spacer(Modifier.width(16.dp))
            
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = if (record.recordType == RecordType.PHOTO) "写真の記録" else (memos.firstOrNull()?.memoText?.take(20) ?: "メモの記録"),
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Bold,
                    maxLines = 1
                )
                Text(
                    text = "${record.recordTime.toLocalDate()} ${record.recordTime.toLocalTime()}",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}
