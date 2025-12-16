import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/app_state.dart';
import 'services/notification_service.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'views/home_dashboard.dart';
import 'views/settings_page.dart';
import 'views/activity_page.dart';
import 'views/onboarding_page.dart'; // 🔴 1. IMPORT

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

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
            navigatorKey: navigatorKey,
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
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'PhishWatch',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Color(0xFFF5F7FA),
        useMaterial3: true,
      ),
      // 🔴 2. DYNAMIC HOME SCREEN
      // Listens to AppState. If termsAccepted is false -> Onboarding.
      home: Consumer<AppState>(
        builder: (context, appState, child) {
          // If Terms/Onboarding NOT accepted yet -> Show Onboarding
          if (!appState.termsAccepted) {
            return OnboardingPage();
          }

          // Otherwise -> Show Main App Layout
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