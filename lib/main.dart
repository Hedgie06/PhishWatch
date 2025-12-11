import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'services/notification_service.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart'; // Make sure this file exists!
import 'services/alert_service.dart';

// The NEW UI
import 'views/home_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Keep your existing local notification setup
  await AlertService.init(); 

  runApp(
    MultiProvider(
      providers: [
        // This injects the "Brain" (AppState) into the app
        ChangeNotifierProvider(
          create: (_) => AppState(
            notificationService: NotificationService(),
            apiService: ApiService(),
            storageService: StorageService(),
          ),
        ),
      ],
      child: const PhishWatchApp(),
    ),
  );
}

class PhishWatchApp extends StatelessWidget {
  const PhishWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PhishWatch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: Color(0xFFF5F7FA), // Matches your new UI background
      ),
      // Point to the NEW Home Screen
      home: HomeScreen(),
    );
  }
}