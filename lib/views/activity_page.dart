import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/detection_item.dart';

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
      backgroundColor: Color(0xFFF5F7FA), // Match Home Background
      body: SafeArea(
        child: Column(
          children: [
            // 1. CLEAN HEADER (Matches Home Page Vibe)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Text(
                    "Activity Log",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  Spacer(),
                  // Optional: Tiny icon to show it's live
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.history, size: 14, color: Colors.blue),
                        SizedBox(width: 5),
                        Text("${appState.detections.length} Scans", style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                ],
              ),
            ),

            // 2. MODERN "PILL" TABS
            // Instead of the old AppBar tabs, we use a clean Container
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              height: 45,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TabBar(
                controller: _tabController,
                // Design the "Selected" Pill
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: Offset(0, 2))],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent, // Remove the ugly line
                labelColor: Color(0xFF229ED9), // Blue text when selected
                labelStyle: TextStyle(fontWeight: FontWeight.bold),
                unselectedLabelColor: Colors.grey.shade600,
                tabs: [
                  Tab(text: "Safe Messages"),
                  Tab(text: "Dangerous"),
                ],
              ),
            ),

            SizedBox(height: 15),

            // 3. THE LIST (Expanded to fill rest of screen)
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
        final item = list[index];
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            // Subtle shadow like Home Dashboard
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(15),
            leading: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDangerous ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.telegram, color: isDangerous ? Colors.red : Colors.green),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                   child: Text(item.app, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis)
                ),
                // RISK SCORE BADGE
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: Text(
                    "${(item.confidence * 100).toInt()}% Conf.",
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                )
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                item.message,
                style: TextStyle(color: Colors.black54, fontSize: 12, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      },
    );
  }
}