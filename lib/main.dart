import 'package:flutter/material.dart';
import 'notification_page.dart';
import 'services/alert_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // make sure plugins load properly
  await AlertService.init(); // initialize the local notification service
  runApp(const PhishWatchApp());
}

class PhishWatchApp extends StatelessWidget {
  const PhishWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: NotificationPage(),
    );
  }
}
