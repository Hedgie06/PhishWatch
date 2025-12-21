import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'privacy_policy_page.dart';

class OnboardingPage extends StatefulWidget {
  @override
  _OnboardingPageState createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  List<Widget> _buildPages() {
    return [
      // PAGE 1: WELCOME 
      _buildPage(
        imagePath: 'assets/icon/app_icon.png', 
        title: "Welcome to PhishWatch",
        description: "Your intelligent guardian against Telegram scams. Specifically designed for detecting threats in the Malay language.",
      ),
      // PAGE 2: HOW IT WORKS
      _buildPage(
        icon: Icons.notifications_active_outlined,
        title: "Real-Time Protection",
        description: "We analyze incoming Telegram notifications instantly. If a scam is detected, we alert you before you act.",
      ),
      // PAGE 3: PRIVACY & PERMISSIONS
      _buildPage(
        icon: Icons.lock_outline,
        title: "Privacy First",
        description: "Your messages are analyzed anonymously to detect threats. We respect your data and privacy.",
        isLastPage: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // SKIP BUTTON
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 20, top: 10),
                child: _currentIndex == pages.length - 1
                    ? SizedBox(height: 48) // Hide Skip on last page
                    : TextButton(
                        onPressed: () => _pageController.jumpToPage(pages.length - 1),
                        child: Text("Skip", style: TextStyle(color: Colors.grey)),
                      ),
              ),
            ),

            // PAGE VIEW (SLIDER)
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                children: pages,
              ),
            ),

            // DOT INDICATORS
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pages.length, (index) {
                return AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentIndex == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentIndex == index ? Color(0xFF229ED9) : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),

            SizedBox(height: 30),

            // BOTTOM BUTTON AREA
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: _currentIndex == pages.length - 1
                    ? ElevatedButton(
                        // Open Privacy Policy instead of instant accept
                        onPressed: () {
                          Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (_) => PrivacyPolicyPage())
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF229ED9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 2,
                        ),
                        child: Text("Get Started", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      )
                    : ElevatedButton(
                        onPressed: () {
                          _pageController.nextPage(
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Color(0xFF229ED9), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 0,
                        ),
                        child: Text("Next", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF229ED9))),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

 // --- HELPER: BUILD SINGLE SLIDE ---
  Widget _buildPage({
    IconData? icon,
    String? imagePath, // Added optional image path
    required String title,
    required String description,
    bool isLastPage = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          
          // 🔴 UPDATED LOGO LOGIC
          imagePath != null
              ? Container(
                  height: 160, // Slightly larger for the main logo
                  width: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Add a soft shadow to make it pop
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.2), 
                        blurRadius: 20, 
                        offset: Offset(0, 10)
                      )
                    ],
                  ),
                  // ✂️ THE FIX: This cuts the square image into a perfect circle
                  child: ClipOval(
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover, // Forces the image to fill the entire circle
                    ),
                  ),
                )
              : Container(
                  // Keep the original look for the standard Icons (Pages 2 & 3)
                  padding: EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F7FA),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 100, color: Color(0xFF229ED9)),
                ),

          SizedBox(height: 40),
          
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          
          SizedBox(height: 20),
          
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.5),
          ),
        ],
      ),
    );
  }
}