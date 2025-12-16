import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AlertService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // We use 'ic_launcher' because you just pasted it into the drawable folder
    const androidSettings = AndroidInitializationSettings('ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    
    await _notifications.initialize(settings);
  }

  static Future<void> showDangerAlert(String title, String body) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'danger_channel', 
      'Danger Alerts', 
      channelDescription: 'Alerts for detected phishing threats',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFFFF0000), 
      playSound: true,
      enableVibration: true,
      icon: 'ic_launcher', // This now matches the file in res/drawable/
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecond, 
      title,
      body,
      details,
    );
  }
}