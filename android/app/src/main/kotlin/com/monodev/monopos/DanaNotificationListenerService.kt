package com.monodev.monopos

import android.app.Notification
import android.os.Handler
import android.os.Looper
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import org.json.JSONObject

/**
 * Selalu mendengarkan notifikasi dari aplikasi DANA (consumer & kasir).
 *
 * Service ini di-bind oleh sistem Android (lihat AndroidManifest) dan tetap
 * menerima notifikasi saat aplikasi di background. Setiap event disimpan ke
 * queue lokal lalu diteruskan ke Dart lewat EventChannel.
 */
class DanaNotificationListenerService : NotificationListenerService() {
    companion object {
        private const val TAG = "DanaListener"

        @Volatile
        var isConnected: Boolean = false
            private set
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        isConnected = true
        Log.i(TAG, "Listener connected")
        captureActiveNotifications()
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        isConnected = false
        Log.i(TAG, "Listener disconnected")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return
        handleNotification(sbn)
    }

    private fun captureActiveNotifications() {
        try {
            val active = activeNotifications ?: return
            val cutoff = System.currentTimeMillis() - 10 * 60 * 1000L

            active
                .filter { it.postTime >= cutoff }
                .sortedBy { it.postTime }
                .takeLast(20)
                .forEach { handleNotification(it) }
        } catch (e: Exception) {
            Log.w(TAG, "Gagal membaca active notifications", e)
        }
    }

    private fun handleNotification(sbn: StatusBarNotification) {
        try {
            val allowed = DanaListenerBridge.getPackages(this)
            if (!allowed.contains(sbn.packageName)) return

            val extras = sbn.notification?.extras ?: return

            val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString().orEmpty()
            val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString().orEmpty()
            val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString().orEmpty()
            val subText = extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString().orEmpty()
            val lines = extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)
                ?.joinToString(" ") { it.toString() }
                .orEmpty()

            val body = listOf(text, bigText, subText, lines)
                .filter { it.isNotBlank() }
                .distinct()
                .joinToString(" ")

            if (title.isBlank() && body.isBlank()) return

            val event = JSONObject().apply {
                put("key", "${sbn.key}|${sbn.postTime}")
                put("packageName", sbn.packageName)
                put("title", title)
                put("body", body)
                put("postedAt", sbn.postTime)
                put("capturedAt", System.currentTimeMillis())
            }

            DanaListenerBridge.store(this, event)

            val sink = DanaListenerBridge.eventSink
            if (sink != null) {
                val payload = DanaListenerBridge.toMap(event)
                Handler(Looper.getMainLooper()).post { sink(payload) }
            }

            Log.d(TAG, "Captured notification from ${sbn.packageName}")
        } catch (e: Exception) {
            Log.w(TAG, "Gagal memproses notifikasi", e)
        }
    }
}
