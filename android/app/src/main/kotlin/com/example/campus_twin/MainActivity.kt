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

    /** Returns today's total foreground screen time in fractional hours. */
    private fun getTodayScreenTimeHours(): Double {
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val cal = Calendar.getInstance()
        // Start of today (midnight)
        cal.set(Calendar.HOUR_OF_DAY, 0)
        cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)
        val startMs = cal.timeInMillis
        val endMs   = System.currentTimeMillis()

        val stats = usm.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY, startMs, endMs
        ) ?: return 0.0

        val totalMs = stats.sumOf { it.totalTimeInForeground }
        return totalMs / 3_600_000.0   // ms → hours
    }
}
