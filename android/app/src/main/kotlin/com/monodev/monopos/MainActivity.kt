package com.monodev.monopos

import android.content.ComponentName
import android.content.Intent
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
                        try {
                            startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("OPEN_SETTINGS_FAILED", e.message, null)
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
}
