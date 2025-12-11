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