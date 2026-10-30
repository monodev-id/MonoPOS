package com.monodev.monopos

import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.service.notification.NotificationListenerService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val methodChannelName = "com.monodev.monopos/dana_listener"
    private val eventChannelName = "com.monodev.monopos/dana_listener/events"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasPermission" -> result.success(DanaListenerBridge.hasNotificationAccess(this))

                    "isConnected" -> result.success(DanaNotificationListenerService.isConnected)

                    "openPermissionSettings" -> {
                        if (openNotificationAccessSettings()) {
                            result.success(null)
                        } else {
                            result.error(
                                "OPEN_SETTINGS_FAILED",
                                "Pengaturan akses notifikasi tidak tersedia di perangkat ini",
                                null,
                            )
                        }
                    }

                    "openAppDetails" -> {
                        val intent = Intent(
                            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            Uri.parse("package:$packageName"),
                        )
                        if (tryStartActivity(intent)) {
                            result.success(null)
                        } else {
                            result.error("OPEN_SETTINGS_FAILED", "Info aplikasi tidak bisa dibuka", null)
                        }
                    }

                    "getPendingEvents" -> result.success(DanaListenerBridge.pending(this))

                    "ackEvents" -> {
                        val keys = call.argument<List<String>>("keys") ?: emptyList()
                        DanaListenerBridge.ack(this, keys)
                        result.success(null)
                    }

                    "setAllowedPackages" -> {
                        val packages = call.argument<List<String>>("packages") ?: emptyList()
                        DanaListenerBridge.setPackages(this, packages)
                        result.success(null)
                    }

                    "rebindService" -> {
                        try {
                            val component = ComponentName(this, DanaNotificationListenerService::class.java)
                            NotificationListenerService.requestRebind(component)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("REBIND_FAILED", e.message, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    DanaListenerBridge.eventSink = { payload -> events?.success(payload) }
                }

                override fun onCancel(arguments: Any?) {
                    DanaListenerBridge.eventSink = null
                }
            })
    }

    /**
     * Buka halaman akses notifikasi sedetail mungkin.
     *
     * Android 11+ mendukung intent langsung ke komponen listener Mono POS,
     * sehingga pengguna tidak perlu mencari di daftar panjang. Beberapa ROM
     * (mis. XOS/Infinix) menolak intent detail, jadi selalu ada fallback ke
     * daftar listener lalu ke halaman info aplikasi.
     */
    private fun openNotificationAccessSettings(): Boolean {
        val component = ComponentName(this, DanaNotificationListenerService::class.java)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val detailIntent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_DETAIL_SETTINGS).apply {
                putExtra(
                    Settings.EXTRA_NOTIFICATION_LISTENER_COMPONENT_NAME,
                    component.flattenToString(),
                )
            }

            if (tryStartActivity(detailIntent)) return true
        }

        if (tryStartActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))) return true

        return tryStartActivity(
            Intent(
                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.parse("package:$packageName"),
            ),
        )
    }

    private fun tryStartActivity(intent: Intent): Boolean {
        return try {
            startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }
}
