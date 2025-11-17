package com.example.phishwatch

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.os.Bundle
import android.util.Log
import io.flutter.FlutterInjector
import io.flutter.plugin.common.EventChannel   // ✅ ADD THIS IMPORT


class NotifListenerService : NotificationListenerService() {
    companion object {
        var eventSinkSupplier: (() -> EventChannel.EventSink?)? = null
    }

    override fun onCreate() {
        super.onCreate()
        Log.i("NotifListener", "🟢 Service created")
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.i("NotifListener", "✅ Listener connected")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        try {
            val pkg = sbn.packageName ?: "unknown"
            val extras: Bundle = sbn.notification.extras
            val title = extras.getString("android.title") ?: ""
            val textObj = extras.getCharSequence("android.text")
            val text = textObj?.toString() ?: ""

            Log.i("NotifListener", "📩 Notification received from: $pkg")
            Log.i("NotifListener", "   Title: $title")
            Log.i("NotifListener", "   Text: $text")

            if (pkg == "org.telegram.messenger" || pkg == "org.telegram.messenger.web") {
                val map = HashMap<String, Any?>()
                map["app"] = "Telegram"
                map["title"] = title
                map["text"] = text
                val sink = eventSinkSupplier?.invoke()
                if (sink == null) {
                    Log.e("NotifListener", "❌ EventSink is null — Flutter not connected")
                } else {
                    sink.success(map)
                    Log.i("NotifListener", "✅ Sent Telegram message to Flutter")
                }
            }
        } catch (e: Exception) {
            Log.e("NotifListener", "❌ Error processing notification", e)
        }
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.w("NotifListener", "⚠️ Listener disconnected")
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        Log.i("NotifListener", "🗑️ Notification removed from: ${sbn.packageName}")
    }
}
