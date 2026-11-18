package com.nexmile.rider

import android.annotation.SuppressLint
import android.app.KeyguardManager
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * The rider surface, plus the few phone settings an order alert depends on
 * that no Flutter plugin covers cleanly: showing over the lock screen,
 * full-screen intents, battery optimisation, and the phone's brand for the
 * autostart step. All on one channel, `nexmile/device`.
 */
class MainActivity : FlutterActivity() {

    /**
     * Opened by a new-order alert while the phone is locked: over the lock
     * screen and screen on from the very first frame, the way a call is.
     *
     * Waiting for Flutter to draw the order card first is too late. Android
     * decides whether to switch the display on when it starts the activity,
     * and by the time Dart asks, the app is already sitting dark behind the
     * lock screen.
     */
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (isOrderAlert(intent)) wakeForOrder()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (isOrderAlert(intent)) wakeForOrder()
    }

    /**
     * The alert's full-screen intent carries its push data in the `payload`
     * extra (flutter_local_notifications), and an order offer's says so.
     */
    private fun isOrderAlert(intent: Intent?): Boolean {
        val payload = intent?.getStringExtra("payload") ?: return false
        return payload.contains("ORDER_OFFER")
    }

    private fun wakeForOrder() {
        showOverLockScreen(true)
        wakeScreen()
    }

    /**
     * Switches the display on for a moment. The backup for when the alert
     * cannot open the app over the lock screen (Android 14 without the
     * full-screen permission, or a phone that ignores it): the rider at least
     * sees the alert on a lit lock screen instead of a dark one.
     */
    @Suppress("DEPRECATION")
    private fun wakeScreen() {
        val power = getSystemService(Context.POWER_SERVICE) as PowerManager
        if (power.isInteractive) return
        power.newWakeLock(
            PowerManager.SCREEN_BRIGHT_WAKE_LOCK or
                PowerManager.ACQUIRE_CAUSES_WAKEUP or
                PowerManager.ON_AFTER_RELEASE,
            "nexmile:new-order",
        ).acquire(15_000L)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "nexmile/device")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "showOverLockScreen" -> {
                        showOverLockScreen(call.arguments as? Boolean ?: false)
                        result.success(null)
                    }
                    "wakeScreen" -> {
                        wakeScreen()
                        result.success(null)
                    }
                    "canUseFullScreenIntent" -> result.success(canUseFullScreenIntent())
                    "openFullScreenIntentSettings" -> {
                        openFullScreenIntentSettings()
                        result.success(null)
                    }
                    "isIgnoringBatteryOptimizations" ->
                        result.success(isIgnoringBatteryOptimizations())
                    "requestIgnoreBatteryOptimizations" -> {
                        requestIgnoreBatteryOptimizations()
                        result.success(null)
                    }
                    "openAppSettings" -> {
                        openAppSettings()
                        result.success(null)
                    }
                    "manufacturer" -> result.success(Build.MANUFACTURER ?: "")
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Lets an incoming order show over the lock screen and wake the display,
     * the way a call does. Switched on only while an offer card is up and off
     * again after, so the rest of the app never shows to someone holding a
     * locked phone.
     */
    private fun showOverLockScreen(on: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(on)
            setTurnScreenOn(on)
            if (on) {
                val keyguard = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
                keyguard.requestDismissKeyguard(this, null)
            }
        } else {
            @Suppress("DEPRECATION")
            val flags = WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            if (on) window.addFlags(flags) else window.clearFlags(flags)
        }
    }

    /** Android 14 stopped granting this to apps that are not dialers or alarms. */
    private fun canUseFullScreenIntent(): Boolean {
        if (Build.VERSION.SDK_INT < 34) return true
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        return manager.canUseFullScreenIntent()
    }

    private fun openFullScreenIntentSettings() {
        if (Build.VERSION.SDK_INT >= 34) {
            startActivity(
                Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT)
                    .setData(Uri.parse("package:$packageName"))
            )
        } else {
            openAppSettings()
        }
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        val power = getSystemService(Context.POWER_SERVICE) as PowerManager
        return power.isIgnoringBatteryOptimizations(packageName)
    }

    @SuppressLint("BatteryLife")
    private fun requestIgnoreBatteryOptimizations() {
        // A delivery app that is killed while the rider is online misses
        // orders, which is the case this direct request exists for.
        try {
            startActivity(
                Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                    .setData(Uri.parse("package:$packageName"))
            )
        } catch (_: Exception) {
            startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
        }
    }

    private fun openAppSettings() {
        startActivity(
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                .setData(Uri.parse("package:$packageName"))
        )
    }
}
