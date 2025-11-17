class DetectionItem {
  final String id;
  final String app;
  final String message;
  final bool isPhishing;
  final double confidence;
  final DateTime timestamp;

  DetectionItem({
    required this.id,
    required this.app,
    required this.message,
    required this.isPhishing,
    required this.confidence,
    required this.timestamp,
  });

  // For saving to local storage
  Map<String, dynamic> toJson() => {
        'id': id,
        'app': app,
        'message': message,
        'isPhishing': isPhishing,
        'confidence': confidence,
        'timestamp': timestamp.toIso8601String(),
      };

  factory DetectionItem.fromJson(Map<String, dynamic> json) {
    return DetectionItem(
      id: json['id'] as String,
      app: json['app'] as String,
      message: json['message'] as String,
      isPhishing: json['isPhishing'] as bool,
      confidence: (json['confidence'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
