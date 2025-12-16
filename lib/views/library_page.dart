import 'package:flutter/material.dart';

class LibraryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA), // Main scaffold background
      appBar: AppBar(
        title: Text("Learn Common Tactics", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),

            // ===========================================
            // SECTION 1: HEADER
            // ===========================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text("Anatomy of Phishing Attempt", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.red.withOpacity(0.3))
                    ),
                    child: Text("HIGH RISK", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
                  )
                ],
              ),
            ),
            SizedBox(height: 20),

            // ===========================================
            // THE TELEGRAM CHAT SIMULATION
            // ===========================================
            Container(
              margin: EdgeInsets.symmetric(horizontal: 15), 
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
              decoration: BoxDecoration(
                // 🔴 1. BACKGROUND COLOR CHANGED TO 0xFFF5F7FA (Light Grey)
                color: Color(0xFFF5F7FA), 
                borderRadius: BorderRadius.circular(15),
                // Optional: Add a subtle border or shadow to separate it from the white background
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fake Sender Info Header
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 18,
                        child: Icon(Icons.person, color: Colors.grey.shade400),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🔴 2. PHONE NUMBER UPDATED
                          Text("+601X-XXXX XXXX", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                          Text("online", style: TextStyle(fontSize: 12, color: Colors.blue)),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // THE REALISTIC TELEGRAM BUBBLE WITH TAIL
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // The tiny tail on the left (Wrapped in Padding)
                      Padding(
                        padding: const EdgeInsets.only(top: 0), 
                        child: CustomPaint(
                          painter: _TelegramTailPainter(),
                          child: SizedBox(width: 6, height: 10),
                        ),
                      ),
                      
                      // The main bubble
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.zero, // Connects to tail
                              topRight: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: Offset(0, 1))
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Sender Name inside bubble
                              Text(
                                "+601X-XXXX XXXX", // Updated inside bubble too
                                style: TextStyle(color: Color(0xFF498FD5), fontWeight: FontWeight.bold, fontSize: 13)
                              ),
                              Text(
                                "Forwarded message", 
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontStyle: FontStyle.italic)
                              ),
                              SizedBox(height: 5),
                              
                              // Content
                              Text(
                                """🎊🎉Bantuan Ramadhan 2025 : Cara Mohon & Syarat Kelayakan

Jom semak sekarang!!!🎉🎉
Dah boleh claim Bantuan Awal Ramadhan RM 500, Buat korg yg bertujuan untuk membantu meringankan bebanan rakyat Malaysia terutamanya kepada golongan isi rumah yang kurang berkemampuan... untuk semua rakyat malaysia, insyaallah semua boleh dpt 😇
semak sekarang 👇
https://berkaramadan02.v11-2025.my.id/

JOM 🗣 "SHARE" Bantuan Ini ke family and kawan-kawan TQ""",
                                style: TextStyle(fontSize: 14, height: 1.3, color: Colors.black),
                              ),
                              
                              SizedBox(height: 4),
                              // Timestamp tucked in corner
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text("2:30 PM", style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Source Watermark
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.bookmark_border, size: 12, color: Colors.grey.shade600),
                      SizedBox(width: 4),
                      Text(
                        "Source: AsamAlert group",
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 25),
            Divider(indent: 20, endIndent: 20),
            SizedBox(height: 10),

            // The "Forensic" Analysis
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text("⚠️ BREAKDOWN", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            SizedBox(height: 15),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildAnalysisPoint(
                    "1", 
                    "Unofficial Domain (.my.id)", 
                    "Inspect the URL. Official Malaysian government aid portals always end with '.gov.my'. This link uses a foreign country code (.id). This mismatch is a guaranteed red flag."
                  ),
                  _buildAnalysisPoint(
                    "2", 
                    "Unrealistic Eligibility", 
                    "Claims 'semua rakyat boleh dapat' (everyone gets it) are a psychological hook. Real government aid targets specific groups (e.g., B40) and always requires a formal database check."
                  ),
                  _buildAnalysisPoint(
                    "3", 
                    "Viral Mechanics", 
                    "The instruction to 'SHARE' to family is a 'Viral Loop'. Scammers use your trusted network to spread the malicious link, knowing your family is more likely to click if you sent it."
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),
            
            // SECTION 2: COLLAPSIBLE DEFENSE GUIDE
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: Text("General Defense Guide", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                subtitle: Text("4 Rules to stay safe online", style: TextStyle(color: Colors.grey)),
                childrenPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildDetailTipCard(
                        Icons.link, 
                        "Check The URL", 
                        "Hover before you click. Look for strange domains or misspellings (e.g., 'bank-secure-login.com'). If in doubt, type the official address yourself."
                      )),
                      SizedBox(width: 15),
                      Expanded(child: _buildDetailTipCard(
                        Icons.access_time, 
                        "Ignore Urgency", 
                        "Scammers use fear ('Your account will be locked!'). Official organizations never pressure you to act instantly via text message."
                      )),
                    ],
                  ),
                  SizedBox(height: 15),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildDetailTipCard(
                        Icons.share, 
                        "Verify First", 
                        "Just because a friend sent it doesn't mean it's safe. Their device might be compromised. Always verify with official news sources."
                      )),
                      SizedBox(width: 15),
                      Expanded(child: _buildDetailTipCard(
                        Icons.money_off, 
                        "No Free Money", 
                        "Legitimate aid is never claimed via unofficial online forms or personal messaging apps. It always requires logging into a secure government portal."
                      )),
                    ],
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),

            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- HELPER: DETAILED TIPS ---
  Widget _buildDetailTipCard(IconData icon, String title, String subtitle) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Color(0xFF229ED9), size: 28),
          SizedBox(height: 12),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
          SizedBox(height: 6),
          Text(
            subtitle, 
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3),
          ),
        ],
      ),
    );
  }

  // --- HELPER: ANALYSIS POINTS ---
  Widget _buildAnalysisPoint(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20), 
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24, height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
            child: Text(number, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                SizedBox(height: 4),
                Text(description, style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.5)), 
              ],
            ),
          )
        ],
      ),
    );
  }
}

// THE PAINTER: Creates the bottom-left tail for Telegram bubble
class _TelegramTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    var path = Path();
    path.moveTo(0, size.height); // Bottom left point
    path.lineTo(size.width, size.height); // Bottom right point
    path.lineTo(size.width, 0); // Top right point
    path.quadraticBezierTo(size.width / 2, size.height / 2, 0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}