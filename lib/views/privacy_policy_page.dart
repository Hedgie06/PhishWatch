import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class PrivacyPolicyPage extends StatefulWidget {
  @override
  _PrivacyPolicyPageState createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  // Local state for the checkbox on this page
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    // If they already accepted previously, show it as checked
    if (appState.termsAccepted) {
      _isChecked = true;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Terms & Privacy", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // 1. SCROLLABLE LEGAL TEXT
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle("End User License Agreement (EULA)"),
                  _buildText(
                    "This application ('PhishWatch') is a Final Year Project designed for educational and research purposes. "
                    "By using this software, you acknowledge and agree to the following terms."
                  ),

                  // 1. NATURE OF SERVICE
                  _buildHeader("1. Nature of Service"),
                  _buildText(
                    "PhishWatch utilizes advanced Machine Learning models specifically trained to classify phishing attempts in the **Bahasa Melayu** language. "
                    "This capability is designed to protect users against local financial scams and SMS threats commonly found in Malaysia."
                  ),
                  _buildText(
                    "\n**Please Note:** The system is optimized for Malay text. It may not accurately detect threats in English or other languages."
                  ),
                  _buildText(
                    "\nWhile we strive for high accuracy, no AI system is 100% perfect. "
                    "This app provides *suggestions* only and should not be the sole basis for your financial or security decisions."
                  ),

                  // 2. LIABILITY
                  _buildHeader("2. Limitation of Liability"),
                  _buildText(
                    "TO THE MAXIMUM EXTENT PERMITTED BY LAW, THE DEVELOPER SHALL NOT BE LIABLE FOR ANY DIRECT, INDIRECT, "
                    "INCIDENTAL, OR CONSEQUENTIAL DAMAGES RESULTING FROM THE USE OR INABILITY TO USE THIS APPLICATION, "
                    "INCLUDING BUT NOT LIMITED TO FINANCIAL LOSS DUE TO UNDETECTED SCAMS."
                  ),
                  _buildHighlight("You use this application at your own risk."),

                  // 3. DATA PRIVACY
                  _buildHeader("3. Data Privacy & Sovereignty"),
                  _buildText(
                    "We implement a 'Local-First' architecture to protect your privacy:"
                  ),
                  _buildBullet("Safe Messages: Processed locally on your device (RAM) and immediately discarded. We do not store your private conversations."),
                  
                  _buildBullet("Threat Intelligence: If a message is identified as 'High Risk' (Phishing), the specific content is **stored in our secure database**. This allows us to analyze new scam patterns and improve the detection model."),
                  
                  // 4. PERMISSIONS
                  _buildHeader("4. Permissions"),
                  _buildText(
                    "We require 'Notification Access' strictly to analyze incoming text patterns. "
                    "We do not read, store, or transmit data from unsupported applications."
                  ),
                  
                  _buildText(
                    "\n**Real-Time Alerts (Optional):**\n"
                    "By enabling permissions, you also opt-in to receive immediate alert notifications if a phishing attempt is detected. "
                    "These alerts are designed to warn you in real-time. You can disable these alerts in the Settings."
                  ),

                  SizedBox(height: 30),
                  Divider(),
                  SizedBox(height: 10),
                  Text("Version 1.0.0 (Beta)", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),

          // 2. AGREEMENT CHECKBOX AREA (Fixed at bottom)
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _isChecked,
                      activeColor: Color(0xFF229ED9),
                      onChanged: (val) {
                        setState(() {
                          _isChecked = val ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: Text(
                        "I have read and agree to the Terms of Service and Privacy Policy.",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isChecked 
                        ? () {
                            // Update Global State
                            appState.acceptTerms();
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Agreement Accepted"), backgroundColor: Colors.green)
                            );
                          } 
                        : null, // Disable button if not checked
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF229ED9),
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text("CONFIRM & CONTINUE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---
  Widget _buildTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Text(text, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87)),
    );
  }

  Widget _buildHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 25, bottom: 10),
      child: Text(text.toUpperCase(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: 1.0)),
    );
  }

  Widget _buildText(String text) {
    // Basic Markdown styling for **Bold**
    List<TextSpan> spans = [];
    text.split("**").asMap().forEach((index, part) {
      if (index % 2 == 1) {
        // Bold part
        spans.add(TextSpan(text: part, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)));
      } else {
        // Normal part
        spans.add(TextSpan(text: part));
      }
    });

    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 15, height: 1.6, color: Colors.grey.shade800),
        children: spans,
      ),
    );
  }

  Widget _buildHighlight(String text) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
      child: Text(text, style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("• ", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF229ED9))),
          Expanded(child: Text(text, style: TextStyle(fontSize: 15, height: 1.5, color: Colors.grey.shade800))),
        ],
      ),
    );
  }
}