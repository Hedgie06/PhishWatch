import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class AlertService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(settings);
  }

  static Future<void> showDangerAlert(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'phish_alerts', // channel ID
      'Phishing Alerts', // channel name
      channelDescription: 'Alerts for detected phishing messages',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      color: Colors.red,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      0, // notification ID
      title,
      body,
      details,
    );
  }
}
