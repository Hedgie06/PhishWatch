import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/detection_item.dart';

class StorageService {
  static const String _keyTerms = 'terms_accepted';
  static const String _keyNotifications = 'notifications_enabled'; // 🔴 NEW KEY
  static const String _keyDetections = 'detection_history';

  // --- TERMS ---
  Future<bool> getTermsAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyTerms) ?? false;
  }

  Future<void> saveTermsAccepted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTerms, value);
  }

  // --- 🔴 NEW: NOTIFICATION PREFERENCE ---
  Future<bool> getNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to false if not set
    return prefs.getBool(_keyNotifications) ?? false;
  }

  Future<void> saveNotificationPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, value);
  }

  // --- DETECTIONS (History) ---
  Future<void> saveDetection(DetectionItem item) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_keyDetections) ?? [];
    
    // Convert item to map, then to string
    Map<String, dynamic> map = {
      'id': item.id,
      'app': item.app,
      'message': item.message,
      'isPhishing': item.isPhishing,
      'confidence': item.confidence,
      'timestamp': item.timestamp.toIso8601String(),
    };
    
    history.insert(0, jsonEncode(map)); // Add to top
    await prefs.setStringList(_keyDetections, history);
  }

  Future<List<DetectionItem>> loadDetections() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_keyDetections) ?? [];
    
    return history.map((str) {
      Map<String, dynamic> map = jsonDecode(str);
      return DetectionItem(
        id: map['id'],
        app: map['app'],
        message: map['message'],
        isPhishing: map['isPhishing'],
        confidence: map['confidence'],
        timestamp: DateTime.parse(map['timestamp']),
      );
    }).toList();
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDetections);
  }
}