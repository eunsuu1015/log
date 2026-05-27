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
 */
class WidgetDataStoreTest {

    private lateinit var prefs: SharedPreferences

    @Before
    fun setUp() {
        prefs = mockk(relaxed = true)
        // 기본값 셋업: 모든 getString 호출은 두 번째 인자(기본값) 반환
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
    // lastMoodLabel · lastMoodColor
    // ──────────────────────────────────────────────────────────────────────

    @Test
    fun `lastMoodLabel 정상 반환`() {
        every { prefs.getString("last_mood_label", "") } returns "좋음"
        val data = WidgetDataStore.read(prefs)
        assertEquals("좋음", data.lastMoodLabel)
    }

    @Test
    fun `lastMoodColor 정상 반환`() {
        every { prefs.getString("last_mood_color", "") } returns "#639922"
        val data = WidgetDataStore.read(prefs)
        assertEquals("#639922", data.lastMoodColor)
    }

    @Test
    fun `lastMoodLabel null이면 빈 문자열`() {
        every { prefs.getString("last_mood_label", "") } returns null
        val data = WidgetDataStore.read(prefs)
        assertEquals("", data.lastMoodLabel)
    }

    // ──────────────────────────────────────────────────────────────────────
    // todayDots 파싱
    // ──────────────────────────────────────────────────────────────────────

    @Test
    fun `todayDots 빈 문자열이면 빈 리스트`() {
        every { prefs.getString("today_dots", "") } returns ""
        val data = WidgetDataStore.read(prefs)
        assertTrue(data.todayDots.isEmpty())
    }

    @Test
    fun `todayDots null이면 빈 리스트`() {
        every { prefs.getString("today_dots", "") } returns null
        val data = WidgetDataStore.read(prefs)
        assertTrue(data.todayDots.isEmpty())
    }

    @Test
    fun `todayDots 단일 색상`() {
        every { prefs.getString("today_dots", "") } returns "#639922"
        val data = WidgetDataStore.read(prefs)
        assertEquals(listOf("#639922"), data.todayDots)
    }

    @Test
    fun `todayDots 콤마 구분 3개 색상`() {
        every { prefs.getString("today_dots", "") } returns "#639922,#BA7517,#E24B4A"
        val data = WidgetDataStore.read(prefs)
        assertEquals(
            listOf("#639922", "#BA7517", "#E24B4A"),
            data.todayDots,
        )
    }

    @Test
    fun `todayDots — 빈 항목은 필터링됨`() {
        every { prefs.getString("today_dots", "") } returns "#639922,,#BA7517"
        val data = WidgetDataStore.read(prefs)
        assertEquals(listOf("#639922", "#BA7517"), data.todayDots)
    }

    @Test
    fun `todayDots 5개 항목 모두 파싱`() {
        val raw = "#639922,#BA7517,#E24B4A,#B4B2A9,#639922"
        every { prefs.getString("today_dots", "") } returns raw
        val data = WidgetDataStore.read(prefs)
        assertEquals(5, data.todayDots.size)
    }

    // ──────────────────────────────────────────────────────────────────────
    // dateLabel
    // ──────────────────────────────────────────────────────────────────────

    @Test
    fun `dateLabel 정상 반환`() {
        every { prefs.getString("date_label", "") } returns "5/21"
        val data = WidgetDataStore.read(prefs)
        assertEquals("5/21", data.dateLabel)
    }

    @Test
    fun `dateLabel null이면 빈 문자열`() {
        every { prefs.getString("date_label", "") } returns null
        val data = WidgetDataStore.read(prefs)
        assertEquals("", data.dateLabel)
    }

    // ──────────────────────────────────────────────────────────────────────
    // 전체 WidgetData 구조
    // ──────────────────────────────────────────────────────────────────────

    @Test
    fun `모든 키가 정상값일 때 WidgetData 전체 검증`() {
        every { prefs.getString("visit_count", "0") } returns "3"
        every { prefs.getString("last_time", "") } returns "14:32"
        every { prefs.getString("last_mood_label", "") } returns "보통"
        every { prefs.getString("last_mood_color", "") } returns "#BA7517"
        every { prefs.getString("today_dots", "") } returns "#639922,#BA7517,#B4B2A9"
        every { prefs.getString("date_label", "") } returns "5/21"

        val data = WidgetDataStore.read(prefs)

        assertEquals(3, data.visitCount)
        assertEquals("14:32", data.lastTime)
        assertEquals("보통", data.lastMoodLabel)
        assertEquals("#BA7517", data.lastMoodColor)
        assertEquals(listOf("#639922", "#BA7517", "#B4B2A9"), data.todayDots)
        assertEquals("5/21", data.dateLabel)
    }

    @Test
    fun `모든 키가 기본값(빈 상태)일 때 WidgetData 검증`() {
        // relaxed mock이므로 기본값 반환 그대로 사용
        val data = WidgetDataStore.read(prefs)

        assertEquals(0, data.visitCount)
        assertEquals("", data.lastTime)
        assertEquals("", data.lastMoodLabel)
        assertEquals("", data.lastMoodColor)
        assertTrue(data.todayDots.isEmpty())
        assertEquals("", data.dateLabel)
    }
}
