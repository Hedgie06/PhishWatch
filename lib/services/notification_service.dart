import 'dart:async';
import 'package:flutter/services.dart';

class NotificationService {
  static const MethodChannel _method = MethodChannel('fyp.notification/methods');
  static const EventChannel _events = EventChannel('fyp.notification/events');
  
  // We removed the FlutterLocalNotificationsPlugin logic
  // because we are relying on the "Session-Based" approach.

  NotificationService(); // Default constructor is fine

  Stream<Map<String, dynamic>>? _onNotificationStream;
  
  Stream<Map<String, dynamic>> get onNotification {
    _onNotificationStream ??= _events.receiveBroadcastStream().map((event) {
      return Map<String, dynamic>.from(event as Map);
    });
    return _onNotificationStream!;
  }
    
  Stream<Map<String, dynamic>> get notificationStream => onNotification;
  
  Future<bool> isListenerEnabled() async {
    try {
      final bool enabled = await _method.invokeMethod('isListenerEnabled');
      return enabled;
    } catch (e) {
      return false;
    }
  }
  
  Future<void> openListenerSettings() async {
    try {
      await _method.invokeMethod('openListenerSettings');
    } catch (e) {
      // ignore
    }
  }
  
  Future<void> startService() async {
    try {
      await _method.invokeMethod('startService');
    } catch (e) {}
  }
  
  Future<void> stopService() async {
    try {
      await _method.invokeMethod('stopService');
    } catch (e) {}
  }
}