package com.tistory.es1015.poopoolog.widget

import android.content.SharedPreferences
import io.mockk.every
import io.mockk.mockk
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

/**
 * WidgetDataStore.read() — SharedPreferences 파싱 단위 테스트
 *
 * home_widget Flutter 패키지는 "HomeWidgetPreferences" SharedPreferences에
 * 모든 값을 String으로 저장한다. 이 테스트는 각 키의 파싱 로직을 검증한다.
 *
 * today_records 포맷: "HH:mm|#COLOR,HH:mm|#COLOR,..."
 */
class WidgetDataStoreTest {

    private lateinit var prefs: SharedPreferences

    @Before
    fun setUp() {
        prefs = mockk(relaxed = true)
        every { prefs.getString(any(), any()) } answers { secondArg() }
    }

    // ──────────────────────────────────────────────────────────────────────
    // visitCount 파싱
    // ──────────────────────────────────────────────────────────────────────

    @Test
    fun `visitCount가 숫자 문자열이면 Int로 변환`() {
        every { prefs.getString("visit_count", "0") } returns "5"
        val data = WidgetDataStore.read(prefs)
        assertEquals(5, data.visitCount)
    }

    @Test
    fun `visitCount 기본값(null) 처리 — 0 반환`() {
        every { prefs.getString("visit_count", "0") } returns null
        val data = WidgetDataStore.read(prefs)
        assertEquals(0, data.visitCount)
    }

    @Test
    fun `visitCount 빈 문자열 — 0 반환`() {
        every { prefs.getString("visit_count", "0") } returns ""
        val data = WidgetDataStore.read(prefs)
        assertEquals(0, data.visitCount)
    }

    @Test
    fun `visitCount 숫자가 아닌 문자열 — 0 반환`() {
        every { prefs.getString("visit_count", "0") } returns "abc"
        val data = WidgetDataStore.read(prefs)
        assertEquals(0, data.visitCount)
    }

    @Test
    fun `visitCount "0" — 0 반환`() {
        every { prefs.getString("visit_count", "0") } returns "0"
        val data = WidgetDataStore.read(prefs)
        assertEquals(0, data.visitCount)
    }

    // ──────────────────────────────────────────────────────────────────────
    // lastTime 파싱
    // ──────────────────────────────────────────────────────────────────────

    @Test
    fun `lastTime 정상 값 그대로 반환`() {
        every { prefs.getString("last_time", "") } returns "14:32"
        val data = WidgetDataStore.read(prefs)
        assertEquals("14:32", data.lastTime)
    }

    @Test
    fun `lastTime null이면 빈 문자열`() {
        every { prefs.getString("last_time", "") } returns null
        val data = WidgetDataStore.read(prefs)
        assertEquals("", data.lastTime)
    }

    @Test
    fun `lastTime 빈 문자열 그대로 반환`() {
        every { prefs.getString("last_time", "") } returns ""
        val data = WidgetDataStore.read(prefs)
        assertEquals("", data.lastTime)
    }

    // ──────────────────────────────────────────────────────────────────────
    // lastMoodColor
    // ──────────────────────────────────────────────────────────────────────

    @Test
    fun `lastMoodColor 정상 반환`() {
        every { prefs.getString("last_mood_color", "") } returns "#3DA06C"
        val data = WidgetDataStore.read(prefs)
        assertEquals("#3DA06C", data.lastMoodColor)
    }

    @Test
    fun `lastMoodColor null이면 빈 문자열`() {
        every { prefs.getString("last_mood_color", "") } returns null
        val data = WidgetDataStore.read(prefs)
        assertEquals("", data.lastMoodColor)
    }

    // ──────────────────────────────────────────────────────────────────────
    // todayRecords 파싱 ("HH:mm|#COLOR,..." 형식)
    // ──────────────────────────────────────────────────────────────────────

    @Test
    fun `todayRecords 빈 문자열이면 빈 리스트`() {
        every { prefs.getString("today_records", "") } returns ""
        val data = WidgetDataStore.read(prefs)
        assertTrue(data.todayRecords.isEmpty())
    }

    @Test
    fun `todayRecords null이면 빈 리스트`() {
        every { prefs.getString("today_records", "") } returns null
        val data = WidgetDataStore.read(prefs)
        assertTrue(data.todayRecords.isEmpty())
    }

    @Test
    fun `todayRecords 단일 기록 파싱`() {
        every { prefs.getString("today_records", "") } returns "14:32|#3DA06C"
        val data = WidgetDataStore.read(prefs)
        assertEquals(1, data.todayRecords.size)
        assertEquals(Pair("14:32", "#3DA06C"), data.todayRecords[0])
    }

    @Test
    fun `todayRecords 콤마 구분 3개 기록 파싱`() {
        every { prefs.getString("today_records", "") } returns "09:00|#3DA06C,13:30|#CC7D30,20:15|#C64848"
        val data = WidgetDataStore.read(prefs)
        assertEquals(3, data.todayRecords.size)
        assertEquals(Pair("09:00", "#3DA06C"), data.todayRecords[0])
        assertEquals(Pair("13:30", "#CC7D30"), data.todayRecords[1])
        assertEquals(Pair("20:15", "#C64848"), data.todayRecords[2])
    }

    @Test
    fun `todayRecords 기분 없는 기록 — 색상 없음(#8CA896) 포함`() {
        every { prefs.getString("today_records", "") } returns "08:00|#8CA896"
        val data = WidgetDataStore.read(prefs)
        assertEquals(Pair("08:00", "#8CA896"), data.todayRecords[0])
    }

    @Test
    fun `todayRecords 빈 항목(연속 콤마)은 필터링됨`() {
        every { prefs.getString("today_records", "") } returns "09:00|#3DA06C,,13:00|#CC7D30"
        val data = WidgetDataStore.read(prefs)
        assertEquals(2, data.todayRecords.size)
    }

    @Test
    fun `todayRecords 구분자(|) 없는 잘못된 항목은 무시됨`() {
        every { prefs.getString("today_records", "") } returns "09:00|#3DA06C,INVALID,13:00|#CC7D30"
        val data = WidgetDataStore.read(prefs)
        assertEquals(2, data.todayRecords.size)
    }

    // ──────────────────────────────────────────────────────────────────────
    // 전체 WidgetData 구조
    // ──────────────────────────────────────────────────────────────────────

    @Test
    fun `모든 키가 정상값일 때 WidgetData 전체 검증`() {
        every { prefs.getString("visit_count", "0") } returns "3"
        every { prefs.getString("last_time", "") } returns "20:15"
        every { prefs.getString("last_mood_color", "") } returns "#C64848"
        every { prefs.getString("today_records", "") } returns "09:00|#3DA06C,13:30|#CC7D30,20:15|#C64848"

        val data = WidgetDataStore.read(prefs)

        assertEquals(3, data.visitCount)
        assertEquals("20:15", data.lastTime)
        assertEquals("#C64848", data.lastMoodColor)
        assertEquals(3, data.todayRecords.size)
        assertEquals(Pair("09:00", "#3DA06C"), data.todayRecords[0])
        assertEquals(Pair("20:15", "#C64848"), data.todayRecords[2])
    }

    @Test
    fun `모든 키가 기본값(빈 상태)일 때 WidgetData 검증`() {
        val data = WidgetDataStore.read(prefs)

        assertEquals(0, data.visitCount)
        assertEquals("", data.lastTime)
        assertEquals("", data.lastMoodColor)
        assertTrue(data.todayRecords.isEmpty())
    }
}
