import 'dart:async';
import 'package:flutter/material.dart'; 
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart'; 
import 'package:connectivity_plus/connectivity_plus.dart'; 

import '../models/detection_item.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/alert_service.dart'; 
import '../views/privacy_policy_page.dart';

class AppState extends ChangeNotifier with WidgetsBindingObserver {
  final NotificationService notificationService;
  final ApiService apiService;
  final StorageService storageService;
  final GlobalKey<NavigatorState> navigatorKey; // 🔴 NEW

  bool listenerEnabled = false;
  bool serviceRunning = false;
  StreamSubscription<Map<String, dynamic>>? _subscription;
  // 🔴 NEW: Connectivity Subscription
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOfflineDialogShowing = false;

  final List<DetectionItem> _detections = [];
  List<DetectionItem> get detections => List.unmodifiable(_detections);

  int _totalThreatsIntercepted = 0;
  int get totalThreatsIntercepted => _totalThreatsIntercepted;

  bool _notificationsEnabled = false; 
  bool get notificationsEnabled => _notificationsEnabled;

  bool _termsAccepted = false;
  bool get termsAccepted => _termsAccepted;

  AppState({
    required this.notificationService,
    required this.apiService,
    required this.storageService,
    required this.navigatorKey, // 🔴 NEW
  }) {
    WidgetsBinding.instance.addObserver(this);
    _loadPersistence();
    _initConnectivityListener(); // 🔴 Start Monitoring
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel(); // Clean up
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncPermissionState();
    }
  }

  // 🔴 1. GLOBAL CONNECTIVITY MONITOR
  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      // Check if ANY connection is available
      bool isConnected = results.any((r) => r != ConnectivityResult.none);

      if (!isConnected && !_isOfflineDialogShowing) {
        _showPersistentOfflineDialog();
      } else if (isConnected && _isOfflineDialogShowing) {
        _closeOfflineDialog();
      }
    });
  }

  // 🔴 2. SHOW BLOCKING DIALOG
  void _showPersistentOfflineDialog() {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    _isOfflineDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false, // User CANNOT close this by tapping outside
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false, // User CANNOT close this by back button
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Column(
            children: [
              Icon(Icons.wifi_off, color: Colors.red, size: 40),
              SizedBox(height: 10),
              Text("Connection Lost", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            "PhishWatch requires an active internet connection to protect you.\n\nPlease reconnect to Wi-Fi or Mobile Data to continue.",
            textAlign: TextAlign.center,
            style: TextStyle(height: 1.4),
          ),
        ),
      ),
    );
  }

  // 🔴 3. HIDE DIALOG AUTOMATICALLY
  void _closeOfflineDialog() {
    final context = navigatorKey.currentContext;
    if (context != null && _isOfflineDialogShowing) {
      Navigator.of(context, rootNavigator: true).pop(); // Close the top dialog
      _isOfflineDialogShowing = false;
    }
  }

  Future<void> _loadPersistence() async {
    _termsAccepted = await storageService.getTermsAccepted();
    notifyListeners();
  }

  void acceptTerms() {
    _termsAccepted = true;
    storageService.saveTermsAccepted(true);
    notifyListeners();
  }

  Future<void> _syncPermissionState() async {
    bool hasListenerPermission = await notificationService.isListenerEnabled();
    if (listenerEnabled && !hasListenerPermission) {
      if (kDebugMode) print("⚠️ Listener permission revoked. Stopping shield.");
      await stopListening();
    }

    PermissionStatus status = await Permission.notification.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      if (_notificationsEnabled) {
        _notificationsEnabled = false;
        notifyListeners();
      }
    }
  }

  // NOTE: This manual helper is still useful for initial checks, 
  // but the Stream listener handles the global blocking.
  void _showTermsDialog(BuildContext context) {
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.policy, color: Color(0xFF229ED9)),
            SizedBox(width: 10),
            Text("Agreement Required", style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Text(
          "Before using PhishWatch, you must read and accept our Privacy Policy and Terms of Service.",
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); 
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => PrivacyPolicyPage())
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF229ED9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text("Go to Policy", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _handlePhishingDetection(String message, String source) {
    _totalThreatsIntercepted++;
    notifyListeners();

    Future(() async {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) await FirebaseAuth.instance.signInAnonymously();

        final batch = FirebaseFirestore.instance.batch();
        final statsRef = FirebaseFirestore.instance.collection('app_stats').doc('global_counts');
        batch.set(statsRef, {'phishing_detected': FieldValue.increment(1)}, SetOptions(merge: true));

        final threatRef = FirebaseFirestore.instance.collection('detected_threats').doc();
        batch.set(threatRef, {
          'text': message,
          'source': source,
          'timestamp': FieldValue.serverTimestamp(),
          'detected_by': 'auto_system',
        });

        await batch.commit();
        if (kDebugMode) print("🚀 Threat uploaded in background.");
      } catch (e) {
        if (kDebugMode) print("⚠️ Background upload failed: $e");
      }
    });
  }

  Future<void> toggleNotifications(BuildContext context, bool value) async {
    if (value && !_termsAccepted) {
      _showTermsDialog(context);
      return; 
    }

    if (value) {
      PermissionStatus status = await Permission.notification.request();
      if (status.isGranted) {
        _notificationsEnabled = true;
        notifyListeners();
      } else {
        // Show permission dialog (omitted for brevity, same as before)
      }
    } else {
      _notificationsEnabled = false;
      notifyListeners();
    }
  }

  Future<void> startListening(BuildContext context) async {
    if (!_termsAccepted) {
      _showTermsDialog(context);
      return; 
    }

    // Note: We don't strictly need _checkConnectivity here anymore 
    // because the global dialog will block the UI if offline anyway.
    
    bool hasPermission = await notificationService.isListenerEnabled();
    if (!hasPermission) {
      if (context.mounted) {
        // Show permission dialog (omitted for brevity, same as before)
        // You can copy the permission dialog code back if you deleted it accidentally
        // or just rely on the openListenerSettings() call.
        await notificationService.openListenerSettings(); // simplified for brevity
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

      final isDuplicate = _detections.any((item) {
        final isSameSender = item.app == title; 
        final isSameContent = item.message == message;
        final isRecent = DateTime.now().difference(item.timestamp).inMinutes < 5; 
        return isSameSender && isSameContent && isRecent;
      });

      if (isDuplicate) return; 

      try {
        final result = await apiService.classifyMessage(message);
        final isPhishing = result['prediction'].toString().toLowerCase() == 'spam';
        final confidence = result['spam_probability'] as double;

        if (isPhishing) {
          if (_notificationsEnabled) {
            AlertService.showDangerAlert(
              "Phishing Detected!", 
              "Suspicious message from $title"
            );
          }
          _handlePhishingDetection(message, "Notification: $app");
        }

        final detection = DetectionItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          app: title, 
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

  Future<void> submitReport(BuildContext context, String message) async {
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
      final doc = await FirebaseFirestore.instance
          .collection('app_stats')
          .doc('global_counts')
          .get()
          .timeout(Duration(seconds: 3)); 

      if (doc.exists) {
        _totalThreatsIntercepted = doc.data()?['phishing_detected'] ?? 0;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print("Error loading stats (non-fatal): $e");
    }
  }

  Future<DetectionItem?> manualScan(BuildContext context, String text) async {
    if (!_termsAccepted) {
      _showTermsDialog(context);
      return null; 
    }

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

      if (isPhishing) {
        _handlePhishingDetection(text, "Manual Scan");
      }
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
    
    loadGlobalStats(); 
    _syncPermissionState();
    
    notifyListeners();
  }
 
  Future<void> clearHistory() async {
    await storageService.clear(); 
    _detections.clear(); 
    notifyListeners(); 
  }
}