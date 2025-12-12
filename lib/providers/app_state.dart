import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import '../models/detection_item.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/alert_service.dart'; 

class AppState extends ChangeNotifier {
  final NotificationService notificationService;
  final ApiService apiService;
  final StorageService storageService;

  bool listenerEnabled = false;
  bool serviceRunning = false;
  StreamSubscription<Map<String, dynamic>>? _subscription;

  final List<DetectionItem> _detections = [];
  List<DetectionItem> get detections => List.unmodifiable(_detections);

  AppState({
    required this.notificationService,
    required this.apiService,
    required this.storageService,
  });

  // -----------------------------------------------------------------------------
  // 🔴 NEW: Submit Report to Firebase (Anonymous Auth + Firestore)
  // -----------------------------------------------------------------------------
  Future<void> submitReport(String message) async {
    if (message.isEmpty) return;

    try {
      // 1. Silent Login (Anonymous)
      // This creates a secure, temporary user ID without a login screen.
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }

      // 2. Upload to Firestore
      // We only store the MESSAGE and TIME. No personal info.
      await FirebaseFirestore.instance.collection('reports').add({
        'text': message,
        'timestamp': FieldValue.serverTimestamp(), // Server-side time
        'platform': 'Phishwatch',
      });
      
      if (kDebugMode) {
        print("✅ Report sent to Firestore successfully!");
      }

    } catch (e) {
      if (kDebugMode) {
        print("❌ Error sending report: $e");
      }
      rethrow; // Pass error back to UI so we can show the Red Snackbar
    }
  }
  // -----------------------------------------------------------------------------

  Future<void> startListening() async {
    if (listenerEnabled) return;
    listenerEnabled = true;
    serviceRunning = true;
    notifyListeners();

    _subscription = notificationService.notificationStream.listen((data) async {
      // Correct Keys from your logs
      final message = data['text'] ?? data['message'] ?? ''; 
      final app = data['app'] ?? data['package'] ?? 'Unknown'; 
      final title = data['title'] ?? '';

      // Ignore Summary notifications
      if (message.contains("new messages") || message.contains("WhatsApp Web")) {
        return; 
      }

      // Telegram Filter
      if (!app.toString().toLowerCase().contains('telegram') && app != 'Manual Scan') {
        return; 
      }

      if (message.isEmpty) return;

      try {
        final result = await apiService.classifyMessage(message);

        final isPhishing = result['prediction'].toString().toLowerCase() == 'spam';
        final confidence = result['spam_probability'] as double;

        // Trigger Alert
        if (isPhishing) {
          await AlertService.showDangerAlert(
            "Phishing Detected!", 
            "Suspicious message from $title"
          );
        }

        final detection = DetectionItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          app: title.isNotEmpty ? title : app, 
          message: message,
          isPhishing: isPhishing, 
          confidence: confidence,
          timestamp: DateTime.now(),
        );

        _detections.insert(0, detection);
        await storageService.saveDetection(detection);
        notifyListeners();
        
      } catch (e) {
        if (kDebugMode) {
          print('Error classifying message: $e');
        }
      }
    });
  }

  // Manual Scan Logic
  Future<void> manualScan(String text) async {
    if (text.isEmpty) return;

    try {
      final result = await apiService.classifyMessage(text);

      final isPhishing = result['prediction'].toString().toLowerCase() == 'spam';
      final confidence = result['spam_probability'] as double;

      final detection = DetectionItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        app: 'Manual Scan',
        message: text,
        isPhishing: isPhishing, 
        confidence: confidence,
        timestamp: DateTime.now(),
      );

      _detections.insert(0, detection);
      await storageService.saveDetection(detection);
      notifyListeners();

    } catch (e) {
      if (kDebugMode) {
        print('Error manual scan: $e');
      }
    }
  }

  Future<void> stopListening() async {
    await _subscription?.cancel();
    listenerEnabled = false;
    serviceRunning = false;
    notifyListeners();
  }

  Future<void> loadHistory() async {
    final history = await storageService.loadDetections();
    _detections
      ..clear()
      ..addAll(history);
    notifyListeners();
  }
 
  Future<void> clearHistory() async {
    await storageService.clear();
    _detections.clear(); 
    notifyListeners(); 
  }
}