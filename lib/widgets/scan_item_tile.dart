import 'package:flutter/material.dart';
import '../models/detection_item.dart';
import '../views/scan_result_page.dart';

class ScanItemTile extends StatelessWidget {
  final DetectionItem item;
  
  const ScanItemTile({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        // 🔴 CHANGE: Use a subtle light red background for phishing items
        color: item.isPhishing ? Color(0xFFFFF5F5) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05), 
            blurRadius: 10, 
            offset: Offset(0, 5)
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ScanResultPage(
                  message: item.message,
                  confidence: item.confidence,
                  isPhishing: item.isPhishing,
                ),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(15),
            child: Row(
              children: [
                // 1. App Icon
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: item.isPhishing 
                        ? Colors.red.withOpacity(0.1) 
                        : Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.telegram, 
                    color: item.isPhishing ? Colors.red : Colors.green,
                  ),
                ),
                
                SizedBox(width: 15),
                
                // 2. Text Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.app, style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text(
                        item.message, 
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis, 
                        style: TextStyle(color: Colors.grey, fontSize: 12)
                      ),
                    ],
                  ),
                ),
                
                // 3. Status Badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item.isPhishing ? "PHISHING" : "SAFE",
                      style: TextStyle(
                        color: item.isPhishing ? Colors.red : Colors.green, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 12
                      ),
                    ),
                    Text(
                      "${(item.confidence * 100).toInt()}%", 
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 10)
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}