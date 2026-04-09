package com.example.aleartmycontroller.ui.screen

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.Notes
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.aleartmycontroller.data.local.entity.RecordEntity
import com.example.aleartmycontroller.data.local.entity.RecordType
import com.example.aleartmycontroller.ui.util.toLocalTime
import com.example.aleartmycontroller.ui.viewmodel.EventDetailViewModel
import coil.compose.AsyncImage
import com.example.aleartmycontroller.data.local.entity.MemoEntity
import com.example.aleartmycontroller.data.local.entity.PhotoEntity
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale

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
                Box(Modifier.fillMaxSize(), contentAlignment = androidx.compose.ui.Alignment.Center) {
                    Text("まだ記録がありません", style = MaterialTheme.typography.bodyMedium)
                }
            } else {
                TimelineRecordList(
                    records = records,
                    photosByRecord = uiState.photosByRecord,
                    memosByRecord = uiState.memosByRecord,
                    onLoadAttachments = viewModel::loadAttachments,
                    onRecordClick = onRecordClick
                )
            }
        }
    }
}


@Composable
private fun TimelineRecordList(
    records: List<RecordEntity>,
    photosByRecord: Map<Long, List<PhotoEntity>>,
    memosByRecord: Map<Long, List<MemoEntity>>,
    onLoadAttachments: (Long) -> Unit,
    onRecordClick: (Long) -> Unit
) {
    LazyColumn(
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        items(records, key = { it.recordId }) { record ->
            LaunchedEffect(record.recordId) { onLoadAttachments(record.recordId) }
            val photos = photosByRecord[record.recordId] ?: emptyList()
            val memos = memosByRecord[record.recordId] ?: emptyList()
            RecordTimelineItem(
                record = record,
                photos = photos,
                memos = memos,
                onClick = { onRecordClick(record.recordId) }
            )
        }
    }
}


@Composable
private fun RecordTimelineItem(
    record: RecordEntity,
    photos: List<PhotoEntity>,
    memos: List<MemoEntity>,
    onClick: () -> Unit
) {
    val icon = when (record.recordType) {
        RecordType.PHOTO -> Icons.Default.CameraAlt
        RecordType.MEMO  -> Icons.Default.Notes
    }
    
    Card(
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
        ),
        modifier = Modifier.fillMaxWidth(),
        onClick = onClick
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(icon, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(18.dp))
                Spacer(Modifier.width(8.dp))
                Text(
                    text = record.recordTime.toLocalTime(),
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            
            if (photos.isNotEmpty()) {
                Spacer(Modifier.height(8.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    photos.forEach { photo ->
                        AsyncImage(
                            model = photo.filePath,
                            contentDescription = "添付写真",
                            modifier = Modifier
                                .size(100.dp)
                                .clip(MaterialTheme.shapes.small),
                            contentScale = ContentScale.Crop
                        )
                    }
                }
            }
            
            if (memos.isNotEmpty()) {
                Spacer(Modifier.height(8.dp))
                memos.forEach { memo ->
                    Text(
                        text = memo.memoText,
                        style = MaterialTheme.typography.bodyMedium,
                        modifier = Modifier.padding(vertical = 4.dp)
                    )
                }
            }
        }
    }
}
