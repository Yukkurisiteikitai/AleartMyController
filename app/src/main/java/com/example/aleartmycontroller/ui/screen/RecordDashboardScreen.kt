package com.example.aleartmycontroller.ui.screen

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.aleartmycontroller.data.local.entity.EventEntity
import com.example.aleartmycontroller.ui.util.toLocalTime
import com.example.aleartmycontroller.ui.viewmodel.RecordDashboardUiEvent
import com.example.aleartmycontroller.ui.viewmodel.RecordDashboardViewModel

/**
 * 記録メニュー (証拠記録ワークスペース): 
 * Toggl Track を参考に、下部に記録開始バー（入力欄 + 再生ボタン）を配置。
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RecordDashboardScreen(
    onAddRecord: (Long) -> Unit,
    onRecordClick: (Long) -> Unit,
    initialEventId: Long? = null,
    initialDraftTitle: String? = null,
    viewModel: RecordDashboardViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val snackbarHostState = remember { SnackbarHostState() }
    val hapticFeedback = LocalHapticFeedback.current

    LaunchedEffect(initialEventId, initialDraftTitle) {
        initialEventId?.let { id ->
            viewModel.manualStartEvent(id)
        } ?: initialDraftTitle?.let { title ->
            viewModel.startDraftSession(title)
        }
    }

    LaunchedEffect(viewModel) {
        viewModel.uiEvent.collect { event ->
            when (event) {
                is RecordDashboardUiEvent.ShowError -> {
                    snackbarHostState.showSnackbar(event.message)
                }
                is RecordDashboardUiEvent.ShowWarning -> {
                    snackbarHostState.showSnackbar(event.message)
                }
            }
        }
    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text("証拠を記録", fontWeight = FontWeight.ExtraBold) },
                colors = TopAppBarDefaults.centerAlignedTopAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface
                )
            )
        },
        bottomBar = {
            if (uiState.currentEvent != null) {
                RecordingControlBar(
                    noteValue = uiState.currentObservationNote,
                    onNoteChange = viewModel::updateNote,
                    isRunning = uiState.isTimerRunning,
                    onShortPress = {
                        if (uiState.isTimerRunning) {
                            uiState.currentEvent?.eventId?.let { onAddRecord(it) }
                        } else {
                            viewModel.startTimer()
                        }
                    },
                    onLongPress = {
                        if (uiState.isTimerRunning) {
                            hapticFeedback.performHapticFeedback(HapticFeedbackType.LongPress)
                            viewModel.requestStop()
                        }
                    },
                    onDoublePress = {
                        if (uiState.isTimerRunning) {
                            viewModel.requestStop()
                        }
                    }
                )
            }
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 20.dp),
            verticalArrangement = Arrangement.spacedBy(24.dp)
        ) {
            val currentEvent = uiState.currentEvent
            if (currentEvent != null) {
                // ---- タイマーセクション ----
                TimerDisplay(
                    elapsedTime = uiState.elapsedTimeText,
                    isRunning = uiState.isTimerRunning,
                    eventTitle = currentEvent.title
                )

                // ---- 証拠記録アクション (タイマー動作中のみ) ----
                if (uiState.isTimerRunning) {
                    EvidenceActionSection(
                        onPhotoAction = { onAddRecord(currentEvent.eventId) },
                        onNoteAction = { onAddRecord(currentEvent.eventId) }
                    )
                }

                // ---- 最近の証拠履歴 ----
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Default.History, contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(Modifier.width(8.dp))
                    Text("最近の証拠", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                }
                
                LazyColumn(
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                    modifier = Modifier.weight(1f)
                ) {
                    items(uiState.recentRecords, key = { it.recordId }) { record ->
                        DashboardRecordItem(
                            recordTime = record.recordTime.toLocalTime(),
                            typeLabel = if (record.recordType == com.example.aleartmycontroller.data.local.entity.RecordType.PHOTO) "写真" else "メモ",
                            onClick = { onRecordClick(record.recordId) }
                        )
                    }
                }
            } else {
                NoActiveEventState()
            }
        }
    }
}

@Composable
private fun TimerDisplay(
    elapsedTime: String,
    isRunning: Boolean,
    eventTitle: String
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = eventTitle,
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold,
            color = if (isRunning) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(Modifier.height(8.dp))
        Text(
            text = elapsedTime,
            style = MaterialTheme.typography.displayLarge.copy(
                fontWeight = FontWeight.Black,
                letterSpacing = 2.sp,
                fontSize = 64.sp
            ),
            color = if (isRunning) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outline.copy(alpha = 0.5f)
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class, androidx.compose.foundation.ExperimentalFoundationApi::class)
@Composable
private fun RecordingControlBar(
    noteValue: String,
    onNoteChange: (String) -> Unit,
    isRunning: Boolean,
    onShortPress: () -> Unit,
    onLongPress: () -> Unit,
    onDoublePress: () -> Unit
) {
    Surface(
        tonalElevation = 8.dp,
        shadowElevation = 16.dp,
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier
                .padding(16.dp)
                .navigationBarsPadding(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            OutlinedTextField(
                value = noteValue,
                onValueChange = onNoteChange,
                placeholder = { Text("何をしていますか？") },
                modifier = Modifier.weight(1f),
                shape = CircleShape,
                colors = OutlinedTextFieldDefaults.colors(
                    unfocusedBorderColor = MaterialTheme.colorScheme.outlineVariant,
                    focusedContainerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f),
                    unfocusedContainerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f)
                ),
                singleLine = true
            )
            
            Box(
                modifier = Modifier
                    .size(56.dp)
                    .clip(CircleShape)
                    .background(if (isRunning) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.primary)
                    .combinedClickable(
                        onClick = onShortPress,
                        onLongClick = onLongPress,
                        onDoubleClick = onDoublePress
                    ),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = if (isRunning) Icons.Default.Stop else Icons.Default.PlayArrow,
                    contentDescription = null,
                    tint = Color.White,
                    modifier = Modifier.size(32.dp)
                )
            }
        }
    }
}

@Composable
private fun EvidenceActionSection(onPhotoAction: () -> Unit, onNoteAction: () -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Button(
            onClick = onPhotoAction,
            modifier = Modifier.weight(1f),
            colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.secondaryContainer),
            contentPadding = PaddingValues(16.dp)
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Default.PhotoCamera, contentDescription = null, tint = MaterialTheme.colorScheme.onSecondaryContainer)
                Spacer(Modifier.width(8.dp))
                Text("写真証拠", color = MaterialTheme.colorScheme.onSecondaryContainer)
            }
        }
        Button(
            onClick = onNoteAction,
            modifier = Modifier.weight(1f),
            colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.secondaryContainer),
            contentPadding = PaddingValues(16.dp)
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Default.EditNote, contentDescription = null, tint = MaterialTheme.colorScheme.onSecondaryContainer)
                Spacer(Modifier.width(8.dp))
                Text("メモ証拠", color = MaterialTheme.colorScheme.onSecondaryContainer)
            }
        }
    }
}

@Composable
private fun DashboardRecordItem(recordTime: String, typeLabel: String, onClick: () -> Unit) {
    Surface(
        onClick = onClick,
        shape = MaterialTheme.shapes.medium,
        color = MaterialTheme.colorScheme.surface,
        border = androidx.compose.foundation.BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant),
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(modifier = Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
            Text(recordTime, style = MaterialTheme.typography.labelLarge, fontWeight = FontWeight.Bold)
            Spacer(Modifier.width(16.dp))
            Text(typeLabel, style = MaterialTheme.typography.bodyMedium)
            Spacer(Modifier.weight(1f))
            Icon(Icons.Default.ChevronRight, contentDescription = null, tint = MaterialTheme.colorScheme.outline)
        }
    }
}

@Composable
private fun NoActiveEventState() {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Icon(Icons.Default.Timeline, contentDescription = null, modifier = Modifier.size(80.dp), tint = MaterialTheme.colorScheme.outlineVariant)
            Spacer(Modifier.height(16.dp))
            Text("現在進行中のイベントはありません", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.outline)
        }
    }
}
