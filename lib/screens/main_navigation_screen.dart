import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';
import 'matches_screen.dart';
import 'inbox_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

/// Main Application Navigation Shell
/// Replaced "Feed" with "Matches" in the bottom navigation bar per user request.
/// Tabs:
/// 1. Home
/// 2. Matches (Replaced Feed)
/// 3. Inbox
/// 4. Chat (Connected Inquiries & Messaging)
/// 5. Profile
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
  final int _matchesCount = 18;
  final int _inboxCount = 5;
  final int _chatCount = 2;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildNavBadgeIcon({
    required IconData icon,
    int? count,
    double size = 23,
  }) {
    final iconWidget = Icon(icon, size: size);
    if (count == null || count <= 0) return iconWidget;

    return Badge(
      label: Text(
        count > 99 ? '99+' : count.toString(),
        style: GoogleFonts.outfit(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      backgroundColor: const Color(0xFF750000), // Theme Burgundy
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
      child: iconWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // 0. Home
          RaniHomeScreen(
            onOpenSearch: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RaniSearchScreen()),
              );
            },
            onOpenFilter: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RaniSearchScreen()),
              );
            },
            onOpenProfile: () => _navigateToTab(4),
          ),

          // 1. Matches (Replaced Feed)
          RaniMatchesScreen(
            onOpenSearch: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RaniSearchScreen()),
              );
            },
            onOpenNotifications: () => _navigateToTab(2),
          ),

          // 2. Inbox (Inquiries & Requests)
          const RaniInboxScreen(),

          // 3. Chat (Conversations / Connected Matrimonial Chats)
          const RaniInboxScreen(initialTab: 'chats'),

          // 4. Profile & Account
          const RaniProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Color(0xFFEFE8DE),
              width: 1.0,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF750000), // Royal Burgundy Brand Theme
          unselectedItemColor: const Color(0xFF8E8E93),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF750000),
          ),
          unselectedLabelStyle: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          onTap: _navigateToTab,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.house, size: 23),
              activeIcon: Icon(CupertinoIcons.house_fill, size: 23),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: _buildNavBadgeIcon(icon: CupertinoIcons.person_2, count: _matchesCount, size: 24),
              activeIcon: _buildNavBadgeIcon(icon: CupertinoIcons.person_2_fill, count: _matchesCount, size: 24),
              label: 'Matches',
            ),
            BottomNavigationBarItem(
              icon: _buildNavBadgeIcon(icon: CupertinoIcons.mail, count: _inboxCount, size: 22),
              activeIcon: _buildNavBadgeIcon(icon: CupertinoIcons.mail_solid, count: _inboxCount, size: 22),
              label: 'Interests',
            ),
            BottomNavigationBarItem(
              icon: _buildNavBadgeIcon(icon: CupertinoIcons.chat_bubble_2, count: _chatCount, size: 23),
              activeIcon: _buildNavBadgeIcon(icon: CupertinoIcons.chat_bubble_2_fill, count: _chatCount, size: 23),
              label: 'Wallet',
            ),
            const BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.person, size: 23),
              activeIcon: Icon(CupertinoIcons.person_fill, size: 23),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

