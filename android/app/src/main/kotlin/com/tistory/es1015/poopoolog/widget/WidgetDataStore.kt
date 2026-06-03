package com.tistory.es1015.poopoolog.widget

import android.content.SharedPreferences

object WidgetDataStore {

    /// 홈 위젯에 표시할 데이터 모델.
    /// todayRecords: 오늘 방문 기록 리스트 (시간 "HH:mm", 기분 색상 hex 쌍).
    data class WidgetData(
        val visitCount: Int,
        val lastTime: String,
        val lastMoodColor: String,
        val todayRecords: List<Pair<String, String>>,
    )

    /// SharedPreferences에서 위젯 데이터를 읽어 WidgetData로 파싱한다.
    fun read(prefs: SharedPreferences): WidgetData = WidgetData(
        visitCount = prefs.getString("visit_count", "0")?.toIntOrNull() ?: 0,
        lastTime = prefs.getString("last_time", "") ?: "",
        lastMoodColor = prefs.getString("last_mood_color", "") ?: "",
        todayRecords = prefs.getString("today_records", "")
            ?.split(",")
            ?.filter { it.isNotEmpty() }
            ?.mapNotNull { entry ->
                val parts = entry.split("|")
                if (parts.size == 2) Pair(parts[0], parts[1]) else null
            } ?: emptyList(),
    )
}
