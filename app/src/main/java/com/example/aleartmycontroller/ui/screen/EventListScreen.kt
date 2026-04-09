package com.example.aleartmycontroller.ui.screen

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.Notes
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.aleartmycontroller.ui.model.EventWithCounts
import com.example.aleartmycontroller.ui.util.toLocalDate
import com.example.aleartmycontroller.ui.util.toLocalTime
import com.example.aleartmycontroller.ui.viewmodel.EventListViewModel
import com.example.aleartmycontroller.ui.viewmodel.EventListUiState

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EventListScreen(
    onEventClick: (Long) -> Unit,
    onStartEvent: (Long) -> Unit,
    onSettingsClick: () -> Unit,
    viewModel: EventListViewModel = hiltViewModel()
) {
    val eventsWithCounts: List<EventWithCounts> by viewModel.events.collectAsStateWithLifecycle()
    val uiState: EventListUiState by viewModel.uiState.collectAsStateWithLifecycle()

    if (uiState.errorMessage != null) {
        AlertDialog(
            onDismissRequest = viewModel::dismissError,
            confirmButton = {
                TextButton(onClick = viewModel::dismissError) { Text("OK") }
            },
            title = { Text("同期エラー") },
            text = { Text(uiState.errorMessage!!) }
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("ホーム", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onSettingsClick) {
                        Icon(Icons.Default.Settings, contentDescription = "設定")
                    }
                },
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
                EventList(
                    eventsWithCounts = eventsWithCounts,
                    onEventClick = onEventClick,
                    onStartEvent = onStartEvent
                )
            }
        }
    }
}

@Composable
private fun EventList(
    eventsWithCounts: List<EventWithCounts>,
    onEventClick: (Long) -> Unit,
    onStartEvent: (Long) -> Unit
) {
    val now = System.currentTimeMillis()
    LazyColumn(
        contentPadding = PaddingValues(vertical = 8.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        items(eventsWithCounts, key = { it.event.eventId }) { item ->
            val isCurrent = now in item.event.startTime..item.event.endTime
            EventListItem(
                item = item,
                isCurrent = isCurrent,
                onClick = { onEventClick(item.event.eventId) },
                onStartClick = { onStartEvent(item.event.eventId) }
            )
        }
    }
}

@Composable
private fun EventListItem(
    item: EventWithCounts,
    isCurrent: Boolean,
    onClick: () -> Unit,
    onStartClick: () -> Unit
) {
    val event = item.event
    val containerColor = if (isCurrent) {
        MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.9f)
    } else {
        MaterialTheme.colorScheme.surface
    }

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .clickable(onClick = onClick),
        colors = CardDefaults.cardColors(containerColor = containerColor),
        elevation = if (isCurrent) CardDefaults.cardElevation(defaultElevation = 4.dp) else CardDefaults.cardElevation(defaultElevation = 0.dp),
        border = if (isCurrent) androidx.compose.foundation.BorderStroke(2.dp, MaterialTheme.colorScheme.primary.copy(alpha = 0.5f)) else null
    ) {
        ListItem(
            colors = ListItemDefaults.colors(containerColor = Color.Transparent),
            overlineContent = {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(event.startTime.toLocalDate(), style = MaterialTheme.typography.labelSmall)
                    if (isCurrent) {
                        Spacer(Modifier.width(8.dp))
                        Surface(
                            color = MaterialTheme.colorScheme.primary,
                            shape = CircleShape,
                            modifier = Modifier.size(8.dp)
                        ) {}
                        Spacer(Modifier.width(4.dp))
                        Text(
                            "実行中の予定",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.primary,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            },
            headlineContent = {
                Text(
                    text = event.title,
                    style = if (isCurrent) MaterialTheme.typography.titleMedium else MaterialTheme.typography.bodyLarge,
                    fontWeight = if (isCurrent) FontWeight.ExtraBold else FontWeight.SemiBold
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
            },
            trailingContent = {
                IconButton(onClick = onStartClick) {
                    Icon(
                        imageVector = Icons.Default.PlayArrow,
                        contentDescription = "開始",
                        tint = if (isCurrent) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        )
    }
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
