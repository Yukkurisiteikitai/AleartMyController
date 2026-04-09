package com.example.aleartmycontroller.ui.navigation

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.example.aleartmycontroller.ui.screen.*

private data class BottomNavItem(
    val screen: Screen,
    val label: String,
    val icon: ImageVector
)

private val bottomNavItems = listOf(
    BottomNavItem(Screen.EventList, "イベント", Icons.Default.CalendarMonth),
    BottomNavItem(Screen.History,   "履歴",     Icons.Default.History),
    BottomNavItem(Screen.Settings,  "設定",     Icons.Default.Settings)
)

@Composable
fun AppNavHost(initialEventId: Long? = null) {
    val navController = rememberNavController()

    // 通知などからの初期遷移処理
    LaunchedEffect(initialEventId) {
        initialEventId?.let { id ->
             // 直接「記録追加」へ。戻ると一覧。
            navController.navigate(Screen.AddRecord.createRoute(id))
        }
    }
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination

    // ボトムナビを表示するルートかどうか
    val showBottomBar = bottomNavItems.any {
        currentDestination?.hierarchy?.any { dest -> dest.route == it.screen.route } == true
    }

    Scaffold(
        bottomBar = {
            if (showBottomBar) {
                NavigationBar {
                    bottomNavItems.forEach { item ->
                        NavigationBarItem(
                            icon = { Icon(item.icon, contentDescription = item.label) },
                            label = { Text(item.label) },
                            selected = currentDestination?.hierarchy
                                ?.any { it.route == item.screen.route } == true,
                            onClick = {
                                navController.navigate(item.screen.route) {
                                    popUpTo(navController.graph.findStartDestination().id) {
                                        saveState = true
                                    }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            }
                        )
                    }
                }
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
                    }
                )
            }
            composable(Screen.History.route) {
                HistoryScreen(
                    onEventClick = { eventId ->
                        navController.navigate(Screen.EventDetail.createRoute(eventId))
                    }
                )
            }
            composable(Screen.Settings.route) {
                SettingsScreen()
            }
            composable(
                route = Screen.EventDetail.route,
                arguments = listOf(navArgument("eventId") { type = NavType.LongType })
            ) {
                EventDetailScreen(
                    onBack = { navController.popBackStack() },
                    onAddRecord = { eventId ->
                        navController.navigate(Screen.AddRecord.createRoute(eventId))
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
        }
    }
}
