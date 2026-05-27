package com.tistory.es1015.poopoolog.widget

import android.content.SharedPreferences

object WidgetDataStore {
    data class WidgetData(
        val visitCount: Int,
        val lastTime: String,
        val lastMoodLabel: String,
        val lastMoodColor: String,
        val todayDots: List<String>,
        val dateLabel: String,
    )

    fun read(prefs: SharedPreferences): WidgetData = WidgetData(
        visitCount = prefs.getString("visit_count", "0")?.toIntOrNull() ?: 0,
        lastTime = prefs.getString("last_time", "") ?: "",
        lastMoodLabel = prefs.getString("last_mood_label", "") ?: "",
        lastMoodColor = prefs.getString("last_mood_color", "") ?: "",
        todayDots = prefs.getString("today_dots", "")
            ?.split(",")?.filter { it.isNotEmpty() } ?: emptyList(),
        dateLabel = prefs.getString("date_label", "") ?: "",
    )
}
