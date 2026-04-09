package com.example.aleartmycontroller.ui.screen

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.aleartmycontroller.data.local.entity.EventEntity
import com.example.aleartmycontroller.ui.model.EventWithCounts
import com.example.aleartmycontroller.ui.util.toLocalDate
import com.example.aleartmycontroller.ui.util.toLocalTime
import com.example.aleartmycontroller.ui.viewmodel.EventListViewModel

/**
 * 履歴画面: 過去のイベント記録を一覧表示する。
 * EventListViewModel の observeAllEvents を利用。
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HistoryScreen(
    onEventClick: (Long) -> Unit,
    viewModel: EventListViewModel = hiltViewModel()
) {
    val events by viewModel.events.collectAsStateWithLifecycle()

    Scaffold(
        topBar = {
            TopAppBar(title = { Text("履歴") })
        }
    ) { padding ->
        if (events.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding),
                contentAlignment = Alignment.Center
            ) {
                Text("記録がありません", style = MaterialTheme.typography.bodyLarge)
            }
        } else {
            LazyColumn(
                modifier = Modifier.padding(padding),
                contentPadding = PaddingValues(vertical = 8.dp)
            ) {
                items(events, key = { it.event.eventId }) { item ->
                    HistoryItem(event = item.event, onClick = { onEventClick(item.event.eventId) })
                    HorizontalDivider(thickness = 0.5.dp)
                }
            }
        }
    }
}

@Composable
private fun HistoryItem(event: EventEntity, onClick: () -> Unit) {
    ListItem(
        modifier = Modifier.padding(0.dp),
        overlineContent = {
            Text(event.startTime.toLocalDate(), style = MaterialTheme.typography.labelSmall)
        },
        headlineContent = { Text(event.title) },
        supportingContent = {
            Text("${event.startTime.toLocalTime()} – ${event.endTime.toLocalTime()}")
        }
    )
}
