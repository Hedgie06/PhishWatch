import 'dart:async';
import 'package:flutter/foundation.dart';
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


// inside lib/providers/app_state.dart

Future<void> startListening() async {
  if (listenerEnabled) return;
  listenerEnabled = true;
  serviceRunning = true;
  notifyListeners();

  _subscription = notificationService.notificationStream.listen((data) async {
    // ---------------------------------------------------------
    // 🔴 FIX 1: USE THE CORRECT KEYS FROM YOUR LOGS
    // ---------------------------------------------------------
    // The logs show the keys are 'text' and 'app', not 'message' and 'package'
    final message = data['text'] ?? data['message'] ?? ''; 
    final app = data['app'] ?? data['package'] ?? 'Unknown'; 
    final title = data['title'] ?? '';
    // ---------------------------------------------------------

    // 🔴 FIX 2: IGNORE "SUMMARY" NOTIFICATIONS
    // Telegram sends "628 new messages" summaries. We don't want to scan those.
    if (message.contains("new messages") || message.contains("WhatsApp Web")) {
      return; 
    }

    // 🔴 FIX 3: TELEGRAM FILTER
    // Check if the app name contains "telegram" (Case insensitive)
    if (!app.toString().toLowerCase().contains('telegram') && app != 'Manual Scan') {
       return; // Ignore WhatsApp, SMS, etc.
    }

    if (message.isEmpty) return;

    try {
      final result = await apiService.classifyMessage(message);

      final isPhishing = result['prediction'].toString().toLowerCase() == 'spam';
      final confidence = result['spam_probability'] as double;

      // TRIGGER ALERT
      if (isPhishing) {
        await AlertService.showDangerAlert(
          "Phishing Detected!", 
          "Suspicious message from $title" // Use title (Sender Name) here
        );
      }

      final detection = DetectionItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        // Use 'title' (Sender Name) if available, otherwise use App Name
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

  // Manual Paste message
  // ADD THIS TO lib/providers/app_state.dart
  Future<void> manualScan(String text) async {
    if (text.isEmpty) return;

    try {
      // 1. Call your existing API
      final result = await apiService.classifyMessage(text);

      // 2. PARSE THE RESULT (Fixing the mismatch)
      // Assuming 'prediction' returns strings "spam" or "ham"
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

      // 3. Save and Update UI
      _detections.insert(0, detection);
      await storageService.saveDetection(detection);
      notifyListeners();

    } catch (e) {
      if (kDebugMode) {
        print('Error manual scan: $e');
      }
      // Optional: Show an error snackbar here if you have access to context
      // or rethrow to handle it in the UI
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
}
