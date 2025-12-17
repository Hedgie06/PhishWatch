import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  late final String baseUrl;

  ApiService({String? customBaseUrl}) {
    if (customBaseUrl != null) {
      baseUrl = customBaseUrl;
    } else if (Platform.isAndroid) {
      // For physical device via USB debugging or Emulator
      // Note: If using Emulator, use "http://10.0.2.2:5000"
      // If using Physical Device, use your PC's IP "http://192.168.x.x:5000"
      baseUrl = "http://172.20.10.6:5000"; 
    } else if (Platform.isWindows) {
      baseUrl = "http://127.0.0.1:5000";
    } else {
      baseUrl = "http://10.115.13.66:5000";
    }
  }

  // 🔴 NEW: Health Check
  Future<bool> checkHealth() async {
    try {
      // Ping the server to see if it's reachable
      final response = await http.get(Uri.parse("$baseUrl/")).timeout(Duration(seconds: 5));
      // If we get any response code (even 404), the server is at least "up"
      return true;
    } catch (e) {
      return false; // Connection failed/Timeout
    }
  }

  Future<Map<String, dynamic>> classifyMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/predict"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message": message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          "prediction": data["prediction"],
          "spam_probability": data["spam_probability"],
          "ham_probability": data["ham_probability"]
        };
      } else {
        throw Exception("Failed to classify: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error connecting to API: $e");
    }
  }
}