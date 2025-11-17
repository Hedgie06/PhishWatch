import 'dart:ui';
import 'package:flutter/material.dart';

class SearchOverlay extends StatefulWidget {
  final VoidCallback onClose;
  final ValueChanged<String> onSubmit;

  const SearchOverlay({
    Key? key,
    required this.onClose,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<SearchOverlay>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Positioned.fill(
        child: GestureDetector(
          onTap: widget.onClose,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              color: Colors.black.withOpacity(0.4),
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () {}, // prevent closing when tapping input
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          autofocus: true,
                          textInputAction: TextInputAction.search,
                          decoration: const InputDecoration(
                            hintText: "Type a message to check...",
                            border: InputBorder.none,
                          ),
                          onSubmitted: (value) {
                            if (value.trim().isNotEmpty) {
                              widget.onSubmit(value);
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.blueAccent),
                        onPressed: () {
                          final query = _controller.text.trim();
                          if (query.isNotEmpty) widget.onSubmit(query);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
