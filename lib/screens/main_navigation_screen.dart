import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';
import 'matches_screen.dart';
import 'search_screen.dart';
import 'inbox_screen.dart';
import 'profile_screen.dart';

/// Main Application Navigation Shell
/// Features the 5 requested tabs with modern Cupertino icons:
/// 1. Home
/// 2. Feed
/// 3. Search
/// 4. Interests
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          RaniHomeScreen(
            onOpenSearch: () => _navigateToTab(2),
            onOpenFilter: () => _navigateToTab(2),
            onOpenProfile: () => _navigateToTab(4),
          ),
          const RaniMatchesScreen(),
          const RaniSearchScreen(),
          const RaniInboxScreen(),
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
          selectedItemColor: const Color(0xFF750000), // Theme Burgundy
          unselectedItemColor: const Color(0xFF7A7A7A),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          onTap: _navigateToTab,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.house, size: 22),
              activeIcon: Icon(CupertinoIcons.house_fill, size: 22),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.compass, size: 22),
              activeIcon: Icon(CupertinoIcons.compass_fill, size: 22),
              label: 'Feed',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.search, size: 22),
              activeIcon: Icon(CupertinoIcons.search, size: 22),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.heart, size: 22),
              activeIcon: Icon(CupertinoIcons.heart_fill, size: 22),
              label: 'Interests',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.person, size: 22),
              activeIcon: Icon(CupertinoIcons.person_fill, size: 22),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
