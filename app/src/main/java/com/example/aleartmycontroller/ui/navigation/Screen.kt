package com.example.aleartmycontroller.ui.navigation

/** アプリ内ルート定義 */
sealed class Screen(val route: String) {
    data object EventList   : Screen("event_list")
    data object History     : Screen("history")
    data object RecordList  : Screen("record_list?eventId={eventId}") {
        fun createRoute(eventId: Long? = null): String = 
            if (eventId != null) "record_list?eventId=$eventId" else "record_list"
    }
    data object Settings    : Screen("settings")

    data object EventDetail : Screen("event_detail/{eventId}") {
        fun createRoute(eventId: Long) = "event_detail/$eventId"
    }
    data object AddRecord   : Screen("add_record/{eventId}") {
        fun createRoute(eventId: Long) = "add_record/$eventId"
    }

    data object RecordDetail : Screen("record_detail/{recordId}") {
        fun createRoute(recordId: Long) = "record_detail/$recordId"
    }
}
