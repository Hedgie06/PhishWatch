import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/detection_item.dart';

class StorageService {
  static const _key = 'detections';

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
}
