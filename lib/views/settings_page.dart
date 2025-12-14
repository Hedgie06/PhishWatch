import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Settings", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87)),
              SizedBox(height: 30),

              // 1. GENERAL SECTION
              _buildSectionHeader("General"),
              Container(
                decoration: _boxDecoration(),
                child: Column(
                  children: [
                    // Notifications (Blue Theme)
                    _buildSwitchTile(
                      context,
                      title: "Notifications",
                      subtitle: "Receive alert notifications",
                      icon: Icons.notifications_active,
                      iconColor: Colors.blue,
                      value: appState.notificationsEnabled,
                      onChanged: (val) => appState.toggleNotifications(context, val),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 25),

              // 🔴 DELETED: The "Data" section is gone.
              // We moved the Delete button to the Activity Page where it belongs.

              // 2. ABOUT SECTION
              _buildSectionHeader("About"),
              Container(
                decoration: _boxDecoration(),
                child: Column(
                  children: [
                    _buildActionTile(
                      context,
                      title: "Version",
                      trailingText: "1.0.0 (Beta)",
                      icon: Icons.info_outline,
                      iconColor: Colors.purple,
                      onTap: () {}, 
                    ),
                    _buildDivider(),
                    _buildActionTile(
                      context,
                      title: "Privacy Policy",
                      icon: Icons.shield_outlined,
                      iconColor: Colors.teal,
                      onTap: () {}, 
                    ),
                    
                    // Hidden Developer Stats (Subtle)
                    _buildDivider(),
                    Consumer<AppState>(
                      builder: (context, appState, child) {
                        return Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.query_stats, size: 14, color: Colors.grey.shade400),
                              SizedBox(width: 8),
                              Text(
                                "Global Threats Intercepted: ${appState.totalThreatsIntercepted}",
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 40),
              Center(
                child: Text("Designed for FYP 2025", style: TextStyle(color: Colors.grey.shade400, fontSize: 12, letterSpacing: 1.0)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 10),
      child: Text(
        title.toUpperCase(), 
        style: TextStyle(
          color: Colors.grey.shade600, 
          fontSize: 13, 
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1
        ),
      ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: Offset(0, 5)),
      ],
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 0.5, indent: 60, endIndent: 20, color: Colors.grey.shade200);
  }

  Widget _buildSwitchTile(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1), 
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: iconColor,
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    String? trailingText,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title, 
        style: TextStyle(
          fontWeight: FontWeight.bold, 
          fontSize: 16,
          color: isDestructive ? Colors.red : Colors.black87
        )
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null) 
            Text(trailingText, style: TextStyle(color: Colors.grey, fontSize: 14)),
          if (trailingText != null) SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade300),
        ],
      ),
    );
  }
}