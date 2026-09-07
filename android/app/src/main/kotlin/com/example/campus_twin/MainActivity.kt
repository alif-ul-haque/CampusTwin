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
                    "getScreenTimeWeek" -> {
                        if (!hasUsageAccess()) {
                            result.success(emptyList<Double>())
                        } else {
                            result.success(getWeekScreenTimeHours())
                        }
                    }
                    "getScreenTimeDebug" -> result.success(getScreenTimeDebug())
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
        val cal = Calendar.getInstance()
        cal.set(Calendar.HOUR_OF_DAY, 0)
        cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)
        return screenHoursFor(cal.timeInMillis, System.currentTimeMillis())
    }

    /**
     * Returns true interactive screen time in fractional hours for each day of
     * the current week, indexed Monday (0) through Sunday (6). Days that come
     * after today (or have no usage data yet) report 0.0.
     */
    private fun getWeekScreenTimeHours(): List<Double> {
        val today = Calendar.getInstance()
        today.set(Calendar.HOUR_OF_DAY, 0)
        today.set(Calendar.MINUTE, 0)
        today.set(Calendar.SECOND, 0)
        today.set(Calendar.MILLISECOND, 0)
        val todayStartMs = today.timeInMillis
        val nowMs = System.currentTimeMillis()

        // Monday of the current week (Calendar.DAY_OF_WEEK: SUNDAY=1, MONDAY=2…)
        val daysSinceMonday = (today.get(Calendar.DAY_OF_WEEK) + 5) % 7
        val mondayStartMs = todayStartMs - daysSinceMonday * 86_400_000L

        return List(7) { i ->
            val dayStartMs = mondayStartMs + i * 86_400_000L
            if (dayStartMs >= nowMs) 0.0
            else screenHoursFor(dayStartMs, minOf(dayStartMs + 86_400_000L, nowMs))
        }
    }

    /**
     * Real-time diagnostic so we can see exactly what the device is reporting
     * instead of guessing. Returns access state, how many usage events were
     * delivered today, which event types they had, and today's computed hours.
     */
    private fun getScreenTimeDebug(): Map<String, Any?> {
        val out = mutableMapOf<String, Any?>()
        out["has_access"] = hasUsageAccess()
        val endMs = System.currentTimeMillis()
        val cal = Calendar.getInstance()
        cal.set(Calendar.HOUR_OF_DAY, 0)
        cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)
        val startMs = cal.timeInMillis

        var count = 0
        var firstTs = 0L
        var lastTs = 0L
        val typeCounts = mutableMapOf<Int, Int>()
        if (hasUsageAccess()) {
            val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val events = usm.queryEvents(startMs, endMs)
            while (events.hasNextEvent()) {
                val event = android.app.usage.UsageEvents.Event()
                events.getNextEvent(event)
                count++
                typeCounts[event.eventType] = (typeCounts[event.eventType] ?: 0) + 1
                if (firstTs == 0L) firstTs = event.timeStamp
                lastTs = event.timeStamp
            }
        }
        out["events_today"] = count
        out["type_counts"] = typeCounts
        out["first_ts"] = firstTs
        out["last_ts"] = lastTs
        out["today_hours"] = if (hasUsageAccess()) screenHoursFor(startMs, endMs) else 0.0
        return out
    }

    /**
     * Interactive screen time between [startMs] and [endMs], in fractional hours.
     *
     * This reconstructs true foreground time from foreground/background app
     * usage events, the same primitives Android's own Digital Wellbeing
     * dashboard is built on. It deliberately avoids relying only on
     * SCREEN_INTERACTIVE / SCREEN_NON_INTERACTIVE (types 15/16): many OEM
     * skins (MIUI, ColorOS, some Samsung builds with aggressive battery
     * optimization) never deliver those through UsageEvents, which silently
     * made the metric always 0 even with Usage Access granted.
     *
     * Two event families represent app foreground state:
     *   - MOVE_TO_FOREGROUND / MOVE_TO_BACKGROUND   (types 9/10, modern)
     *   - ACTIVITY_RESUMED  / ACTIVITY_PAUSED       (types 1/2, older OEMs)
     * Some devices emit 1/2 instead of 9/10, so we pick whichever family is
     * actually present in the stream (never mixing, to avoid double counting).
     */
    private fun screenHoursFor(startMs: Long, endMs: Long): Double {
        if (startMs >= endMs) return 0.0
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager

        // Drain the cursor into a list so we can inspect the stream once.
        val events = usm.queryEvents(startMs, endMs)
        val all = mutableListOf<android.app.usage.UsageEvents.Event>()
        while (events.hasNextEvent()) {
            val event = android.app.usage.UsageEvents.Event()
            events.getNextEvent(event)
            all.add(event)
        }

        val MODE_FG = android.app.usage.UsageEvents.Event.MOVE_TO_FOREGROUND   // 9
        val MODE_BG = android.app.usage.UsageEvents.Event.MOVE_TO_BACKGROUND   // 10
        val RESUMED = android.app.usage.UsageEvents.Event.ACTIVITY_RESUMED     // 1
        val PAUSED  = android.app.usage.UsageEvents.Event.ACTIVITY_PAUSED      // 2

        val usesMove = all.any { it.eventType == MODE_FG || it.eventType == MODE_BG }
        val fgType = if (usesMove) MODE_FG else RESUMED
        val bgType = if (usesMove) MODE_BG else PAUSED

        var totalMs = 0L
        // Track the last foreground time per package, since multiple apps can
        // have overlapping "sessions" queued up in the event stream.
        val foregroundSince = HashMap<String, Long>()

        for (event in all) {
            val pkg = event.packageName ?: continue
            when (event.eventType) {
                fgType -> foregroundSince[pkg] = event.timeStamp
                bgType -> {
                    val start = foregroundSince.remove(pkg)
                    if (start != null) {
                        val diff = event.timeStamp - start
                        if (diff > 0) totalMs += diff
                    }
                    // If there's no matching foreground event, this app's
                    // session actually began before our query window (e.g.
                    // before midnight, from launcher/system UI sitting in the
                    // foreground overnight). We have no way to know the real
                    // start time, so we deliberately skip it instead of
                    // guessing "since midnight" — that guess was exactly what
                    // caused a bogus ~0.5-0.6h baseline to appear every day
                    // before any real usage had happened.
                }
            }
        }

        // Any app still in the foreground right now (or at endMs) keeps
        // accumulating time until the window's end.
        for (start in foregroundSince.values) {
            val diff = endMs - start
            if (diff > 0) totalMs += diff
        }

        var hours = totalMs / 3_600_000.0
        if (hours > 24.0) hours = 24.0
        return hours
    }
}