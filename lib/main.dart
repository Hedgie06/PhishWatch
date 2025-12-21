import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'services/notification_service.dart'; 
import 'services/alert_service.dart';        
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'providers/app_state.dart';

import 'views/home_dashboard.dart';
import 'views/settings_page.dart';
import 'views/activity_page.dart';
import 'views/onboarding_page.dart';


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await AlertService.initialize(); 

  final notificationService = NotificationService();
  final apiService = ApiService();
  final storageService = StorageService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppState(
            notificationService: notificationService,
            apiService: apiService,
            storageService: storageService,
            navigatorKey: navigatorKey, // Passing key to state
          ),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomeDashboard(),
    ActivityPage(),
    SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 🔴 ASSIGN THE GLOBAL KEY
      navigatorKey: navigatorKey, 
      debugShowCheckedModeBanner: false,
      title: 'PhishWatch',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Color(0xFFF5F7FA),
        useMaterial3: true,
      ),
      home: Consumer<AppState>(
        builder: (context, appState, child) {
          // 1. Show Onboarding if not accepted
          if (!appState.termsAccepted) {
            return OnboardingPage();
          }

          // 2. Show Dashboard if accepted
          return Scaffold(
            body: _pages[_selectedIndex],
            bottomNavigationBar: BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Activity'),
                BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Color(0xFF229ED9),
              unselectedItemColor: Colors.grey,
              showUnselectedLabels: true,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              elevation: 0,
            ),
          );
        },
      ),
    );
  }
}