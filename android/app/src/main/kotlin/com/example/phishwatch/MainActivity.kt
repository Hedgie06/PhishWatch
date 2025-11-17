package com.example.phishwatch

import android.content.Intent
import android.provider.Settings
import android.util.Log
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "fyp.notification/methods"
    private val EVENT_CHANNEL = "fyp.notification/events"

    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 🔹 Event channel: for sending notifications to Flutter
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                    eventSink = sink
                    NotifListenerService.eventSinkSupplier = { eventSink }
                    if (eventSink == null) {
                        Log.w("PhishWatch", "⚠️ EventSink still null, reinitializing later")
                    } else {
                        Log.i("PhishWatch", "✅ EventSink connected to Flutter")
                    }
                    Log.i("PhishWatch", "EventChannel listening started ✅")
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    NotifListenerService.eventSinkSupplier = { null }
                }
            }
        )

        // 🔹 Method channel: for controlling service and permissions
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isListenerEnabled" -> {
                    val enabled = NotificationManagerCompat.getEnabledListenerPackages(this)
                        .contains(packageName)
                    result.success(enabled)
                }
                "openListenerSettings" -> {
                    val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(null)
                }
                "startService" -> {
                    val intent = Intent(this, NotifListenerService::class.java)
                    startService(intent)
                    result.success(null)
                }
                "stopService" -> {
                    val intent = Intent(this, NotifListenerService::class.java)
                    stopService(intent)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
