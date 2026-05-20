package com.example.aleartmycontroller.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Notes
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.example.aleartmycontroller.ui.model.DomainRecord
import com.example.aleartmycontroller.ui.util.toLocalTime

import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset

@Composable
fun TimelineRecordItem(
    record: DomainRecord,
    isLastItem: Boolean,
    onClick: () -> Unit
) {
    val cardColors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
    val cardElevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    val cardBorder = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
    val outlineVariantColor = MaterialTheme.colorScheme.outlineVariant

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .drawBehind {
                if (!isLastItem) {
                    val strokeWidth = 2.dp.toPx()
                    val centerX = 16.dp.toPx() + 16.dp.toPx() // padding(16) + center of column(16)
                    val startY = 16.dp.toPx() + 14.dp.toPx() + 4.dp.toPx() // spacer(16) + node(14) + gap(4)
                    drawLine(
                        color = outlineVariantColor,
                        start = Offset(centerX, startY),
                        end = Offset(centerX, size.height),
                        strokeWidth = strokeWidth
                    )
                }
            }
            .padding(horizontal = 16.dp),
        verticalAlignment = Alignment.Top
    ) {
        // 左側のタイムライン部分
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier
                .width(32.dp)
        ) {
            Spacer(modifier = Modifier.height(16.dp)) // ノードをカードの少し下に配置
            
            // ノード（丸）
            Box(
                modifier = Modifier
                    .size(14.dp)
                    .clip(CircleShape)
                    .background(MaterialTheme.colorScheme.primary),
                contentAlignment = Alignment.Center
            ) {
                Box(
                    modifier = Modifier
                        .size(6.dp)
                        .clip(CircleShape)
                        .background(MaterialTheme.colorScheme.onPrimary)
                )
            }
            // 下に続く線は drawBehind で親(Row)から描画するため、ここは不要
        }
        
        Spacer(modifier = Modifier.width(12.dp))
        
        // 右側のカード部分
        val icon = when (record) {
            is DomainRecord.PhotoRecord -> Icons.Default.CameraAlt
            is DomainRecord.MemoRecord -> Icons.AutoMirrored.Filled.Notes
        }
        
        val title = when (record) {
            is DomainRecord.PhotoRecord -> "写真の記録"
            is DomainRecord.MemoRecord -> record.texts.firstOrNull() ?: "メモの記録"
        }

        Card(
            shape = RoundedCornerShape(16.dp),
            colors = cardColors,
            elevation = cardElevation,
            border = cardBorder,
            modifier = Modifier
                .weight(1f)
                .padding(vertical = 8.dp)
                .clip(RoundedCornerShape(16.dp))
                .clickable { onClick() }
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                // ヘッダー部
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = icon,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = record.time.toLocalTime(),
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        fontWeight = FontWeight.Medium
                    )
                }
                
                Spacer(modifier = Modifier.height(12.dp))
                
                // コンテンツ部
                when (record) {
                    is DomainRecord.PhotoRecord -> {
                        if (record.photoPaths.isNotEmpty()) {
                            LazyRow(
                                horizontalArrangement = Arrangement.spacedBy(12.dp),
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                items(record.photoPaths) { path ->
                                    AsyncImage(
                                        model = path,
                                        contentDescription = "添付写真",
                                        modifier = Modifier
                                            .size(120.dp)
                                            .clip(RoundedCornerShape(12.dp)),
                                        contentScale = ContentScale.Crop
                                    )
                                }
                            }
                        } else {
                            Text(
                                text = "写真がありません",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                    is DomainRecord.MemoRecord -> {
                        record.texts.forEach { text ->
                            Text(
                                text = text,
                                style = MaterialTheme.typography.bodyLarge,
                                color = MaterialTheme.colorScheme.onSurface,
                                modifier = Modifier.padding(bottom = 4.dp),
                                maxLines = 5,
                                overflow = TextOverflow.Ellipsis
                            )
                        }
                    }
                }
            }
        }
    }
}
