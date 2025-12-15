import 'package:flutter/material.dart';

class ScanResultPage extends StatelessWidget {
  final String message;
  final double confidence; // Raw probability from API (e.g. 0.48)
  final bool isPhishing;

  const ScanResultPage({
    Key? key,
    required this.message,
    required this.confidence,
    required this.isPhishing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 🔴 STANDARDIZED LOGIC: Winning Label Confidence
    // If Safe (0.48), we invert it to (0.52) to show "52% Safe"
    final double displayConfidence = isPhishing 
        ? confidence 
        : (1.0 - confidence);

    final int percentage = (displayConfidence * 100).toInt();
    
    // UI Colors & Icons
    final Color themeColor = isPhishing ? Colors.red : Colors.green;
    final String statusText = isPhishing ? "Phishing Detected" : "Safe Message";
    final IconData statusIcon = isPhishing ? Icons.warning_amber_rounded : Icons.check_circle_outline;

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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 20),
                  // 1. CIRCULAR INDICATOR
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: CircularProgressIndicator(
                          value: displayConfidence, 
                          strokeWidth: 20,
                          backgroundColor: Colors.grey.shade100,
                          color: themeColor,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "$percentage%",
                            style: TextStyle(
                              fontSize: 48, 
                              fontWeight: FontWeight.bold, 
                              color: themeColor
                            ),
                          ),
                          Text(
                            "Confidence",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 40),

                  // 2. STATUS LABEL
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(statusIcon, color: themeColor, size: 32),
                      SizedBox(width: 10),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 24, 
                          fontWeight: FontWeight.bold, 
                          color: themeColor
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 30),

                  // 3. SCROLLABLE MESSAGE CONTENT
                  Container(
                    padding: EdgeInsets.all(20),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Analyzed Content:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        SizedBox(height: 8),
                        Text(
                          message,
                          style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // 4. EXPLANATION BOX
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: themeColor),
                        SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            isPhishing
                                ? "This message contains patterns commonly used in financial scams."
                                : "No phishing patterns detected. However, always stay vigilant.",
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),

          // 5. DONE BUTTON
          Padding(
            padding: const EdgeInsets.all(30.0),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: Text("Done", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}