package com.example.aleartmycontroller.ui.screen

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Notes
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.aleartmycontroller.ui.util.toLocalTime
import com.example.aleartmycontroller.ui.viewmodel.EventDetailViewModel
import com.example.aleartmycontroller.ui.components.EmptyStatePlaceholder
import com.example.aleartmycontroller.ui.components.TimelineRecordItem
import com.example.aleartmycontroller.ui.model.DomainRecord

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EventDetailScreen(
    onBack: () -> Unit,
    onAddRecord: (Long) -> Unit,
    onRecordClick: (Long) -> Unit,
    viewModel: EventDetailViewModel = hiltViewModel()
) {
    val uiState   by viewModel.uiState.collectAsStateWithLifecycle()
    val records   by viewModel.records.collectAsStateWithLifecycle()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(uiState.event?.title ?: "イベント詳細") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "戻る")
                    }
                }
            )
        },
        floatingActionButton = {
            uiState.event?.let { event ->
                FloatingActionButton(onClick = { onAddRecord(event.eventId) }) {
                    Icon(Icons.Default.Add, contentDescription = "記録追加")
                }
            }
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            // イベント時間ヘッダ
            uiState.event?.let { event ->
                Surface(
                    tonalElevation = 2.dp,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(
                        text = "${event.startTime.toLocalTime()} – ${event.endTime.toLocalTime()}",
                        style = MaterialTheme.typography.labelLarge,
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                    )
                }
            }

            if (records.isEmpty()) {
                EmptyStatePlaceholder(
                    icon = Icons.Default.Notes,
                    title = "記録がありません",
                    message = "このイベントにはまだ記録がありません。右下の＋ボタンから追加しましょう！"
                )
            } else {
                TimelineRecordList(
                    records = records,
                    onRecordClick = onRecordClick
                )
            }
        }
    }
}


@Composable
private fun TimelineRecordList(
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
