import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_state.dart';
import '../models/detection_item.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomeDashboard(),      // Page 0: TrueCaller Style
    ActivityPage(),       // Page 1: YOUR ORIGINAL BLUE TABS (Restored)
    SettingsPage(),       // Page 2: Settings
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

// ==========================================
// PAGE 1: HOME DASHBOARD (Modern UI)
// ==========================================
class HomeDashboard extends StatelessWidget {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final detections = appState.detections;
    final isScanning = appState.listenerEnabled;

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // MANUAL SCAN INPUT
          Container(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "Paste Telegram msg to scan...",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                icon: Icon(Icons.search, color: Colors.grey.shade400),
                suffixIcon: IconButton(
                  icon: Icon(Icons.send, color: Color(0xFF229ED9)),
                  onPressed: () {
                    appState.manualScan(_searchController.text);
                    _searchController.clear();
                    FocusScope.of(context).unfocus();
                  },
                ),
              ),
            ),
          ),

          SizedBox(height: 30),

          // STATUS HERO
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => isScanning ? appState.stopListening() : appState.startListening(),
                  child: Container(
                    height: 100, width: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: isScanning ? Color(0xFF229ED9).withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                          blurRadius: 20, spreadRadius: 5,
                        )
                      ],
                    ),
                    child: Icon(
                      isScanning ? Icons.security : Icons.gpp_bad_outlined,
                      size: 50,
                      color: isScanning ? Color(0xFF229ED9) : Colors.grey,
                    ),
                  ),
                ),
                SizedBox(height: 15),
                Text(
                  isScanning ? "System Secure" : "Protection Paused",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  isScanning ? "Monitoring Telegram..." : "Tap shield to activate",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          SizedBox(height: 30),

          // ACTION CARDS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionCard(context, Icons.people_outline, "Community", "Join AsamAlert",
                  () => launchUrl(Uri.parse('https://t.me/AsamAlert'))),
              _buildActionCard(context, Icons.menu_book, "Library", "Learn tactics", () {}),
              _buildActionCard(context, Icons.flag_outlined, "Report", "Flag error",
                  () => _showReportDialog(context)),
            ],
          ),

          SizedBox(height: 30),

          // RECENT SCANS PREVIEW
          Text("Recent Scans", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 15),
          if (detections.isEmpty)
             Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No scans yet", style: TextStyle(color: Colors.grey))))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: detections.take(3).length,
              itemBuilder: (context, index) => ScanItemTile(item: detections[index]),
            ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Report Error"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Help us retrain the model.", style: TextStyle(fontSize: 12, color: Colors.grey)),
            SizedBox(height: 10),
            TextField(decoration: InputDecoration(labelText: "Sender Info", border: OutlineInputBorder())),
            SizedBox(height: 10),
            TextField(decoration: InputDecoration(labelText: "Paste Message", border: OutlineInputBorder()), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: Text("Submit")),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.28,
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 5))],
        ),
        child: Column(
          children: [
            Icon(icon, color: Color(0xFF229ED9)),
            SizedBox(height: 10),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text(subtitle, style: TextStyle(color: Colors.grey, fontSize: 10), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// PAGE 2: ACTIVITY PAGE (RESTORED NOTIFICATION_PAGE UI)
// ==========================================
class ActivityPage extends StatefulWidget {
  @override
  _ActivityPageState createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    // 1. Get Data from AppState
    final appState = Provider.of<AppState>(context);
    
    // 2. Filter Lists based on isPhishing status
    final safeList = appState.detections.where((d) => !d.isPhishing).toList();
    final dangerousList = appState.detections.where((d) => d.isPhishing).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false, // Hide back button (we use bottom nav)
        title: Text(
          "PhishWatch",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 24),
        ),
        backgroundColor: Color(0xFF229ED9), // Your original Blue
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          tabs: [
            Tab(text: "Safe"),
            Tab(text: "Dangerous"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOriginalList(safeList, isDangerous: false),
          _buildOriginalList(dangerousList, isDangerous: true),
        ],
      ),
    );
  }

  Widget _buildOriginalList(List<DetectionItem> list, {required bool isDangerous}) {
    if (list.isEmpty) {
      return Center(
        child: Text("No notifications yet.", style: TextStyle(fontSize: 16, color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(top: 10),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            // Slight red tint for dangerous, grey for safe
            color: isDangerous ? Color(0xFFFFF5F5) : Color(0xFFF1F0F0),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: Offset(0, 3)),
            ],
          ),
          child: ListTile(
            leading: Icon(
              Icons.telegram, // Force Telegram icon
              color: Color(0xFF229ED9),
              size: 28,
            ),
            title: Text(
              item.app, // Displays "Manual Scan" or "Telegram"
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Text(
              item.message,
              style: TextStyle(color: Colors.black87, fontSize: 13, height: 1.3),
              maxLines: 4, // Show more lines like original
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              "${(item.confidence * 100).toInt()}%",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }
}

// ==========================================
// PAGE 3: SETTINGS PAGE
// ==========================================
class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Settings", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          
          Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield, color: Color(0xFF229ED9)),
                    SizedBox(width: 15),
                    Text("Real-time Protection", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Switch(
                  value: appState.listenerEnabled, 
                  onChanged: (val) => val ? appState.startListening() : appState.stopListening(),
                  activeColor: Color(0xFF229ED9),
                ),
              ],
            ),
          ),
          Spacer(),
          Center(child: Text("PhishWatch v1.0\nTelegram Dataset Model", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }
}

// ==========================================
// SHARED WIDGET: SCAN ITEM TILE (FOR HOME PAGE)
// ==========================================
class ScanItemTile extends StatelessWidget {
  final DetectionItem item;
  const ScanItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.isPhishing ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.telegram, color: item.isPhishing ? Colors.red : Colors.green),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.app, style: TextStyle(fontWeight: FontWeight.bold)),
                Text(item.message, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.isPhishing ? "PHISHING" : "SAFE",
                style: TextStyle(color: item.isPhishing ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          )
        ],
      ),
    );
  }
}