import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

// Import your new view files
import 'home_dashboard.dart';
import 'activity_page.dart';
import 'settings_page.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomeDashboard(),
    ActivityPage(), 
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
      Provider.of<AppState>(context, listen: false).loadHistory()
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        
        // ----------------------------------------------------
        // 🔴 FIX: Force background to White to remove pink tint
        backgroundColor: Colors.white, 
        // ----------------------------------------------------
        
        selectedItemColor: Color(0xFF229ED9), // Your App Blue
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "Activity"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }
}