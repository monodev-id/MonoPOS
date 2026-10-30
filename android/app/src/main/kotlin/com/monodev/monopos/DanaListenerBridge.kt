package com.monodev.monopos

import android.content.ComponentName
import android.content.Context
import android.provider.Settings
import org.json.JSONArray
import org.json.JSONObject

/**
 * Penyimpanan queue notifikasi DANA + helper status akses notifikasi.
 *
 * Queue disimpan di SharedPreferences supaya notifikasi yang masuk saat Flutter
 * engine mati tetap bisa diproses ketika aplikasi dibuka kembali.
 */
object DanaListenerBridge {
    private const val PREFS = "dana_listener_prefs"
    private const val KEY_QUEUE = "notification_queue"
    private const val KEY_PACKAGES = "allowed_packages"
    private const val MAX_QUEUE = 200

    const val DEFAULT_PACKAGES = "id.dana,id.dana.kasir"

    @Volatile
    var eventSink: ((Map<String, Any>) -> Unit)? = null

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun getPackages(context: Context): List<String> {
        val raw = prefs(context).getString(KEY_PACKAGES, DEFAULT_PACKAGES) ?: DEFAULT_PACKAGES
        return raw.split(",").map { it.trim() }.filter { it.isNotEmpty() }
    }

    fun setPackages(context: Context, packages: List<String>) {
        val cleaned = packages.map { it.trim() }.filter { it.isNotEmpty() }
        val value = if (cleaned.isEmpty()) DEFAULT_PACKAGES else cleaned.joinToString(",")
        prefs(context).edit().putString(KEY_PACKAGES, value).apply()
    }

    fun hasNotificationAccess(context: Context): Boolean {
        val enabled = Settings.Secure.getString(
            context.contentResolver,
            "enabled_notification_listeners",
        ) ?: return false

        val expected = ComponentName(context, DanaNotificationListenerService::class.java)
        return enabled.split(":").any { entry ->
            ComponentName.unflattenFromString(entry) == expected
        }
    }

    @Synchronized
    fun store(context: Context, event: JSONObject) {
        val key = event.optString("key")
        if (key.isEmpty()) return

        val queue = readQueue(context)

        for (i in 0 until queue.length()) {
            if (queue.optJSONObject(i)?.optString("key") == key) return
        }

        queue.put(event)

        while (queue.length() > MAX_QUEUE) {
            queue.remove(0)
        }

        prefs(context).edit().putString(KEY_QUEUE, queue.toString()).apply()
    }

    @Synchronized
    fun pending(context: Context): List<Map<String, Any>> {
        val queue = readQueue(context)
        val result = ArrayList<Map<String, Any>>(queue.length())

        for (i in 0 until queue.length()) {
            val item = queue.optJSONObject(i) ?: continue
            result.add(toMap(item))
        }

        return result
    }

    @Synchronized
    fun ack(context: Context, keys: List<String>) {
        if (keys.isEmpty()) return

        val queue = readQueue(context)
        val kept = JSONArray()
        val ackSet = keys.toSet()

        for (i in 0 until queue.length()) {
            val item = queue.optJSONObject(i) ?: continue
            if (!ackSet.contains(item.optString("key"))) {
                kept.put(item)
            }
        }

        prefs(context).edit().putString(KEY_QUEUE, kept.toString()).apply()
    }

    private fun readQueue(context: Context): JSONArray {
        val raw = prefs(context).getString(KEY_QUEUE, "[]") ?: "[]"
        return try {
            JSONArray(raw)
        } catch (_: Exception) {
            JSONArray()
        }
    }

    fun toMap(json: JSONObject): Map<String, Any> {
        val map = HashMap<String, Any>()
        map["key"] = json.optString("key")
        map["packageName"] = json.optString("packageName")
        map["title"] = json.optString("title")
        map["body"] = json.optString("body")
        map["postedAt"] = json.optLong("postedAt")
        map["capturedAt"] = json.optLong("capturedAt")
        return map
    }
}
