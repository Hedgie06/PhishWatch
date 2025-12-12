import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text("Settings", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          
          // 1. Real-time Protection Switch
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

          SizedBox(height: 15),

          // 2. Clear History Button (ADDED HERE)
          GestureDetector(
             onTap: () {
               // Show Confirmation Dialog
               showDialog(
                 context: context,
                 builder: (context) => AlertDialog(
                   backgroundColor: Colors.white,
                   surfaceTintColor: Colors.transparent,
                   title: Text("Clear History?"),
                   content: Text("This will permanently delete all scan logs."),
                   actions: [
                     TextButton(
                       onPressed: () => Navigator.pop(context), 
                       child: Text("Cancel", style: TextStyle(color: Colors.grey))
                     ),
                     TextButton(
                       onPressed: () {
                         // Calls the clear function in AppState
                         Provider.of<AppState>(context, listen: false).clearHistory();
                         Navigator.pop(context); // Close dialog
                         
                         ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(
                             content: Text("History cleared!"),
                             backgroundColor: Colors.red,
                             duration: Duration(seconds: 1),
                           )
                         );
                       }, 
                       child: Text("Clear", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                     ),
                   ],
                 ),
               );
             },
             child: Container(
               width: double.infinity,
               padding: EdgeInsets.all(15),
               decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
               child: Row(
                 children: [
                   Icon(Icons.delete_outline, color: Colors.red),
                   SizedBox(width: 15),
                   Text("Clear Scan History", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                 ],
               ),
             ),
          ),
          
          Spacer(),
          
          // Footer
          Center(child: Text("PhishWatch v1.0\nTelegram Dataset Model", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }
}