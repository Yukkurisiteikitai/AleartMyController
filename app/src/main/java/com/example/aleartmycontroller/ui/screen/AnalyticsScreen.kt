package com.example.aleartmycontroller.ui.screen

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.patrykandpatrick.vico.compose.cartesian.CartesianChartHost
import com.patrykandpatrick.vico.compose.cartesian.layer.rememberColumnCartesianLayer
import com.patrykandpatrick.vico.compose.cartesian.layer.rememberLineCartesianLayer
import com.patrykandpatrick.vico.compose.cartesian.rememberCartesianChart
import com.patrykandpatrick.vico.compose.cartesian.axis.rememberBottom
import com.patrykandpatrick.vico.compose.cartesian.axis.rememberStart
import com.patrykandpatrick.vico.core.cartesian.axis.HorizontalAxis
import com.patrykandpatrick.vico.core.cartesian.axis.VerticalAxis
import com.patrykandpatrick.vico.core.cartesian.data.CartesianChartModelProducer
import com.patrykandpatrick.vico.core.cartesian.data.CartesianValueFormatter
import com.patrykandpatrick.vico.core.cartesian.data.columnSeries
import com.patrykandpatrick.vico.core.cartesian.data.lineSeries
import com.example.aleartmycontroller.data.local.dao.DailyRecordCount
import com.example.aleartmycontroller.data.local.dao.EventRecordCount
import com.example.aleartmycontroller.data.local.dao.RecordTypeCount
import com.example.aleartmycontroller.data.repository.AnalyticsSummary
import com.example.aleartmycontroller.data.repository.TogglDailyDuration
import com.example.aleartmycontroller.ui.viewmodel.AnalyticsPeriod
import com.example.aleartmycontroller.ui.viewmodel.AnalyticsViewModel
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AnalyticsScreen(viewModel: AnalyticsViewModel = hiltViewModel()) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    Scaffold(
        topBar = {
            TopAppBar(title = { Text("分析") })
        }
    ) { padding ->
        LazyColumn(
            contentPadding = PaddingValues(
                start = 16.dp, end = 16.dp,
                top = padding.calculateTopPadding() + 8.dp,
                bottom = padding.calculateBottomPadding() + 16.dp
            ),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            item {
                PeriodChips(selected = uiState.period, onSelect = viewModel::setPeriod)
            }

            if (uiState.isLoading) {
                item {
                    Box(
                        modifier = Modifier.fillMaxWidth().padding(24.dp),
                        contentAlignment = Alignment.Center
                    ) { CircularProgressIndicator() }
                }
                return@LazyColumn
            }

            uiState.errorMessage?.let { msg ->
                item { Text(text = "エラー: $msg", color = MaterialTheme.colorScheme.error) }
            }

            item { SummarySection(summary = uiState.summary) }

            if (uiState.dailyCounts.isNotEmpty()) {
                item {
                    SectionCard(title = "日別記録数推移") {
                        DailyTrendChart(dailyCounts = uiState.dailyCounts)
                    }
                }
            }

            if (uiState.typeBreakdown.isNotEmpty()) {
                item {
                    SectionCard(title = "記録タイプ内訳") {
                        TypeBreakdownChart(breakdown = uiState.typeBreakdown)
                    }
                }
            }

            if (uiState.topEvents.isNotEmpty()) {
                item {
                    SectionCard(title = "イベント別記録数 TOP") {
                        TopEventsSection(topEvents = uiState.topEvents)
                    }
                }
            }

            if (uiState.togglDaily.isNotEmpty()) {
                item {
                    SectionCard(title = "Toggl 日別作業時間") {
                        TogglDailyChart(togglDaily = uiState.togglDaily)
                    }
                }
            }
        }
    }
}

@Composable
private fun PeriodChips(selected: AnalyticsPeriod, onSelect: (AnalyticsPeriod) -> Unit) {
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        AnalyticsPeriod.entries.forEach { period ->
            FilterChip(
                selected = selected == period,
                onClick = { onSelect(period) },
                label = { Text(if (period == AnalyticsPeriod.WEEK) "7日" else "30日") }
            )
        }
    }
}

@Composable
private fun SummarySection(summary: AnalyticsSummary) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        SummaryCard(label = "総記録", value = summary.totalCount, modifier = Modifier.weight(1f))
        SummaryCard(label = "写真", value = summary.photoCount, modifier = Modifier.weight(1f))
        SummaryCard(label = "メモ", value = summary.memoCount, modifier = Modifier.weight(1f))
    }
}

