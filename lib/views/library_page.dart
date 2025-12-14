import 'package:flutter/material.dart';

class LibraryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 🔴 CONTENT: Top Scams in Malaysia
    final tactics = [
      {
        "title": "The 'Macau Scam'",
        "tag": "Impersonation",
        "desc": "Scammers pose as police (PDRM), court officials, or LHDN officers. They claim you are involved in a crime, money laundering, or tax evasion.\n\nThey demand a fund transfer to a 'third-party account' for 'investigation' purposes.\n\n🛡️ Safety Tip: Government agencies will NEVER demand money transfers via phone calls.",
        "icon": Icons.phone_locked,
        "color": Colors.red
      },
      {
        "title": "APK Installation Scam",
        "tag": "Malware",
        "desc": "Victims receive a WhatsApp message with an attached file (e.g., 'WeddingInvite.apk', 'MaidService.apk').\n\nInstalling this gives hackers control over your phone to steal SMS TAC/OTP codes and empty your bank account.\n\n🛡️ Safety Tip: Never install apps sent directly through chat. Only use the Play Store.",
        "icon": Icons.android_outlined,
        "color": Colors.green
      },
      {
        "title": "E-Commerce Job Scam",
        "tag": "Job Fraud",
        "desc": "You get a WhatsApp offering a 'part-time job' to boost ratings for products on Shopee or Lazada.\n\nThey ask you to pay for an item first, promising a refund + commission. The refund never comes, and they ask for larger payments.\n\n🛡️ Safety Tip: Legitimate jobs never ask you to pay money to start working.",
        "icon": Icons.work_off_outlined,
        "color": Colors.orange
      },
      {
        "title": "Phishing Links (TAC)",
        "tag": "Credential Theft",
        "desc": "You receive an SMS saying your bank account (Maybank/CIMB) is blocked, with a link like 'cimb-verify-user.com'.\n\nThe website looks real but sends your username and password directly to the scammer.\n\n🛡️ Safety Tip: Always type the bank's website manually into your browser.",
        "icon": Icons.link_off,
        "color": Colors.blue
      },
      {
        "title": "Love / Romance Scam",
        "tag": "Social Engineering",
        "desc": "A stranger befriends you on social media and builds a romantic relationship over months. They claim to send a 'parcel' containing gifts or cash but say it is stuck at customs.\n\nThey ask you to pay 'customs fees' to release it.\n\n🛡️ Safety Tip: Never transfer money to someone you haven't met in person.",
        "icon": Icons.favorite_border,
        "color": Colors.pink
      },
    ];

    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA), // Matches Home Dashboard
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.menu_book_rounded, color: Color(0xFF229ED9)),
            SizedBox(width: 10),
            Text("Security Library", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: false,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(20),
        itemCount: tactics.length,
        itemBuilder: (context, index) {
          final item = tactics[index];
          return Container(
            margin: EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05), 
                  blurRadius: 10, 
                  offset: Offset(0, 4)
                )
              ],
            ),
            child: ExpansionTile(
              shape: Border(), // Removes the default divider lines
              leading: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (item['color'] as Color).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(item['icon'] as IconData, color: item['color'] as Color),
              ),
              title: Text(
                item['title'] as String, 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
              ),
              subtitle: Text(
                item['tag'] as String, 
                style: TextStyle(fontSize: 12, color: Colors.grey)
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Text(
                    item['desc'] as String,
                    style: TextStyle(color: Colors.grey[800], height: 1.5, fontSize: 14),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}