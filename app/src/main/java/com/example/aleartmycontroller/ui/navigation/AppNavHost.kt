package com.example.aleartmycontroller.ui.navigation

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.History
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.example.aleartmycontroller.ui.screen.*

@Composable
fun AppNavHost(initialEventId: Long? = null) {
    val navController = rememberNavController()

    LaunchedEffect(initialEventId) {
        initialEventId?.let { id ->
            navController.navigate(Screen.AddRecord.createRoute(id))
        }
    }
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination

    val showBottomBar = listOf(Screen.EventList.route, Screen.RecordList.route, Screen.History.route)
        .any { route -> currentDestination?.hierarchy?.any { it.route == route } == true }

    Scaffold(
        bottomBar = {
            if (showBottomBar) {
                BottomAppBar(
                    actions = {
                        // 左側: ホーム
                        BottomNavItem(
                            label = "ホーム",
                            icon = Icons.Default.Home,
                            selected = currentDestination?.hierarchy?.any { it.route == Screen.EventList.route } == true,
                            onClick = {
                                navController.navigate(Screen.EventList.route) {
                                    popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            },
                            modifier = Modifier.weight(1f)
                        )
                        
                        // 中央のスペース (FAB用)
                        Spacer(modifier = Modifier.weight(1f))

                        // 右側: 履歴
                        BottomNavItem(
                            label = "履歴",
                            icon = Icons.Default.History,
                            selected = currentDestination?.hierarchy?.any { it.route == Screen.History.route } == true,
                            onClick = {
                                navController.navigate(Screen.History.route) {
                                    popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            },
                            modifier = Modifier.weight(1f)
                        )
                    },
                    floatingActionButton = {
                        FloatingActionButton(
                            onClick = {
                                navController.navigate(Screen.RecordList.route) {
                                    popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            },
                            containerColor = MaterialTheme.colorScheme.primary,
                            elevation = FloatingActionButtonDefaults.elevation(0.dp),
                            shape = CircleShape,
                            modifier = Modifier.size(64.dp).offset(y = 20.dp)
                        ) {
                            Icon(Icons.Default.Add, contentDescription = "記録", modifier = Modifier.size(32.dp))
                        }
                    }
                )
            }
        }
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = Screen.EventList.route,
            modifier = Modifier.padding(innerPadding)
        ) {
            composable(Screen.EventList.route) {
                EventListScreen(
                    onEventClick = { eventId ->
                        navController.navigate(Screen.EventDetail.createRoute(eventId))
                    },
                    onStartEvent = { eventId ->
                        navController.navigate(Screen.RecordList.createRoute(eventId)) {
                            popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                            launchSingleTop = true
                            restoreState = true
                        }
                    },
                    onSettingsClick = {
                        navController.navigate(Screen.Settings.route)
                    }
                )
            }
            composable(Screen.History.route) {
                HistoryScreen(
                    onEventClick = { eventId ->
                        navController.navigate(Screen.EventDetail.createRoute(eventId))
                    },
                    onRecordClick = { recordId ->
                        navController.navigate(Screen.RecordDetail.createRoute(recordId))
                    },
                    isRecordViewInitial = false
                )
            }
            composable(Screen.Settings.route) {
                SettingsScreen(onBack = { navController.popBackStack() })
            }
            composable(
                route = Screen.EventDetail.route,
                arguments = listOf(navArgument("eventId") { type = NavType.LongType })
            ) {
                EventDetailScreen(
                    onBack = { navController.popBackStack() },
                    onAddRecord = { eventId ->
                        navController.navigate(Screen.AddRecord.createRoute(eventId))
                    },
                    onRecordClick = { recordId ->
                        navController.navigate(Screen.RecordDetail.createRoute(recordId))
                    }
                )
            }
            composable(
                route = Screen.AddRecord.route,
                arguments = listOf(navArgument("eventId") { type = NavType.LongType })
            ) {
                AddRecordScreen(
                    onBack = { navController.popBackStack() }
                )
            }
            composable(
                route = Screen.RecordList.route,
                arguments = listOf(navArgument("eventId") { 
                    type = NavType.LongType; defaultValue = -1L 
                })
            ) { backStackEntry ->
                val eventId = backStackEntry.arguments?.getLong("eventId")?.takeIf { it != -1L }
                RecordDashboardScreen(
                    onAddRecord = { id ->
                        navController.navigate(Screen.AddRecord.createRoute(id))
                    },
                    onRecordClick = { recordId ->
                        navController.navigate(Screen.RecordDetail.createRoute(recordId))
                    },
                    initialEventId = eventId
                )
            }
            composable(
                route = Screen.RecordDetail.route,
                arguments = listOf(navArgument("recordId") { type = NavType.LongType })
            ) {
                RecordDetailScreen(
                    onBack = { navController.popBackStack() }
                )
            }
        }
    }
}

@Composable
private fun BottomNavItem(
    label: String,
    icon: ImageVector,
    selected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier.clickable(onClick = onClick).padding(vertical = 8.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Icon(
                imageVector = icon,
                contentDescription = label,
                tint = if (selected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant
            )
            Text(
                text = label,
                style = MaterialTheme.typography.labelSmall,
                color = if (selected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}