@Composable
private fun SummaryCard(label: String, value: Int, modifier: Modifier = Modifier) {
    Card(modifier = modifier) {
        Column(
            modifier = Modifier.padding(12.dp).fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = value.toString(),
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = label,
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun SectionCard(title: String, content: @Composable () -> Unit) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(text = title, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold)
            Spacer(modifier = Modifier.height(12.dp))
            content()
        }
    }
}

@Composable
private fun DailyTrendChart(dailyCounts: List<DailyRecordCount>) {
    val zoneId = ZoneId.systemDefault()
    val dateFmt = DateTimeFormatter.ofPattern("M/d")
    val modelProducer = remember { CartesianChartModelProducer() }
    LaunchedEffect(dailyCounts) {
        modelProducer.runTransaction {
            lineSeries { series(dailyCounts.map { it.totalCount }) }
        }
    }
    CartesianChartHost(
        chart = rememberCartesianChart(
            rememberLineCartesianLayer(),
            startAxis = VerticalAxis.rememberStart(),
            bottomAxis = HorizontalAxis.rememberBottom(
                valueFormatter = CartesianValueFormatter { _, x, _ ->
                    val idx = x.toInt().coerceIn(0, dailyCounts.lastIndex)
                    Instant.ofEpochMilli(dailyCounts[idx].dayKey * 86400000L)
                        .atZone(zoneId).toLocalDate().format(dateFmt)
                }
            )
        ),
        modelProducer = modelProducer,
        modifier = Modifier.fillMaxWidth().height(160.dp)
    )
}

@Composable
private fun TypeBreakdownChart(breakdown: List<RecordTypeCount>) {
    val modelProducer = remember { CartesianChartModelProducer() }
    LaunchedEffect(breakdown) {
        modelProducer.runTransaction {
            columnSeries { series(breakdown.map { it.count }) }
        }
    }
    CartesianChartHost(
        chart = rememberCartesianChart(
            rememberColumnCartesianLayer(),
            startAxis = VerticalAxis.rememberStart(),
            bottomAxis = HorizontalAxis.rememberBottom(
                valueFormatter = CartesianValueFormatter { _, x, _ ->
                    val idx = x.toInt().coerceIn(0, breakdown.lastIndex)
                    when (breakdown[idx].recordType) {
                        "PHOTO" -> "写真"
                        "MEMO" -> "メモ"
                        else -> breakdown[idx].recordType
                    }
                }
            )
        ),
        modelProducer = modelProducer,
        modifier = Modifier.fillMaxWidth().height(140.dp)
    )
}

@Composable
private fun TopEventsSection(topEvents: List<EventRecordCount>) {
    val maxCount = topEvents.maxOf { it.recordCount }.coerceAtLeast(1)
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        topEvents.forEach { event ->
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = event.eventTitle,
                    modifier = Modifier.weight(1f),
                    style = MaterialTheme.typography.bodySmall,
                    maxLines = 1
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "${event.recordCount}件",
                    style = MaterialTheme.typography.bodySmall,
                    fontWeight = FontWeight.Bold
                )
            }
            LinearProgressIndicator(
                progress = { event.recordCount.toFloat() / maxCount },
                modifier = Modifier.fillMaxWidth()
            )
        }
    }
}

@Composable
private fun TogglDailyChart(togglDaily: List<TogglDailyDuration>) {
    val dateFmt = DateTimeFormatter.ofPattern("M/d")
    val modelProducer = remember { CartesianChartModelProducer() }
    LaunchedEffect(togglDaily) {
        modelProducer.runTransaction {
            lineSeries { series(togglDaily.map { it.totalSeconds.toFloat() / 3600f }) }
        }
    }
    CartesianChartHost(
        chart = rememberCartesianChart(
            rememberLineCartesianLayer(),
            startAxis = VerticalAxis.rememberStart(),
            bottomAxis = HorizontalAxis.rememberBottom(
                valueFormatter = CartesianValueFormatter { _, x, _ ->
                    val idx = x.toInt().coerceIn(0, togglDaily.lastIndex)
                    LocalDate.ofEpochDay(togglDaily[idx].dayKey).format(dateFmt)
                }
            )
        ),
        modelProducer = modelProducer,
        modifier = Modifier.fillMaxWidth().height(160.dp)
    )
    Text(
        text = "単位: 時間",
        style = MaterialTheme.typography.labelSmall,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = Modifier.padding(top = 4.dp)
    )
}
