package com.washslender.app

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.graphics.Color
import android.os.Build

class App : Application() {
    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java) ?: return
            // Only create if it doesn't already exist so we never downgrade importance.
            if (manager.getNotificationChannel("high_importance_channel") != null) return

            val channel = NotificationChannel(
                "high_importance_channel",
                "وش سلندر",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "إشعارات تطبيق وش سلندر"
                enableVibration(true)
                enableLights(true)
                lightColor = Color.parseColor("#FF1565C0")
            }
            manager.createNotificationChannel(channel)
        }
    }
}
