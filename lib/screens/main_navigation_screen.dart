import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../components/rani_top_bar.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'matches_screen.dart';
import 'inbox_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'splash_screen.dart';

/// Main Application Navigation Shell
/// Features:
/// - Reusable TopBar (RaniTopBar) dynamically changing according to the active screen
/// - Notification bell with live counting badge
/// - Bottom navigation bar with related icons and titles:
///   1. Home: Rani Matrimonial Logo icon with "Home" title
///   2. Matches: Two people icon with "Matches" title & badge count
///   3. Inbox: Mail icon with "Inbox" title & badge count
///   4. Chat: Message bubble icon with "Chat" title & badge count
///   5. Profile: User profile icon with "Profile" title
/// - Brand Royal Burgundy active color (#750000) and Ivory (#FAF7F2) theme
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _currentIndex;
  final int _notificationCount = 3;
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

  /// Reusable TopBar changeable by active screen
  PreferredSizeWidget _buildTopBarForCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        // Home Screen TopBar
        return RaniTopBar(
          title: 'Home',
          notificationCount: _notificationCount,
          onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
          onNotificationPressed: () => RaniTopBar.showNotificationsSheet(context, _notificationCount),
          actions: [
            IconButton(
              icon: const Icon(CupertinoIcons.slider_horizontal_3, color: Color(0xFF1E1E1E), size: 21),
              tooltip: 'Quick Filter',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RaniSearchScreen()),
                );
              },
            ),
          ],
        );

      case 1:
        // Matches Screen TopBar (Matches user screenshot)
        return RaniTopBar(
          title: 'Matches',
          notificationCount: _notificationCount,
          onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
          onNotificationPressed: () => RaniTopBar.showNotificationsSheet(context, _notificationCount),
        );

      case 2:
        // Inbox Screen TopBar
        return RaniTopBar(
          title: 'Inbox',
          notificationCount: _notificationCount,
          onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
          onNotificationPressed: () => RaniTopBar.showNotificationsSheet(context, _notificationCount),
        );

      case 3:
        // Chat Screen TopBar
        return RaniTopBar(
          title: 'Chat',
          notificationCount: _notificationCount,
          onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
          onNotificationPressed: () => RaniTopBar.showNotificationsSheet(context, _notificationCount),
        );

      case 4:
        // Profile Screen TopBar
        return RaniTopBar(
          title: 'Profile',
          notificationCount: _notificationCount,
          onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
          onNotificationPressed: () => RaniTopBar.showNotificationsSheet(context, _notificationCount),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Color(0xFF750000), size: 22),
              tooltip: 'Log Out',
              onPressed: _showLogoutConfirmDialog,
            ),
          ],
        );

      default:
        return RaniTopBar(
          title: 'Rani Matrimonial',
          notificationCount: _notificationCount,
          onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
        );
    }
  }

  /// Home Brand Logo Icon for Bottom Navigation Bar
  Widget _buildHomeLogoNavIcon({required bool isActive}) {
    return Container(
      width: 25,
      height: 25,
      alignment: Alignment.center,
      child: Opacity(
        opacity: isActive ? 1.0 : 0.55,
        child: Image.asset(
          'assets/logo.png',
          width: 23,
          height: 23,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Icon(
            CupertinoIcons.circle_grid_hex_fill,
            size: 22,
            color: isActive ? const Color(0xFF750000) : const Color(0xFF8E8E93),
          ),
        ),
      ),
    );
  }

  /// Badge indicator wrapper for bottom nav items with counting
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
      backgroundColor: const Color(0xFF750000), // Royal Burgundy Theme
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
      child: iconWidget,
    );
  }

  void _showLogoutConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Log Out',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to log out of Rani Matrimonial?',
          style: GoogleFonts.outfit(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF750000),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ApiService.instance.logout();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const RaniSplashScreen()),
                (route) => false,
              );
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  /// Navigation Drawer opened by the topbar hamburger menu
  Widget _buildDrawer() {
    final candidate = ApiService.instance.candidate;
    final firstName = candidate?['first_name'] ?? 'Candidate';
    final lastName = candidate?['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final candidateCode = candidate?['candidate_code'] ?? candidate?['profile_id'] ?? 'RM00024';
    final photo = candidate?['profile_picture'] ?? '';

    return Drawer(
      backgroundColor: const Color(0xFFFAF7F2),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF750000),
                borderRadius: BorderRadius.only(bottomRight: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFFE5B842),
                    backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                    child: photo.isEmpty
                        ? Text(
                            fullName.isNotEmpty ? fullName[0].toUpperCase() : 'R',
                            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF750000)),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName.isNotEmpty ? fullName : 'Rani Member',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: $candidateCode',
                          style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFFE5B842), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Navigation Links
            _buildDrawerTile(
              icon: CupertinoIcons.sparkles,
              title: 'Discover Matches',
              isSelected: _currentIndex == 1,
              onTap: () {
                Navigator.pop(context);
                _navigateToTab(1);
              },
            ),
            _buildDrawerTile(
              icon: CupertinoIcons.mail,
              title: 'Inbox & Requests',
              count: _inboxCount,
              isSelected: _currentIndex == 2,
              onTap: () {
                Navigator.pop(context);
                _navigateToTab(2);
              },
            ),
            _buildDrawerTile(
              icon: CupertinoIcons.chat_bubble_2,
              title: 'Chats',
              count: _chatCount,
              isSelected: _currentIndex == 3,
              onTap: () {
                Navigator.pop(context);
                _navigateToTab(3);
              },
            ),
            _buildDrawerTile(
              icon: CupertinoIcons.person,
              title: 'My Profile',
              isSelected: _currentIndex == 4,
              onTap: () {
                Navigator.pop(context);
                _navigateToTab(4);
              },
            ),
            _buildDrawerTile(
              icon: CupertinoIcons.search,
              title: 'Advanced Search',
              isSelected: false,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RaniSearchScreen()));
              },
            ),

            const Spacer(),
            const Divider(color: Color(0xFFE8DFD5)),

            // Log Out
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Color(0xFF750000)),
              title: Text(
                'Log Out',
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF750000)),
              ),
              onTap: () {
                Navigator.pop(context);
                _showLogoutConfirmDialog();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required String title,
    int? count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? const Color(0xFF750000) : const Color(0xFF5A5A5A)),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 14.5,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? const Color(0xFF750000) : const Color(0xFF2E2E2E),
        ),
      ),
      trailing: (count != null && count > 0)
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF750000),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            )
          : null,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: _buildTopBarForCurrentScreen(),
      drawer: _buildDrawer(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // 0. Home
          RaniHomeScreen(
            showCandidateHeader: false,
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

          // 1. Matches (Full single-card swipe + tabs)
          RaniMatchesScreen(
            showAppBar: false,
            onOpenSearch: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RaniSearchScreen()),
              );
            },
            onOpenNotifications: () => RaniTopBar.showNotificationsSheet(context, _notificationCount),
          ),

          // 2. Inbox (Inquiries & Requests)
          const RaniInboxScreen(showAppBar: false),

          // 3. Chat (Conversations / Connected Matrimonial Chats)
          const RaniInboxScreen(initialTab: 'chats', showAppBar: false),

          // 4. Profile & Account
          const RaniProfileScreen(showAppBar: false),
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
            // Tab 0: Home with Brand Logo Icon
            BottomNavigationBarItem(
              icon: _buildHomeLogoNavIcon(isActive: false),
              activeIcon: _buildHomeLogoNavIcon(isActive: true),
              label: 'Home',
            ),
            // Tab 1: Matches with dynamic count badge
            BottomNavigationBarItem(
              icon: _buildNavBadgeIcon(icon: CupertinoIcons.person_2, count: _matchesCount, size: 24),
              activeIcon: _buildNavBadgeIcon(icon: CupertinoIcons.person_2_fill, count: _matchesCount, size: 24),
              label: 'Matches',
            ),
            // Tab 2: Inbox with dynamic count badge
            BottomNavigationBarItem(
              icon: _buildNavBadgeIcon(icon: CupertinoIcons.mail, count: _inboxCount, size: 22),
              activeIcon: _buildNavBadgeIcon(icon: CupertinoIcons.mail_solid, count: _inboxCount, size: 22),
              label: 'Inbox',
            ),
            // Tab 3: Chat with dynamic count badge
            BottomNavigationBarItem(
              icon: _buildNavBadgeIcon(icon: CupertinoIcons.chat_bubble_2, count: _chatCount, size: 23),
              activeIcon: _buildNavBadgeIcon(icon: CupertinoIcons.chat_bubble_2_fill, count: _chatCount, size: 23),
              label: 'Chat',
            ),
            // Tab 4: Profile
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
