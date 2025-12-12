import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart'; // 1. IMPORT THIS

import 'providers/app_state.dart';
import 'services/notification_service.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'services/alert_service.dart';
import 'views/home_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await AlertService.init(); 

  // 2. ADD THIS LINE
  // This turns on the connection to your google-services.json file
  await Firebase.initializeApp(); 

  runApp(
    MultiProvider(
      providers: [
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
        scaffoldBackgroundColor: Color(0xFFF5F7FA),
      ),
      home: HomeScreen(),
    );
  }
}