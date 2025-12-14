import 'dart:async';
import 'package:flutter/material.dart'; 
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart'; 

import '../models/detection_item.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/alert_service.dart'; 

class AppState extends ChangeNotifier with WidgetsBindingObserver {
  final NotificationService notificationService;
  final ApiService apiService;
  final StorageService storageService;

  bool listenerEnabled = false;
  bool serviceRunning = false;
  StreamSubscription<Map<String, dynamic>>? _subscription;

  final List<DetectionItem> _detections = [];
  List<DetectionItem> get detections => List.unmodifiable(_detections);

  int _totalThreatsIntercepted = 0;
  int get totalThreatsIntercepted => _totalThreatsIntercepted;

  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;

  AppState({
    required this.notificationService,
    required this.apiService,
    required this.storageService,
  }) {
    WidgetsBinding.instance.addObserver(this);
    _syncPermissionState(); 
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncPermissionState();
    }
  }

  Future<void> _syncPermissionState() async {
    // 1. Sync Shield (Notification Listener)
    bool hasListenerPermission = await notificationService.isListenerEnabled();
    if (listenerEnabled && !hasListenerPermission) {
      if (kDebugMode) print("⚠️ Listener permission revoked. Stopping shield.");
      await stopListening();
    }

    // 2. Sync Toggle (Alert Notifications)
    PermissionStatus status = await Permission.notification.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      if (_notificationsEnabled) {
        if (kDebugMode) print("⚠️ Notifications blocked by OS. Turning off toggle.");
        _notificationsEnabled = false;
        notifyListeners();
      }
    }
  }

  // -----------------------------------------------------------------------------
  // TOGGLE NOTIFICATIONS (Settings Page)
  // -----------------------------------------------------------------------------
  Future<void> toggleNotifications(BuildContext context, bool value) async {
    if (value) {
      PermissionStatus status = await Permission.notification.request();

      if (status.isGranted) {
        _notificationsEnabled = true;
        notifyListeners();
      } else {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: Row(
                children: [
                  Icon(Icons.notifications_off_outlined, color: Colors.orange),
                  SizedBox(width: 10),
                  Text("Permission Needed", style: TextStyle(fontSize: 18)),
                ],
              ),
              content: Text(
                "PhishWatch needs notifications to alert you when a dangerous message is detected.\n\nPlease enable this in Settings.",
                style: TextStyle(height: 1.4),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _notificationsEnabled = false;
                    notifyListeners();
                  },
                  child: Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx); 
                    await openAppSettings(); 
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF229ED9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text("Go to Settings", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }
      }
    } else {
      _notificationsEnabled = false;
      notifyListeners();
    }
  }

  // -----------------------------------------------------------------------------
  // 🔴 UPDATED: START LISTENING (Home Dashboard Shield)
  // -----------------------------------------------------------------------------
  Future<void> startListening(BuildContext context) async {
    bool hasPermission = await notificationService.isListenerEnabled();

    if (!hasPermission) {
      if (kDebugMode) print("⚠️ Permission missing. Showing dialog...");
      
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Row(
              children: [
                Icon(Icons.security_update_warning_outlined, color: Colors.orange),
                SizedBox(width: 10),
                Text("Permission Needed", style: TextStyle(fontSize: 18)),
              ],
            ),
            content: Text(
              "To detect scams in real-time, PhishWatch needs 'Notification Access'.\n\nPlease find 'PhishWatch' in the list and turn it ON.",
              style: TextStyle(height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text("Cancel", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await notificationService.openListenerSettings();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF229ED9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text("Go to Settings", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
      return; 
    }

    if (listenerEnabled) return;
    
    await notificationService.startService(); 
    
    listenerEnabled = true;
    serviceRunning = true;
    notifyListeners();

    _subscription = notificationService.notificationStream.listen((data) async {
      final message = data['text'] ?? data['message'] ?? ''; 
      final app = data['app'] ?? data['package'] ?? 'Unknown'; 
      final title = data['title'] ?? '';

      if (message.contains("new messages") || message.contains("WhatsApp Web")) return; 
      if (!app.toString().toLowerCase().contains('telegram') && app != 'Manual Scan') return; 
      if (message.isEmpty) return;

      try {
        final result = await apiService.classifyMessage(message);
        final isPhishing = result['prediction'].toString().toLowerCase() == 'spam';
        final confidence = result['spam_probability'] as double;

        if (isPhishing) {
          if (_notificationsEnabled) {
            await AlertService.showDangerAlert(
              "Phishing Detected!", 
              "Suspicious message from $title"
            );
          }
          _incrementGlobalStats();
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
        if (kDebugMode) print('Error processing: $e');
      }
    });
  }

  Future<void> stopListening() async {
    await _subscription?.cancel();
    await notificationService.stopService();

    listenerEnabled = false;
    serviceRunning = false;
    notifyListeners();
  }

  Future<void> submitReport(String message) async {
    if (message.isEmpty) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) await FirebaseAuth.instance.signInAnonymously();

      await FirebaseFirestore.instance.collection('reports').add({
        'text': message,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'Phishwatch',
      });
      if (kDebugMode) print("✅ Report sent!");
    } catch (e) {
      if (kDebugMode) print("❌ Error sending report: $e");
      rethrow; 
    }
  }

  Future<void> loadGlobalStats() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('app_stats').doc('global_counts').get();
      if (doc.exists) {
        _totalThreatsIntercepted = doc.data()?['phishing_detected'] ?? 0;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print("Error loading stats: $e");
    }
  }

  void _incrementGlobalStats() {
    _totalThreatsIntercepted++;
    FirebaseFirestore.instance.collection('app_stats').doc('global_counts').update({
      'phishing_detected': FieldValue.increment(1),
    }).catchError((e) => print("Stat update failed: $e"));
    notifyListeners();
  }

  Future<DetectionItem?> manualScan(String text) async {
    if (text.isEmpty) return null;
    try {
      final result = await apiService.classifyMessage(text);
      if (kDebugMode) print("🔍 API RETURNED: $result"); 

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

      if (isPhishing) _incrementGlobalStats();
      return detection; 

    } catch (e) {
      if (kDebugMode) print('❌ Error manual scan: $e');
      return null;
    }
  }

  Future<void> loadHistory() async {
    final history = await storageService.loadDetections();
    _detections
      ..clear()
      ..addAll(history);
    await loadGlobalStats(); 
    await _syncPermissionState();
    notifyListeners();
  }
 
  Future<void> clearHistory() async {
    await storageService.clear(); 
    _detections.clear(); 
    notifyListeners(); 
  }
}