import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_state.dart';
import '../views/library_page.dart';
import 'scan_result_page.dart';
import '../widgets/scan_item_tile.dart';
import 'privacy_policy_page.dart'; 

class HomeDashboard extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final detections = appState.detections;
    final isScanning = appState.listenerEnabled;

    // 🔴 1. ADDED SAFEAREA (Fixes "misplaced" top UI)
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. MANUAL SCAN TRIGGER
            Hero(
              tag: 'search_bar', 
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (!appState.termsAccepted) {
                      _showTermsDialog(context);
                    } else {
                      _showManualScanDialog(context, appState);
                    }
                  },
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

            // 2. HERO SECTION
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => isScanning 
                        ? appState.stopListening() 
                        : appState.startListening(context), 
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
                _buildActionCard(context, Icons.menu_book, "Library", "Learn tactics", 
                    () => Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => LibraryPage())
                    )
                ),
                _buildActionCard(context, Icons.flag_outlined, "Report", "Flag error",
                    () => _showReportDialog(context, appState)),
              ],
            ),

            SizedBox(height: 30),

            // 4. RECENT SCANS LIST (Improved Empty State)
            Text("Recent Scans", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 15),
            
            if (detections.isEmpty)
               // 🔴 BETTER EMPTY STATE DESIGN
               Center(
                 child: Container(
                   margin: EdgeInsets.only(top: 20),
                   padding: EdgeInsets.all(30),
                   child: Column(
                     children: [
                       Icon(Icons.history, size: 40, color: Colors.grey.shade300),
                       SizedBox(height: 10),
                       Text(
                         "No scans yet", 
                         style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500)
                       ),
                     ],
                   ),
                 )
               )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: detections.take(3).length,
                itemBuilder: (context, index) => ScanItemTile(item: detections[index]),
              ),
          ],
        ),
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.policy, color: Color(0xFF229ED9)),
            SizedBox(width: 10),
            Text("Agreement Required", style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Text(
          "Before using PhishWatch, you must read and accept our Privacy Policy and Terms of Service.",
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); 
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => PrivacyPolicyPage())
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF229ED9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text("Go to Policy", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MANUAL SCAN DIALOG (With Loading State)
  // ==========================================
  void _showManualScanDialog(BuildContext parentContext, AppState appState) {
    final TextEditingController _dialogSearchController = TextEditingController();
    final FocusNode _focusNode = FocusNode();

    Future.delayed(Duration(milliseconds: 600), () {
      if (_focusNode.canRequestFocus) {
        _focusNode.requestFocus();
      }
    });

    Navigator.of(parentContext).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black54,
        transitionDuration: Duration(milliseconds: 500),
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          
          return StatefulBuilder(
            builder: (context, setState) {
              bool _isLoading = false; 

              void _startScan() async {
                if (_dialogSearchController.text.isEmpty) return;

                setState(() => _isLoading = true);

                try {
                  final result = await appState.manualScan(parentContext, _dialogSearchController.text);

                  if (result != null && parentContext.mounted) {
                    Navigator.pop(dialogContext); 
                    
                    Navigator.push(
                      parentContext,
                      MaterialPageRoute(
                        builder: (context) => ScanResultPage(
                          message: result.message,
                          confidence: result.confidence,
                          isPhishing: result.isPhishing,
                        ),
                      ),
                    );
                  } else {
                    setState(() => _isLoading = false); 
                  }
                } catch (e) {
                  setState(() => _isLoading = false);
                  if (parentContext.mounted) {
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
                    );
                  }
                }
              }

              return Scaffold(
                backgroundColor: Colors.transparent,
                resizeToAvoidBottomInset: false, 
                body: LayoutBuilder(
                  builder: (context, constraints) {
                    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
                    final availableHeight = constraints.maxHeight - bottomInset - 40;

                    return Stack(
                      children: [
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: _isLoading ? null : () => Navigator.pop(dialogContext),
                            behavior: HitTestBehavior.opaque,
                            child: Container(color: Colors.transparent),
                          ),
                        ),
                        
                        Center(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: bottomInset),
                            child: Hero(
                              tag: 'search_bar',
                              child: Material(
                                color: Colors.transparent,
                                child: Container(
                                  margin: EdgeInsets.all(20),
                                  constraints: BoxConstraints(
                                    maxHeight: availableHeight > 0 ? availableHeight : 300,
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
                                      Text("Message Check", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      SizedBox(height: 15),
                                      
                                      TextField(
                                        controller: _dialogSearchController,
                                        focusNode: _focusNode,
                                        enabled: !_isLoading, 
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
                                      
                                      if (_isLoading)
                                        Center(
                                          child: SizedBox(
                                            height: 30, width: 30,
                                            child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF229ED9)),
                                          ),
                                        )
                                      else
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(dialogContext),
                                              child: Text("Cancel", style: TextStyle(color: Colors.grey)),
                                            ),
                                            SizedBox(width: 10),
                                            ElevatedButton.icon(
                                              onPressed: () {
                                                if (_dialogSearchController.text.isNotEmpty) {
                                                  setState(() => _isLoading = true); 
                                                  
                                                  appState.manualScan(parentContext, _dialogSearchController.text).then((result) {
                                                    if (!context.mounted) return;
                                                    
                                                    if (result != null) {
                                                      Navigator.pop(dialogContext); 
                                                      Navigator.push(
                                                        parentContext,
                                                        MaterialPageRoute(
                                                          builder: (context) => ScanResultPage(
                                                            message: result.message,
                                                            confidence: result.confidence,
                                                            isPhishing: result.isPhishing,
                                                          ),
                                                        ),
                                                      );
                                                    } else {
                                                      setState(() => _isLoading = false);
                                                    }
                                                  }).catchError((e) {
                                                    if (context.mounted) {
                                                      setState(() => _isLoading = false);
                                                      ScaffoldMessenger.of(parentContext).showSnackBar(
                                                        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
                                                      );
                                                    }
                                                  });
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Color(0xFF229ED9),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                              ),
                                              label: Text("Check Now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                              icon: Icon(Icons.shield_outlined, color: Colors.white, size: 18),
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
            }
          );
        },
      ),
    );
  }

  void _showReportDialog(BuildContext context, AppState appState) {
    final TextEditingController _msgController = TextEditingController();
    final FocusNode _focusNode = FocusNode();

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
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        behavior: HitTestBehavior.opaque,
                        child: Container(color: Colors.transparent),
                      ),
                    ),
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
                                Row(
                                  children: [
                                    Icon(Icons.lock_outline, size: 12, color: Colors.green),
                                    SizedBox(width: 4),
                                    Text("Anonymous Submission", style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                SizedBox(height: 20),
                                TextField(
                                  controller: _msgController,
                                  focusNode: _focusNode,
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text("Cancel", style: TextStyle(color: Colors.grey)),
                                    ),
                                    SizedBox(width: 10),
                                    ElevatedButton(
                                      onPressed: () async {
                                        if (_msgController.text.isNotEmpty) {
                                          try {
                                            // 🔴 FIX: Added 'context' here
                                            await appState.submitReport(context, _msgController.text);
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