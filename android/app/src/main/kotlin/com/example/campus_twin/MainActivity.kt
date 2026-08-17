package com.campustwin.app

import android.accounts.AccountManager
import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity : FlutterActivity() {

    private val CHANNEL_USAGE = "campus_twin/usage_access"
    private val CHANNEL_ACCOUNTS = "campus_twin/accounts"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── Usage access + screen time ────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_USAGE)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkUsageAccess" -> result.success(hasUsageAccess())
                    "openUsageSettings" -> {
                        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                        result.success(null)
                    }
                    "getScreenTimeHours" -> {
                        if (!hasUsageAccess()) {
                            result.success(0.0)
                        } else {
                            result.success(getTodayScreenTimeHours())
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // ── Google accounts listed on this device ─────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_ACCOUNTS)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getGoogleAccounts" -> {
                        val am = getSystemService(Context.ACCOUNT_SERVICE) as AccountManager
                        val accounts = am.getAccountsByType("com.google")
                            .map { it.name }
                        result.success(accounts)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasUsageAccess(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    /** Returns today's true interactive screen time in fractional hours. */
    private fun getTodayScreenTimeHours(): Double {
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val cal = Calendar.getInstance()
        cal.set(Calendar.HOUR_OF_DAY, 0)
        cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)
        val startMs = cal.timeInMillis
        val endMs   = System.currentTimeMillis()

        val events = usm.queryEvents(startMs, endMs)
        var totalMs = 0L
        var lastInteractiveTime = 0L

        while (events.hasNextEvent()) {
            val event = android.app.usage.UsageEvents.Event()
            events.getNextEvent(event)
            
            // 15 = SCREEN_INTERACTIVE, 16 = SCREEN_NON_INTERACTIVE
            if (event.eventType == 15) {
                lastInteractiveTime = event.timeStamp
            } else if (event.eventType == 16) {
                // If we get a turn-off event before a turn-on, it means it was on since midnight
                if (lastInteractiveTime == 0L) {
                    lastInteractiveTime = startMs
                }
                val diff = event.timeStamp - lastInteractiveTime
                if (diff > 0) {
                    totalMs += diff
                }
                lastInteractiveTime = 0L
            }
        }
        
        // If the screen is still on right now
        if (lastInteractiveTime > 0) {
            val diff = endMs - lastInteractiveTime
            if (diff > 0) {
                totalMs += diff
            }
        }

        var hours = totalMs / 3_600_000.0
        if (hours > 24.0) hours = 24.0
        return hours
    }
}
