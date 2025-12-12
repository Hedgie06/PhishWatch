import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_state.dart';
import '../models/detection_item.dart';

class HomeDashboard extends StatelessWidget {
  
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
          // 1. MANUAL SCAN TRIGGER (Hero Animation Source)
          Hero(
            tag: 'search_bar', // Unique tag for animation
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showManualScanDialog(context, appState),
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 5))
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey.shade400),
                      SizedBox(width: 10),
                      Text(
                        "Tap to check suspicious message",
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 30),

          // 2. HERO SECTION (Shield & Status)
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
                SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: isScanning ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      isScanning ? "Monitoring Telegram Notifications..." : "Tap shield to activate",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                )
              ],
            ),
          ),

          SizedBox(height: 30),

          // 3. ACTION CARDS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionCard(context, Icons.people_outline, "Community", "Join AsamAlert",
                  () => launchUrl(Uri.parse('https://t.me/AsamAlert'))),
              _buildActionCard(context, Icons.menu_book, "Library", "Learn tactics", () {}),
              _buildActionCard(context, Icons.flag_outlined, "Report", "Flag error",
                  // Pass 'appState' here
                  () => _showReportDialog(context, appState)),
            ],
          ),

          SizedBox(height: 30),

          // 4. RECENT SCANS LIST
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

  // ==========================================
  // NEW: MANUAL SCAN DIALOG (With Hero Animation)
  // ==========================================
void _showManualScanDialog(BuildContext context, AppState appState) {
    final TextEditingController _dialogSearchController = TextEditingController();
    final FocusNode _focusNode = FocusNode();

    // Delay focus to prevent animation jank
    Future.delayed(Duration(milliseconds: 600), () {
      if (_focusNode.canRequestFocus) {
        _focusNode.requestFocus();
      }
    });

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black54,
        transitionDuration: Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            // We handle resizing manually for smoother control
            resizeToAvoidBottomInset: false, 
            body: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate available height above keyboard
                final bottomInset = MediaQuery.of(context).viewInsets.bottom;
                final availableHeight = constraints.maxHeight - bottomInset - 40; // 40 is padding

                return Stack(
                  children: [
                    // Background tap to close
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        behavior: HitTestBehavior.opaque,
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                    
                    // The Dialog
                    Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: bottomInset), // Push up by keyboard height
                        child: Hero(
                          tag: 'search_bar',
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              margin: EdgeInsets.all(20),
                              // 🔴 THIS IS THE FIX:
                              // Constrain the box so it NEVER exceeds available screen space.
                              constraints: BoxConstraints(
                                maxHeight: availableHeight > 0 ? availableHeight : 300,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)],
                              ),
                              // Use ListView instead of Column + SingleChildScrollView
                              // It handles scrolling overflow natively.
                              child: ListView(
                                shrinkWrap: true, // occupy only needed space
                                padding: EdgeInsets.all(20),
                                children: [
                                  Text("Message Check", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 15),
                                  
                                  TextField(
                                    controller: _dialogSearchController,
                                    focusNode: _focusNode,
                                    maxLines: 6,
                                    minLines: 3,
                                    decoration: InputDecoration(
                                      hintText: "Paste the suspicious message here...",
                                      hintStyle: TextStyle(color: Colors.grey.shade400),
                                      filled: true,
                                      fillColor: Color(0xFFF5F7FA),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: EdgeInsets.all(15),
                                    ),
                                  ),
                                  
                                  SizedBox(height: 20),
                                  
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text("Cancel", style: TextStyle(color: Colors.grey)),
                                      ),
                                      SizedBox(width: 10),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          if (_dialogSearchController.text.isNotEmpty) {
                                            appState.manualScan(_dialogSearchController.text);
                                            Navigator.pop(context);
                                            FocusScope.of(context).unfocus();
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF229ED9),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        ),
                                        label: Text("Check Now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showReportDialog(BuildContext context, AppState appState) {
    // Only need the message controller now
    final TextEditingController _msgController = TextEditingController();
    final FocusNode _focusNode = FocusNode();

    // Smooth focus delay
    Future.delayed(Duration(milliseconds: 600), () {
      if (_focusNode.canRequestFocus) {
        _focusNode.requestFocus();
      }
    });

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black54,
        transitionDuration: Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) {
          
          return Scaffold(
            backgroundColor: Colors.transparent,
            resizeToAvoidBottomInset: false, 
            body: LayoutBuilder(
              builder: (context, constraints) {
                final bottomInset = MediaQuery.of(context).viewInsets.bottom;
                final availableHeight = constraints.maxHeight - bottomInset - 40;

                return Stack(
                  children: [
                    // 1. Background tap to close
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        behavior: HitTestBehavior.opaque,
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                    
                    // 2. The Dialog Box
                    Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: bottomInset),
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            margin: EdgeInsets.all(20),
                            constraints: BoxConstraints(
                              maxHeight: availableHeight > 0 ? availableHeight : 450,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)],
                            ),
                            child: ListView(
                              shrinkWrap: true,
                              padding: EdgeInsets.all(20),
                              children: [
                                // Header
                                Row(
                                  children: [
                                    Icon(Icons.flag_outlined, color: Colors.orange, size: 28),
                                    SizedBox(width: 10),
                                    Text("Report Missed Scam", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                SizedBox(height: 5),
                                Text("Did we miss a phishing message? Paste the text below to help us retrain the model.", 
                                  style: TextStyle(fontSize: 12, color: Colors.grey)),
                                
                                SizedBox(height: 5),
                                // Privacy Badge
                                Row(
                                  children: [
                                    Icon(Icons.lock_outline, size: 12, color: Colors.green),
                                    SizedBox(width: 4),
                                    Text("Anonymous Submission", style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                
                                SizedBox(height: 20),
                                
                                // INPUT: Message Content
                                TextField(
                                  controller: _msgController,
                                  focusNode: _focusNode, // Auto-focus the message field
                                  maxLines: 5,
                                  minLines: 3,
                                  decoration: InputDecoration(
                                    labelText: "Paste the phishing message here...",
                                    alignLabelWithHint: true,
                                    labelStyle: TextStyle(color: Colors.grey),
                                    filled: true,
                                    fillColor: Color(0xFFF5F7FA),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: EdgeInsets.all(15),
                                  ),
                                ),
                                
                                SizedBox(height: 20),
                                
                                // Action Buttons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text("Cancel", style: TextStyle(color: Colors.grey)),
                                    ),
                                    SizedBox(width: 10),
                                    ElevatedButton(
                                      onPressed: () async { // 1. Made async
                                        if (_msgController.text.isNotEmpty) {
                                          try {
                                            // 2. Call the submit function
                                            await appState.submitReport(_msgController.text);
                                            
                                            // 3. Close dialog & Show Success
                                            if (context.mounted) {
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text("Report sent securely!"), 
                                                  backgroundColor: Colors.green
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text("Failed to send. Check logs."), 
                                                  backgroundColor: Colors.red
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFF229ED9),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      ),
                                      child: Text("Submit Report", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
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

// Helper: Scan Item Tile
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
              Text("${(item.confidence * 100).toInt()}%", style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
            ],
          )
        ],
      ),
    );
  }
}