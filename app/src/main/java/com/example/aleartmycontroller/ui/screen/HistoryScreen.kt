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

import com.example.aleartmycontroller.ui.components.EmptyStatePlaceholder
import com.example.aleartmycontroller.ui.components.TimelineRecordItem
import com.example.aleartmycontroller.ui.model.DomainRecord

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
                    EmptyStatePlaceholder(
                        icon = Icons.Default.History,
                        title = "記録がありません",
                        message = "まだ何も記録されていません。観察画面から新しい記録を追加してみましょう！"
                    )
                } else {
                    GlobalRecordTimeline(
                        records = records,
                        onRecordClick = onRecordClick
                    )
                }
            } else {
                // イベント履歴表示
                if (events.isEmpty()) {
                    EmptyStatePlaceholder(
                        icon = Icons.Default.EventNote,
                        title = "イベントがありません",
                        message = "過去のイベント履歴がここに表示されます。"
                    )
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
    records: List<DomainRecord>,
    onRecordClick: (Long) -> Unit
) {
    LazyColumn(
        contentPadding = PaddingValues(vertical = 16.dp),
        modifier = Modifier.fillMaxSize()
    ) {
        items(records.size, key = { records[it].id }) { index ->
            val record = records[index]
            TimelineRecordItem(
                record = record,
                isLastItem = index == records.lastIndex,
                onClick = { onRecordClick(record.id) }
            )
        }
    }
}
