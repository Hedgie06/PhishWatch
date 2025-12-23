import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart'; 
import '../views/scan_result_page.dart'; 

class AlertService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          // 🔴 1. UNPACK PAYLOAD
          // Format is: "CONFIDENCE|MESSAGE"
          // Example: "0.88|Click this link..."
          
          double confidence = 0.99; // Default fallback
          String message = response.payload!;

          // Split the string by the "|" character
          final parts = response.payload!.split('|');
          if (parts.length >= 2) {
            // Parse the first part as the score
            confidence = double.tryParse(parts[0]) ?? 0.99;
            // The rest is the message (rejoined just in case the message had a | in it)
            message = parts.sublist(1).join('|');
          }

          // Navigate with the REAL confidence
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => ScanResultPage(
                message: message, 
                isPhishing: true,           
                confidence: confidence, // 🔴 2. PASS REAL SCORE
              ),
            ),
          );
        }
      },
    );
  }

  // 🔴 3. ADDED 'confidence' PARAMETER
  static Future<void> showDangerAlert(String title, String body, double confidence) async {
    await initialize();

    // 🔴 UPDATED VIBRATION: 3 LONG VIBRATIONS
    // Wait 0ms, Vibrate 1000ms, Pause 500ms, Vibrate 1000ms, Pause 500ms, Vibrate 1000ms
    final Int64List vibrationPattern = Int64List.fromList([0, 1000, 500, 1000, 500, 1000]);

    String detailedMessage = 
        "<b>THREAT LEVEL: HIGH</b><br>"
        "PhishWatch has identified this message as a potential scam.<br><br>"
        "<b>RECOMMENDED ACTIONS:</b><br>"
        "• DO NOT open any links.<br>"
        "• DELETE the message immediately.<br>"
        "• BLOCK the sender.";

    final androidDetails = AndroidNotificationDetails(
      'danger_channel_v7', // Bumped version to force phone to update settings
      'Security Alerts', 
      channelDescription: 'Critical security notifications',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      color: const Color(0xFFFF0000), 
      ledColor: const Color(0xFFFF0000),
      enableLights: true,
      ledOnMs: 300,
      ledOffMs: 100,
      playSound: true,
      enableVibration: true,
      vibrationPattern: vibrationPattern,
      styleInformation: BigTextStyleInformation(
        detailedMessage, 
        htmlFormatBigText: true,
        contentTitle: "<b>[ ! ] SECURITY WARNING</b>", 
        htmlFormatContentTitle: true,
        //summaryText: "ACTION REQUIRED", 
      ),
      icon: 'ic_launcher',
    );

    final details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecond, 
      "[!] PHISHING ATTEMPT DETECTED [!]", 
      "PhishWatch has intercepted a threat. Tap for details.", 
      details,
      // 🔴 4. PACK PAYLOAD: "SCORE|MESSAGE"
      payload: "$confidence|$body", 
    );
  }
}