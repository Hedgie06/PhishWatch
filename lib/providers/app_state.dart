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
  
  Timer? _apiHealthTimer; 

  bool _isOfflineDialogShowing = false;
  bool _isApiDialogShowing = false; 

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
    _apiHealthTimer?.cancel(); 
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncPermissionState();
      _checkApiHealthNow(); 
    } else if (state == AppLifecycleState.paused) {
      _apiHealthTimer?.cancel(); 
    }
  }

  // --- CONNECTIVITY & HEALTH LOGIC ---
  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      bool isConnected = results.any((r) => r != ConnectivityResult.none);
      
      if (!isConnected) {
        _apiHealthTimer?.cancel(); 
        _closeApiErrorDialog(); 
        if (!_isOfflineDialogShowing) _showPersistentOfflineDialog();
      } else {
        if (_isOfflineDialogShowing) _closeOfflineDialog();
        _startHealthCheckLoop(); 
      }
    });
  }

  void _startHealthCheckLoop() {
      _apiHealthTimer?.cancel();
      _checkApiHealthNow();
      _apiHealthTimer = Timer.periodic(Duration(seconds: 5), (_) => _checkApiHealthNow());
  }

  Future<void> _checkApiHealthNow() async {
    if (_isOfflineDialogShowing) return; 

    bool isApiUp = await apiService.checkHealth();

    if (!isApiUp && !_isApiDialogShowing) {
      _showApiErrorDialog();
    } else if (isApiUp && _isApiDialogShowing) {
      _closeApiErrorDialog();
    }
  }

  void _showApiErrorDialog() {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    _isApiDialogShowing = true;
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
              Icon(Icons.cloud_off, color: Colors.orange, size: 40),
              SizedBox(height: 10),
              Text("Server Unavailable", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            "We are encountering a problem in our analysis server. Be patient while we are trying to fix this.\n\nPhishWatch will automatically reconnect once everything is fixed.",
            textAlign: TextAlign.center,
            style: TextStyle(height: 1.4),
          ),
          actions: [
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _closeApiErrorDialog();
                    _checkApiHealthNow();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF229ED9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text("Retry Now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _closeApiErrorDialog() {
    final context = navigatorKey.currentContext;
    if (context != null && _isApiDialogShowing) {
      Navigator.of(context, rootNavigator: true).pop();
      _isApiDialogShowing = false;
    }
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
    
    bool storedPreference = await storageService.getNotificationPreference();
    PermissionStatus status = await Permission.notification.status;
    
    if (storedPreference && (status.isGranted || status.isLimited)) {
      _notificationsEnabled = true;
    } else {
      _notificationsEnabled = false;
      if (storedPreference) {
         await storageService.saveNotificationPreference(false);
      }
    }

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
    if (!status.isGranted && _notificationsEnabled) {
      _notificationsEnabled = false;
      await storageService.saveNotificationPreference(false);
      notifyListeners();
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

  // 🔴 1. UPDATED SIGNATURE TO ACCEPT CONFIDENCE
  void _handlePhishingDetection(String message, String source, double confidence) {
    _totalThreatsIntercepted++;
    notifyListeners();

    if (_notificationsEnabled) {
      // 🔴 2. PASS CONFIDENCE TO ALERT SERVICE
      AlertService.showDangerAlert("Phishing Detected!", message, confidence);
    }

    Future(() async {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) await FirebaseAuth.instance.signInAnonymously();
        await FirebaseFirestore.instance.collection('detected_threats').add({
          'text': message,
          'source': source,
          'confidence': confidence, // We can save this too
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
    
    await storageService.saveNotificationPreference(_notificationsEnabled);
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
      final title = data['title'] ?? ''; 
      
      if (title == "Telegram" || title == "WhatsApp") return; 
      if (message.contains("new messages") || message.contains("messages from")) return;
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
        // 🔴 3. CAPTURE CONFIDENCE
        final confidence = result['spam_probability'] as double;
        
        if (isPhishing) {
             // 🔴 4. PASS IT TO HANDLER
             _handlePhishingDetection(message, title, confidence);
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
        // 🔴 5. PASS CONFIDENCE HERE TOO
        _handlePhishingDetection(text, "Manual Scan", confidence);
      }
      return detection; 

    } catch (e) {
      return null;
    }
  }

  Future<void> loadGlobalStats() async {
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