import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/detection_item.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

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

  Future<void> startListening() async {
    if (listenerEnabled) return;
    listenerEnabled = true;
    serviceRunning = true;
    notifyListeners();

    _subscription = notificationService.notificationStream.listen((data) async {
      final message = data['message'] ?? '';
      final app = data['package'] ?? 'Unknown';

      if (message.isEmpty) return;

      try {
        final result = await apiService.classifyMessage(message);

        final detection = DetectionItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          app: app,
          message: message,
          isPhishing: result['isPhishing'] as bool,
          confidence: (result['confidence'] as num).toDouble(),
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
