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
  final GlobalKey<NavigatorState> navigatorKey;

  bool listenerEnabled = false;
  bool serviceRunning = false;
  StreamSubscription<Map<String, dynamic>>? _subscription;
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
    required this.navigatorKey,
  }) {
    WidgetsBinding.instance.addObserver(this);
    _loadPersistence();
    _initConnectivityListener();
    _syncPermissionState(); 
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncPermissionState();
    }
  }

  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      bool isConnected = results.any((r) => r != ConnectivityResult.none);
      if (!isConnected && !_isOfflineDialogShowing) {
        _showPersistentOfflineDialog();
      } else if (isConnected && _isOfflineDialogShowing) {
        _closeOfflineDialog();
      }
    });
  }

  void _showPersistentOfflineDialog() {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    _isOfflineDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false,
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
            "PhishWatch requires an active internet connection to protect you.\n\nPlease reconnect to continue.",
            textAlign: TextAlign.center,
            style: TextStyle(height: 1.4),
          ),
        ),
      ),
    );
  }

  void _closeOfflineDialog() {
    final context = navigatorKey.currentContext;
    if (context != null && _isOfflineDialogShowing) {
      Navigator.of(context, rootNavigator: true).pop();
      _isOfflineDialogShowing = false;
    }
  }

  Future<void> _loadPersistence() async {
    _termsAccepted = await storageService.getTermsAccepted();
    await loadHistory(); 
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
    if (!status.isGranted) {
      if (_notificationsEnabled) {
        _notificationsEnabled = false;
        notifyListeners();
      }
    }
  }

  void _showTermsDialog(BuildContext context) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("Agreement Required"),
        content: Text("Please accept the Terms of Service to continue."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); 
              Navigator.push(context, MaterialPageRoute(builder: (_) => PrivacyPolicyPage()));
            },
            child: Text("Read Policy"),
          ),
        ],
      ),
    );
  }

  void _handlePhishingDetection(String message, String source) {
    _totalThreatsIntercepted++;
    notifyListeners();

    if (_notificationsEnabled) {
      AlertService.showDangerAlert("Phishing Detected!", "Suspicious message from $source");
    }

    Future(() async {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) await FirebaseAuth.instance.signInAnonymously();
        await FirebaseFirestore.instance.collection('detected_threats').add({
          'text': message,
          'source': source,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (e) {}
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
      } else {
        _notificationsEnabled = false;
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Permission denied. Enable notifications in settings.")));
        }
      }
    } else {
      _notificationsEnabled = false;
    }
    notifyListeners();
  }

  Future<void> startListening(BuildContext context) async {
    if (!_termsAccepted) {
      _showTermsDialog(context);
      return; 
    }

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) return;

    bool hasPermission = await notificationService.isListenerEnabled();
    
    if (!hasPermission) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
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
      final message = data['text'] ?? '';
      final title = data['title'] ?? ''; // This is usually the Sender Name
      
      // 🛑 1. FILTERING LOGIC (New)
      // Block generic summaries like "596 new messages" or sender "Telegram"
      if (title == "Telegram" || title == "WhatsApp") return; 
      if (message.contains("new messages") || message.contains("messages from")) return;
      if (message.isEmpty) return;

      // 🛑 2. DEDUPLICATION (Prevent spamming the same log)
      final isDuplicate = _detections.any((item) {
        final isSameSender = item.app == title;
        final isSameContent = item.message == message;
        // Check if same message received within last 5 minutes
        final isRecent = DateTime.now().difference(item.timestamp).inMinutes < 5;
        return isSameSender && isSameContent && isRecent;
      });

      if (isDuplicate) return;

      // 🛑 3. PROCEED TO AI
      try {
        final result = await apiService.classifyMessage(message);
        final isPhishing = result['prediction'].toString().toLowerCase() == 'spam';
        
        if (isPhishing) {
            _handlePhishingDetection(message, title);
        }
        
        final detection = DetectionItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            app: title,
            message: message,
            isPhishing: isPhishing,
            confidence: result['spam_probability'] as double,
            timestamp: DateTime.now(),
        );
        _detections.insert(0, detection);
        await storageService.saveDetection(detection);
        notifyListeners();

      } catch(e) {}
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
    await FirebaseFirestore.instance.collection('reports').add({
      'text': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<DetectionItem?> manualScan(BuildContext context, String text) async {
    if (!_termsAccepted) {
      _showTermsDialog(context);
      return null; 
    }
    
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) return null;

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

      if (isPhishing) {
        _handlePhishingDetection(text, "Manual Scan");
      }
      return detection; 

    } catch (e) {
      return null;
    }
  }

  Future<void> loadGlobalStats() async {
    // Placeholder if you need global stats later
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