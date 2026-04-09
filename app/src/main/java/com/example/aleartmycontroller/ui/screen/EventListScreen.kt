package com.example.aleartmycontroller.ui.screen

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.aleartmycontroller.ui.model.EventWithCounts
import com.example.aleartmycontroller.ui.util.toLocalDate
import com.example.aleartmycontroller.ui.util.toLocalTime
import com.example.aleartmycontroller.ui.viewmodel.EventListViewModel
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.Notes

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EventListScreen(
    onEventClick: (Long) -> Unit,
    viewModel: EventListViewModel = hiltViewModel()
) {
    val eventsWithCounts by viewModel.events.collectAsStateWithLifecycle()
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    // エラー表示
    uiState.errorMessage?.let { msg ->
        AlertDialog(
            onDismissRequest = viewModel::dismissError,
            confirmButton = {
                TextButton(onClick = viewModel::dismissError) { Text("OK") }
            },
            title = { Text("同期エラー") },
            text = { Text(msg) }
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("イベント一覧", fontWeight = FontWeight.Bold) },
                actions = {
                    IconButton(onClick = viewModel::syncCalendar) {
                        Icon(Icons.Default.Refresh, contentDescription = "カレンダー同期")
                    }
                }
            )
        }
    ) { padding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            if (uiState.isLoading) {
                CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
            } else if (eventsWithCounts.isEmpty()) {
                EmptyPlaceholder(modifier = Modifier.align(Alignment.Center))
            } else {
                EventList(eventsWithCounts = eventsWithCounts, onEventClick = onEventClick)
            }
        }
    }
}

@Composable
private fun EventList(
    eventsWithCounts: List<EventWithCounts>,
    onEventClick: (Long) -> Unit
) {
    LazyColumn(
        contentPadding = PaddingValues(vertical = 8.dp),
        verticalArrangement = Arrangement.spacedBy(0.dp)
    ) {
        items(eventsWithCounts, key = { it.event.eventId }) { item ->
            EventListItem(
                item = item,
                onClick = { onEventClick(item.event.eventId) }
            )
            HorizontalDivider(thickness = 0.5.dp, modifier = Modifier.padding(horizontal = 16.dp))
        }
    }
}

@Composable
private fun EventListItem(item: EventWithCounts, onClick: () -> Unit) {
    val event = item.event
    ListItem(
        modifier = Modifier.clickable(onClick = onClick),
        overlineContent = {
            Text(event.startTime.toLocalDate(), style = MaterialTheme.typography.labelSmall)
        },
        headlineContent = {
            Text(
                text = event.title,
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = FontWeight.SemiBold
            )
        },
        supportingContent = {
            Column {
                Text(
                    text = "${event.startTime.toLocalTime()} – ${event.endTime.toLocalTime()}",
                    style = MaterialTheme.typography.bodySmall
                )
                if (item.photoCount > 0 || item.memoCount > 0) {
                    Spacer(Modifier.height(4.dp))
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        if (item.photoCount > 0) {
                            BadgeItem(icon = Icons.Default.CameraAlt, count = item.photoCount)
                        }
                        if (item.memoCount > 0) {
                            BadgeItem(icon = Icons.Default.Notes, count = item.memoCount)
                        }
                    }
                }
            }
        }
    )
}

@Composable
private fun BadgeItem(icon: androidx.compose.ui.graphics.vector.ImageVector, count: Int) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            modifier = Modifier.size(14.dp),
            tint = MaterialTheme.colorScheme.primary.copy(alpha = 0.7f)
        )
        Spacer(Modifier.width(4.dp))
        Text(
            text = count.toString(),
            style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
private fun EmptyPlaceholder(modifier: Modifier = Modifier) {
    Column(modifier = modifier, horizontalAlignment = Alignment.CenterHorizontally) {
        Text("予定がありません", style = MaterialTheme.typography.bodyLarge)
        Spacer(Modifier.height(4.dp))
        Text("右上のボタンで同期してください", style = MaterialTheme.typography.bodySmall)
    }
}
