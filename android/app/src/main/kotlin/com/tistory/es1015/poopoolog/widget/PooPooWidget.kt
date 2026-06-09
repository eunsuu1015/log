package com.tistory.es1015.poopoolog.widget

import android.content.Context
import android.content.Intent
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.LocalSize
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.appWidgetBackground
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.currentState
import androidx.glance.unit.ColorProvider
import com.tistory.es1015.poopoolog.MainActivity
import com.tistory.es1015.poopoolog.R
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition

// ── 다크·라이트 모드 대응 색상 ────────────────────────────────────────────────
// Glance 1.0.0은 ColorProvider(day, night) 미지원.
// values/widget_colors.xml + values-night/widget_colors.xml 리소스로 분기한다.
private val COLOR_SURFACE             = ColorProvider(R.color.widget_surface)
private val COLOR_ON_SURFACE          = ColorProvider(R.color.widget_on_surface)
private val COLOR_ON_SURFACE_VARIANT  = ColorProvider(R.color.widget_on_surface_variant)
private val COLOR_PRIMARY             = ColorProvider(R.color.widget_primary)
private val COLOR_ON_PRIMARY          = ColorProvider(R.color.widget_on_primary)
private val COLOR_MOOD_NONE           = Color(0xFF8CA896)  // AppTheme.moodNone (모드 무관)

class PooPooWidget : GlanceAppWidget() {

    // HomeWidgetGlanceWidgetReceiver.onUpdate가 상태를 갱신하려면 반드시 필요.
    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    companion object {
        private val SMALL = DpSize(57.dp, 57.dp)
        private val MEDIUM = DpSize(120.dp, 57.dp)
    }

    override val sizeMode = SizeMode.Responsive(setOf(SMALL, MEDIUM))

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val prefs = currentState<HomeWidgetGlanceState>().preferences
            val data = WidgetDataStore.read(prefs)
            val size = LocalSize.current
            if (size.width >= 120.dp) Layout2x1(context, data)
            else Layout1x1(context, data)
        }
    }
}

// ── 액션 ─────────────────────────────────────────────────────────────────────

private fun openAppAction(context: Context) = actionStartActivity(
    Intent(context, MainActivity::class.java).apply {
        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
    }
)

private fun openRecordAction(context: Context) = actionStartActivity(
    Intent(context, MainActivity::class.java).apply {
        putExtra("open_record", true)
        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
    }
)

// ── 유틸 ──────────────────────────────────────────────────────────────────────

private fun parseColor(hex: String): Color = try {
    Color(android.graphics.Color.parseColor(hex))
} catch (e: Exception) {
    COLOR_MOOD_NONE
}

// ── 공통 컴포넌트 ─────────────────────────────────────────────────────────────

/// 기록 입력 화면으로 바로 진입하는 원형 + 버튼.
@Composable
private fun AddButton(context: Context) {
    Box(
        modifier = GlanceModifier
            .size(32.dp)
            .background(COLOR_PRIMARY)
            .cornerRadius(16.dp)
            .clickable(openRecordAction(context)),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = "+",
            style = TextStyle(
                fontSize = 20.sp,
                fontWeight = FontWeight.Bold,
                color = COLOR_ON_PRIMARY,
            ),
        )
    }
}

/// 기분 색상 도트 (원형 8dp).
@Composable
private fun MoodDot(colorHex: String) {
    Box(
        modifier = GlanceModifier
            .size(8.dp)
            .background(parseColor(colorHex))
            .cornerRadius(4.dp),
    ) {}
}

// ── 레이아웃 1×1: 오늘 / N회 / + ─────────────────────────────────────────────

@Composable
private fun Layout1x1(context: Context, data: WidgetDataStore.WidgetData) {
    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .appWidgetBackground()
            .background(COLOR_SURFACE)
            .cornerRadius(16.dp)
            .clickable(openAppAction(context)),
        contentAlignment = Alignment.Center,
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            if (data.visitCount > 0) {
                Text(
                    text = "${data.visitCount}회",
                    style = TextStyle(
                        fontSize = 20.sp,
                        fontWeight = FontWeight.Bold,
                        color = COLOR_ON_SURFACE,
                    ),
                )
            } else {
                Text(
                    text = "안 감",
                    style = TextStyle(fontSize = 13.sp, color = COLOR_ON_SURFACE_VARIANT),
                )
            }
            Spacer(GlanceModifier.height(6.dp))
            AddButton(context)
        }
    }
}

// ── 레이아웃 2×1: 오늘 / N회 / 시간 + 기분도트 / + ───────────────────────────

@Composable
private fun Layout2x1(context: Context, data: WidgetDataStore.WidgetData) {
    Row(
        modifier = GlanceModifier
            .fillMaxSize()
            .appWidgetBackground()
            .background(COLOR_SURFACE)
            .cornerRadius(16.dp)
            .padding(horizontal = 20.dp)
            .clickable(openAppAction(context)),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(modifier = GlanceModifier.defaultWeight(), horizontalAlignment = Alignment.CenterHorizontally) {
            if (data.visitCount > 0) {
                Text(
                    text = "${data.visitCount}회",
                    style = TextStyle(
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold,
                        color = COLOR_ON_SURFACE,
                    ),
                )
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = data.lastTime,
                        style = TextStyle(fontSize = 11.sp, color = COLOR_ON_SURFACE_VARIANT),
                    )
                    if (data.lastMoodColor.isNotEmpty()) {
                        Spacer(GlanceModifier.width(8.dp))
                        MoodDot(data.lastMoodColor)
                    }
                }
            } else {
                Text(
                    text = "안 다녀옴",
                    style = TextStyle(fontSize = 13.sp, color = COLOR_ON_SURFACE_VARIANT),
                )
            }
        }
        Spacer(GlanceModifier.width(8.dp))
        AddButton(context)
    }
}

