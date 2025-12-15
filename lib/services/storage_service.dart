import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/detection_item.dart';

class StorageService {
  static const _key = 'detections';
  static const _termsKey = 'terms_accepted'; // 🔴 1. Key for Terms

  Future<void> saveDetection(DetectionItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await loadDetections();
    history.insert(0, item);

    final jsonList = history.map((d) => d.toJson()).toList();
    await prefs.setString(_key, jsonEncode(jsonList));
  }

  Future<List<DetectionItem>> loadDetections() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);

    if (jsonString == null) return [];

    final List decoded = jsonDecode(jsonString);
    return decoded.map((e) => DetectionItem.fromJson(e)).toList();
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  // --- 🔴 2. PERSISTENCE METHODS (Required for Privacy Policy) ---

  Future<void> saveTermsAccepted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_termsKey, value);
  }

  Future<bool> getTermsAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_termsKey) ?? false;
  }
}