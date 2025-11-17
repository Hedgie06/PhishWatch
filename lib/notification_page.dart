import 'package:flutter/material.dart';
import 'package:phishwatch/services/alert_service.dart';
import 'package:phishwatch/services/notification_service.dart';
import 'package:phishwatch/services/api_service.dart';
import 'package:phishwatch/widgets/search_overlay.dart';
import 'dart:ui';
//import 'result_page.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with SingleTickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  final ApiService _apiService = ApiService(
    customBaseUrl: "http://172.20.10.6:5000", // must according to PC IP
  );

  final List<Map<String, dynamic>> _safeNotifications = [];
  final List<Map<String, dynamic>> _dangerousNotifications = [];

  late TabController _tabController;

  // 🔍 Added for search feature
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.delayed(const Duration(seconds: 1), _initListener);
  }

  Future<void> _initListener() async {
    final enabled = await _notificationService.isListenerEnabled();
    if (!enabled && mounted) {
      await _notificationService.openListenerSettings();
    }
    await _notificationService.startService();

    _notificationService.onNotification.listen((data) async {
      if (!mounted) return;

      final messageText = data['text'] ?? '';

      try {
        final result = await _apiService.classifyMessage(messageText);

        // Skip Telegram summary notifications but show a quick popup
        final appName = (data['app'] ?? '').toString().toLowerCase();
        if (appName.contains('telegram') &&
            (data['text']?.toString().contains('new messages') ?? false)) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text("🔄 Listening active – Telegram notification skipped"),
              duration: Duration(milliseconds: 1500),
            ),
          );
          return;
        }

        setState(() {
          // Prevent duplicates based on title + text + app name
          bool isDuplicate(
              List<Map<String, dynamic>> list, Map<String, dynamic> item) {
            return list.any((existing) =>
                existing['title'] == item['title'] &&
                existing['text'] == item['text'] &&
                existing['app'] == item['app']);
          }

          if (result['prediction'] == 'spam') {
            if (!isDuplicate(_dangerousNotifications, data)) {
              _dangerousNotifications.insert(0, data);
            }

            // Wait 3 seconds before showing alert to avoid clumping with original message
            Future.delayed(const Duration(seconds: 3), () {
              AlertService.showDangerAlert(
                "⚠️ Dangerous Message Detected",
                data['text'] ?? 'Suspicious content identified.',
              );
            });
          } else {
            if (!isDuplicate(_safeNotifications, data)) {
              _safeNotifications.insert(0, data);
            }
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${result['prediction'] == 'spam' ? '⚠️ Dangerous' : '✅ Safe'}: ${data['title'] ?? 'No title'}",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (e) {
        debugPrint("❌ API Error: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "🚫 Failed to connect to API: $e",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    });
  }

  Widget _buildList(List<Map<String, dynamic>> list,
      {bool isDangerous = false}) {
    if (list.isEmpty) {
      return const Center(
        child: Text(
          "No notifications yet.",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
        await _notificationService.startService();
        await _initListener();
      },
      color: const Color(0xFF229ED9),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final notif = list[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDangerous
                  ? const Color(0xFFFFF5F5)
                  : const Color.fromARGB(255, 241, 240, 240),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListTile(
              title: Text(
                notif['title'] ?? 'No title',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                notif['text'] ?? 'No text',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
              leading: const Icon(
                Icons.telegram,
                color: Color(0xFF229ED9),
                size: 28,
              ),
              trailing: Text(
                notif['app'] ?? '',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          );
        },
      ),
    );
  }

  // 🔍 Added: build the overlay for search
  Widget _buildSearchOverlay(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isSearching = false;
            _searchController.clear();
          });
        },
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: "Check phishy message here...",
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        final query = _searchController.text.trim();
                        if (query.isNotEmpty) {
                          // TODO: Navigate to result screen or call API
                          debugPrint("Search query: $query");
                          setState(() => _isSearching = false);
                        }
                      },
                    ),
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      debugPrint("Search query: $value");
                      setState(() => _isSearching = false);
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "PhishWatch",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 30,
          ),
        ),
        backgroundColor: const Color(0xFF229ED9),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
          tabs: const [
            Tab(text: "Safe"),
            Tab(text: "Dangerous"),
          ],
        ),
        actions: [
          // 🔍 Search icon
          IconButton(
            icon: const Icon(
              Icons.search, 
              color: Colors.white,
              size: 30,
              ),
            onPressed: () {
              setState(() {
                _isSearching = true;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildList(_safeNotifications),
              _buildList(_dangerousNotifications, isDangerous: true),
            ],
          ),
          if (_isSearching)
            SearchOverlay(
              onClose: () {
                setState(() => _isSearching = false);
              },
              onSubmit: (query) {
                debugPrint("Search query: $query");
                setState(() => _isSearching = false);
              },
            ),
        ],
      ),
    );
  }
}
