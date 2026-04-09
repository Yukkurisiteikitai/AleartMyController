package com.example.aleartmycontroller.ui.navigation

/** アプリ内ルート定義 */
sealed class Screen(val route: String) {
    data object EventList   : Screen("event_list")
    data object History     : Screen("history")
    data object Settings    : Screen("settings")

    data object EventDetail : Screen("event_detail/{eventId}") {
        fun createRoute(eventId: Long) = "event_detail/$eventId"
    }
    data object AddRecord   : Screen("add_record/{eventId}") {
        fun createRoute(eventId: Long) = "add_record/$eventId"
    }
}
