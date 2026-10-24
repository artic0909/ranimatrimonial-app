import 'package:flutter/material.dart';
import '../theme/rani_colors.dart';
import '../theme/rani_spacing.dart';
import '../theme/rani_typography.dart';
import 'home_screen.dart';
import 'search_screen.dart';

/// Main Application Navigation Shell
/// Features the signature #1A0000 Bottom Navigation Bar with gold active icons
class RaniMainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const RaniMainNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<RaniMainNavigationScreen> createState() => _RaniMainNavigationScreenState();
}

class _RaniMainNavigationScreenState extends State<RaniMainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const RaniHomeScreen(),
          const RaniSearchScreen(),
          _buildPlaceholderTab(
            title: 'Your Matches',
            subtitle: 'AI-curated recommendations based on your preferences',
            icon: Icons.favorite,
          ),
          _buildPlaceholderTab(
            title: 'Messages',
            subtitle: 'Chat and communicate with interested matches',
            icon: Icons.chat_bubble_outline,
          ),
          _buildPlaceholderTab(
            title: 'My Profile',
            subtitle: 'Manage your photos, horoscope, and partner preferences',
            icon: Icons.person_outline,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: RaniColors.surfaceAlt,
          border: Border(
            top: BorderSide(
              color: RaniColors.gold,
              width: 0.8,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              activeIcon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline),
              activeIcon: Icon(Icons.favorite),
              label: 'Matches',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderTab({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Scaffold(
      backgroundColor: RaniColors.canvas,
      appBar: AppBar(
        title: Text(title, style: RaniTypography.headingSm(color: Colors.white)),
        backgroundColor: RaniColors.surfaceAlt,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(RaniSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: RaniColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: RaniColors.gold, width: 1.0),
                ),
                child: Icon(icon, color: RaniColors.primary, size: 40),
              ),
              const SizedBox(height: RaniSpacing.md),
              Text(
                title,
                style: RaniTypography.headingMd(color: RaniColors.ink),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: RaniSpacing.xs),
              Text(
                subtitle,
                style: RaniTypography.bodySm(color: RaniColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
