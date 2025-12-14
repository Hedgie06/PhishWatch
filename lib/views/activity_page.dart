import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/detection_item.dart';
import '../widgets/scan_item_tile.dart';

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
    final appState = Provider.of<AppState>(context);
    final safeList = appState.detections.where((d) => !d.isPhishing).toList();
    final dangerousList = appState.detections.where((d) => d.isPhishing).toList();

    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // 1. HEADER ROW
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Text(
                    "Activity Log",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  Spacer(),
                  
                  // 🔵 1. SCAN COUNT PILL (Now on the Left)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.history, size: 16, color: Colors.blue),
                        SizedBox(width: 4),
                        Text("${appState.detections.length} Scans", style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),

                  // 🔴 2. DELETE BUTTON (Now on the Right)
                  if (appState.detections.isNotEmpty) ...[
                    SizedBox(width: 10), // Spacing between buttons
                    GestureDetector(
                      onTap: () => _showClearHistoryDialog(context),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1), // Light Red
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 16, color: Colors.red),
                            SizedBox(width: 4),
                            Text("Clear", style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 2. MODERN TABS
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              height: 45,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: Offset(0, 2))],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Color(0xFF229ED9),
                labelStyle: TextStyle(fontWeight: FontWeight.bold),
                unselectedLabelColor: Colors.grey.shade600,
                tabs: [
                  Tab(text: "Safe Messages"),
                  Tab(text: "Dangerous"),
                ],
              ),
            ),

            SizedBox(height: 15),

            // 3. THE LIST
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildModernList(safeList, isDangerous: false),
                  _buildModernList(dangerousList, isDangerous: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // DELETE CONFIRMATION DIALOG
  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("Clear History?"),
        content: Text("This will permanently delete all scan records."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              // Call AppState to clear data
              Provider.of<AppState>(context, listen: false).clearHistory();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("History cleared"), 
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 1),
                )
              );
            },
            child: Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildModernList(List<DetectionItem> list, {required bool isDangerous}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isDangerous ? Icons.gpp_good : Icons.mark_email_unread, size: 60, color: Colors.grey.shade300),
            SizedBox(height: 10),
            Text("No records found", style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: list.length,
      itemBuilder: (context, index) {
        return ScanItemTile(item: list[index]);
      },
    );
  }
}