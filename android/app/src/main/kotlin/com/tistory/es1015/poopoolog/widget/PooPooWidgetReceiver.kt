package com.tistory.es1015.poopoolog.widget

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.glance.appwidget.updateAll
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.util.Calendar

class PooPooWidgetReceiver : HomeWidgetGlanceWidgetReceiver<PooPooWidget>() {

    override val glanceAppWidget = PooPooWidget()

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        scheduleMidnightReset(context)
    }

    override fun onDisabled(context: Context) {
        cancelMidnightReset(context)
        super.onDisabled(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_MIDNIGHT_RESET) {
            val result = goAsync()
            CoroutineScope(Dispatchers.IO).launch {
                try {
                    glanceAppWidget.updateAll(context)
                } finally {
                    result.finish()
                }
            }
        }
    }

    companion object {
        const val ACTION_MIDNIGHT_RESET = "com.tistory.es1015.poopoolog.MIDNIGHT_RESET"
        private const val ALARM_REQUEST_CODE = 9001

        fun scheduleMidnightReset(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val pendingIntent = midnightPendingIntent(context, PendingIntent.FLAG_UPDATE_CURRENT) ?: return
            val midnight = Calendar.getInstance().apply {
                add(Calendar.DAY_OF_YEAR, 1)
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            alarmManager.setRepeating(
                AlarmManager.RTC,
                midnight.timeInMillis,
                AlarmManager.INTERVAL_DAY,
                pendingIntent,
            )
        }

        private fun cancelMidnightReset(context: Context) {
            val pi = midnightPendingIntent(context, PendingIntent.FLAG_NO_CREATE) ?: return
            (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(pi)
        }

        private fun midnightPendingIntent(context: Context, flags: Int): PendingIntent? =
            PendingIntent.getBroadcast(
                context,
                ALARM_REQUEST_CODE,
                Intent(context, PooPooWidgetReceiver::class.java).apply {
                    action = ACTION_MIDNIGHT_RESET
                },
                flags or PendingIntent.FLAG_IMMUTABLE,
            )
    }
}
