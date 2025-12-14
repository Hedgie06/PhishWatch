import 'package:flutter/material.dart';

class ScanResultPage extends StatelessWidget {
  final String message;
  final double confidence; // Raw API score (0.0 to 1.0)
  final bool isPhishing;

  const ScanResultPage({
    Key? key,
    required this.message,
    required this.confidence,
    required this.isPhishing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1. Calculate Display Percentage
    // If Safe, we invert it (e.g., 0.1 spam score = 90% Safe)
    double displayConfidence = isPhishing ? confidence : (1.0 - confidence);
    
    // 2. Determine TIER (Color, Text, Icon)
    Color statusColor;
    String statusText;
    String adviceText;
    IconData statusIcon;

    if (!isPhishing) {
      // --- SAFE TIER ---
      statusColor = Colors.green;
      statusText = "Safe Message";
      statusIcon = Icons.verified_user;
      adviceText = "No phishing patterns detected. However, always stay vigilant.";
    } else {
      // --- PHISHING TIERS ---
      if (confidence >= 0.90) {
        // TIER 1: CRITICAL (90% - 100%)
        statusColor = Color(0xFFD32F2F); // Darker Red
        statusText = "CRITICAL THREAT";
        statusIcon = Icons.block;
        adviceText = "This message is definitely a scam. It matches known phishing patterns perfectly. Do not click any links or reply.";
      } 
      else if (confidence >= 0.75) {
        // TIER 2: HIGH RISK (75% - 89%) -> Covers your 83% case
        statusColor = Colors.red;
        statusText = "DANGER: High Risk";
        statusIcon = Icons.gpp_bad;
        adviceText = "This message is highly likely to be a scam. Do not click any links or reply.";
      } 
      else {
        // TIER 3: SUSPICIOUS (50% - 74%)
        statusColor = Colors.orange;
        statusText = "WARNING: Suspicious";
        statusIcon = Icons.warning_amber_rounded;
        adviceText = "This message looks unusual. It shares some characteristics with spam. Verify with the sender before taking action.";
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 10),
                    
                    // 1. BIG CIRCULAR GAUGE
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: CircularProgressIndicator(
                            value: displayConfidence,
                            strokeWidth: 20,
                            backgroundColor: Colors.grey[100],
                            color: statusColor,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${(displayConfidence * 100).toInt()}%",
                              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: statusColor),
                            ),
                            Text("Confidence", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),

                    SizedBox(height: 40),

                    // 2. STATUS TITLE
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 30),
                        SizedBox(width: 10),
                        Text(
                          statusText,
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: statusColor),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    // 3. SCANNED MESSAGE PREVIEW
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Analyzed Content:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          SizedBox(height: 5),
                          Text(
                            message,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // 4. ACTIONABLE ADVICE
                    Container(
                      padding: EdgeInsets.all(20),
                      margin: EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: statusColor),
                          SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              adviceText,
                              style: TextStyle(color: Colors.black87, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // 5. DONE BUTTON
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: statusColor,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: Text("Done", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}