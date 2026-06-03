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
import androidx.glance.unit.ColorProvider
import com.tistory.es1015.poopoolog.MainActivity

private val SURFACE = Color(0xFFFFFBFE.toInt())
private val COLOR_ON_SURFACE = ColorProvider(Color(0xFF1C1B1F.toInt()))
private val COLOR_ON_SURFACE_VARIANT = ColorProvider(Color(0xFF49454F.toInt()))
private val COLOR_PRIMARY = ColorProvider(Color(0xFF2D6A4F.toInt()))
private val COLOR_ON_PRIMARY = ColorProvider(Color(0xFFFFFFFF.toInt()))
private val COLOR_MOOD_NONE = Color(0xFF8CA896.toInt())

class PooPooWidget : GlanceAppWidget() {

    companion object {
        private val SMALL = DpSize(57.dp, 57.dp)
        private val MEDIUM = DpSize(120.dp, 57.dp)
        private val LARGE = DpSize(120.dp, 120.dp)
    }

    override val sizeMode = SizeMode.Responsive(setOf(SMALL, MEDIUM, LARGE))

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val data = WidgetDataStore.read(prefs)
        provideContent {
            val size = LocalSize.current
            when {
                size.height >= 120.dp -> Layout2x2(context, data)
                size.width >= 120.dp -> Layout2x1(context, data)
                else -> Layout1x1(context, data)
            }
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
            .background(SURFACE)
            .cornerRadius(16.dp)
            .clickable(openAppAction(context)),
        contentAlignment = Alignment.Center,
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                text = "오늘",
                style = TextStyle(fontSize = 9.sp, color = COLOR_ON_SURFACE_VARIANT),
            )
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
                    style = TextStyle(fontSize = 9.sp, color = COLOR_ON_SURFACE_VARIANT),
                )
            }
            Spacer(GlanceModifier.height(4.dp))
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
            .background(SURFACE)
            .cornerRadius(16.dp)
            .padding(horizontal = 12.dp)
            .clickable(openAppAction(context)),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(modifier = GlanceModifier.defaultWeight()) {
            Text(
                text = "오늘",
                style = TextStyle(fontSize = 9.sp, color = COLOR_ON_SURFACE_VARIANT),
            )
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
                        Spacer(GlanceModifier.width(6.dp))
                        MoodDot(data.lastMoodColor)
                    }
                }
            } else {
                Text(
                    text = "안 다녀왔어요",
                    style = TextStyle(fontSize = 11.sp, color = COLOR_ON_SURFACE_VARIANT),
                )
            }
        }
        Spacer(GlanceModifier.width(8.dp))
        AddButton(context)
    }
}

// ── 레이아웃 2×2: 오늘 / N회 / 전체 기록(시간 + 기분도트) / + ─────────────────

@Composable
private fun Layout2x2(context: Context, data: WidgetDataStore.WidgetData) {
    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .appWidgetBackground()
            .background(SURFACE)
            .cornerRadius(16.dp)
            .padding(12.dp)
            .clickable(openAppAction(context)),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                text = "오늘",
                modifier = GlanceModifier.defaultWeight(),
                style = TextStyle(fontSize = 10.sp, color = COLOR_ON_SURFACE_VARIANT),
            )
            AddButton(context)
        }
        Spacer(GlanceModifier.height(4.dp))
        if (data.visitCount > 0) {
            Text(
                text = "${data.visitCount}회",
                style = TextStyle(
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold,
                    color = COLOR_ON_SURFACE,
                ),
            )
            Spacer(GlanceModifier.height(6.dp))
            data.todayRecords.take(4).forEach { (time, colorHex) ->
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = time,
                        style = TextStyle(fontSize = 11.sp, color = COLOR_ON_SURFACE_VARIANT),
                    )
                    Spacer(GlanceModifier.width(6.dp))
                    MoodDot(colorHex)
                }
                Spacer(GlanceModifier.height(2.dp))
            }
        } else {
            Text(
                text = "안 다녀왔어요",
                style = TextStyle(fontSize = 11.sp, color = COLOR_ON_SURFACE_VARIANT),
            )
        }
    }
}
