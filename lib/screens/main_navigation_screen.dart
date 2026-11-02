import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/rani_top_bar.dart';
import '../services/api_service.dart';
import 'home/home_screen.dart';
import 'matches/matches_screen.dart';
import 'matches/details_screen.dart';
import 'connections/connection_request.dart';
import 'wallet/wallet_screen.dart';
import 'profile/profile_screen.dart';
import 'search/search_screen.dart';
import 'auth/aadhaar_verification_screen.dart';
import 'splash_screen.dart';
import '../services/razorpay_service.dart';
import '../services/push_notification_service.dart';

/// Main Application Navigation Shell
/// Features:
/// 1. Automatic screen refresh on bottom nav tab switch
/// 2. Crisp, normal Home brand logo icon (not disabled/washed-out)
/// 3. Bottom nav updated: Home, Matches, Interests (replaces Inbox), Wallet (replaces Chat), Profile
/// 4. Full-screen sliding sidebar widget from topbar burger menu:
///    - Fixed top header: profile image, fixed ID, candidate name & cross (X) close button
///    - Middle scrollable navigation items
///    - Fixed bottom area: Available Wallet Balance & "Recharge Wallet" CTA button
class RaniMainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const RaniMainNavigationScreen({
    super.key,
    this.initialIndex = 1, // Default directly to Matches screen ('new' tab) per user specification
  });

  @override
  State<RaniMainNavigationScreen> createState() => _RaniMainNavigationScreenState();
}

class _RaniMainNavigationScreenState extends State<RaniMainNavigationScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _currentIndex;
  int _notificationCount = 3;
  int _matchesCount = 16;
  int _interestsCount = 5;
  double _walletBalance = 0.00;
  List<dynamic> _dynamicNotifications = [];
  final Set<String> _dismissedNotificationIds = {};

  // Refresh counters: incrementing forces full refresh & skeleton shimmer when switching tabs
  int _homeRefreshKey = 0;
  int _matchesRefreshKey = 0;
  int _interestsRefreshKey = 0;
  int _walletRefreshKey = 0;
  int _profileRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadDismissedNotifications();
    _fetchLiveMetrics();
    PushNotificationService.syncDeviceToken();
  }

  Future<void> _loadDismissedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('dismissed_notif_ids') ?? [];
      _dismissedNotificationIds.addAll(list);
    } catch (_) {}
  }

  Future<void> _saveDismissedNotification(String id) async {
    _dismissedNotificationIds.add(id);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('dismissed_notif_ids', _dismissedNotificationIds.toList());
    } catch (_) {}
  }

  Future<void> _saveAllDismissedNotifications(List<String> ids) async {
    _dismissedNotificationIds.addAll(ids);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('dismissed_notif_ids', _dismissedNotificationIds.toList());
    } catch (_) {}
  }

  Future<void> _fetchLiveMetrics() async {
    _fetchLiveWalletBalance();
    _fetchLiveDashboardAndNotifications();
  }

  static double _toDouble(dynamic val, [double fallback = 0.0]) {
    if (val == null) return fallback;
    if (val is num) return val.toDouble();
    if (val is String) {
      final clean = val.replaceAll(RegExp(r'[^0-9.-]'), '');
      return double.tryParse(clean) ?? fallback;
    }
    return fallback;
  }

  static int _toInt(dynamic val, [int fallback = 0]) {
    if (val == null) return fallback;
    if (val is num) return val.toInt();
    if (val is String) {
      final clean = val.replaceAll(RegExp(r'[^0-9.-]'), '');
      return int.tryParse(clean) ?? double.tryParse(clean)?.toInt() ?? fallback;
    }
    return fallback;
  }

  Future<void> _fetchLiveWalletBalance() async {
    try {
      final res = await ApiService.instance.getWallet();
      if (mounted && res['success'] == true && res['wallet'] != null) {
        setState(() {
          _walletBalance = _toDouble(res['wallet']['avl_balance'], _walletBalance);
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchLiveDashboardAndNotifications() async {
    try {
      // 1. Fetch live dashboard metrics and notifications
      final dashRes = await ApiService.instance.getDashboard();
      if (mounted && dashRes['success'] == true && dashRes['data'] != null) {
        final data = dashRes['data'] as Map<String, dynamic>;
        final rawNotifs = (data['notifications'] as List?) ?? [];

        // Filter out notifications dismissed locally or on server
        final validNotifs = rawNotifs.where((n) {
          final id = (n['id'] ?? n['db_id'] ?? n['notification_id'])?.toString();
          if (id != null && _dismissedNotificationIds.contains(id)) {
            return false;
          }
          if (n['is_dismissed'] == true) {
            return false;
          }
          return true;
        }).toList();

        final unreadCount = validNotifs.where((n) => n['is_new'] == true || n['is_read'] == false).length;

        final matchesLen = _toInt(
          data['metrics']?['new_matches_count'] ??
              data['metrics']?['total_matches_count'] ??
              data['newMatchesCount'] ??
              data['totalMatchesCount'] ??
              (data['matches'] as List?)?.length,
        );

        final pendingInvitations = _toInt(
          data['metrics']?['pending_invitations_count'] ?? data['pendingInvitationsCount'],
        );

        setState(() {
          _notificationCount = unreadCount;
          _dynamicNotifications = validNotifs;

          if (matchesLen > 0) {
            _matchesCount = matchesLen;
          }

          if (pendingInvitations > 0) {
            _interestsCount = pendingInvitations;
          }
        });
      }

      // 2. Fetch live matches total count for bottom nav badge
      try {
        final matchesRes = await ApiService.instance.getMatches(tab: 'new');
        if (mounted && matchesRes['success'] == true) {
          int count = 0;
          if (matchesRes['counts'] is Map) {
            final c = matchesRes['counts'] as Map;
            count = _toInt(c['todays'] ?? c['my_matches'] ?? c['new']);
          }
          if (count == 0 && matchesRes['matches'] is List) {
            count = (matchesRes['matches'] as List).length;
          }
          if (count > 0 && mounted) {
            setState(() {
              _matchesCount = count;
            });
          }
        }
      } catch (_) {}

      // 3. Fetch live inbox tab counts
      final inboxRes = await ApiService.instance.getInbox(tab: 'received');
      if (mounted && inboxRes['success'] == true && inboxRes['counts'] is Map) {
        final counts = inboxRes['counts'] as Map;
        final rec = _toInt(counts['received'] ?? counts['pending']);
        final sent = _toInt(counts['sent']);
        final total = _toInt(counts['total']);

        setState(() {
          if (rec > 0) {
            _interestsCount = rec;
          } else if (total > 0) {
            _interestsCount = total;
          } else if (sent > 0) {
            _interestsCount = sent;
          }
        });
      }
    } catch (_) {}
  }

  void _openNotificationsSheet() {
    RaniTopBar.showNotificationsSheet(
      context,
      _notificationCount,
      notifications: _dynamicNotifications,
      onNotificationTap: (notif) async {
        final notifId = notif['id'] ?? notif['db_id'] ?? notif['notification_id'];

        // 1. Instantly mark read and hide from list in UI & decrement count
        setState(() {
          _dynamicNotifications.removeWhere((n) =>
              (n['id'] ?? n['db_id'] ?? n['notification_id'])?.toString() == notifId?.toString());
          if (_notificationCount > 0) {
            _notificationCount--;
          }
        });

        // 2. Persist dismissal locally so it never reappears on reload
        if (notifId != null) {
          _saveDismissedNotification(notifId.toString());
        }

        // 3. Call backend to mark read & dismissed in database
        if (notifId != null) {
          try {
            await ApiService.instance.markNotificationRead(notifId);
          } catch (_) {}
        }

        // 4. Navigate to target screen
        final link = notif['link']?.toString() ?? notif['action_url']?.toString() ?? '';
        final profileId = notif['profile_id'] ?? notif['candidate_id'] ?? notif['candidate_code'];

        if (profileId != null && profileId.toString().isNotEmpty) {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RaniMatchDetailsScreen(profileId: profileId.toString()),
              ),
            );
          }
        } else if (link.contains('inbox') || link.contains('connection') || link.contains('request')) {
          _navigateToTab(2); // Interests/Connections
        } else if (link.contains('profile')) {
          _navigateToTab(4); // Profile
        } else if (link.contains('wallet')) {
          _navigateToTab(3); // Wallet
        } else {
          _navigateToTab(1); // Matches
        }
      },
      onNotificationDismiss: (notif) async {
        final notifId = notif['id'] ?? notif['db_id'] ?? notif['notification_id'];
        setState(() {
          _dynamicNotifications.removeWhere((n) =>
              (n['id'] ?? n['db_id'] ?? n['notification_id'])?.toString() == notifId?.toString());
          if (_notificationCount > 0) {
            _notificationCount--;
          }
        });
        if (notifId != null) {
          _saveDismissedNotification(notifId.toString());
          try {
            await ApiService.instance.markNotificationRead(notifId);
          } catch (_) {}
        }
      },
      onDismissAll: () async {
        final notifIds = _dynamicNotifications
            .map((n) => (n['id'] ?? n['db_id'] ?? n['notification_id'])?.toString())
            .whereType<String>()
            .toList();
        setState(() {
          _dynamicNotifications.clear();
          _notificationCount = 0;
        });
        _saveAllDismissedNotifications(notifIds);
        try {
          await ApiService.instance.clearAllNotifications();
        } catch (_) {}
      },
    );
  }

  /// Switch tab and trigger a clean refresh of the target screen
  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
      if (index == 0) _homeRefreshKey++;
      if (index == 1) _matchesRefreshKey++;
      if (index == 2) _interestsRefreshKey++;
      if (index == 3) {
        _walletRefreshKey++;
        _fetchLiveWalletBalance();
      }
      if (index == 4) _profileRefreshKey++;
    });
    _fetchLiveMetrics();
  }

  /// Reusable TopBar changeable by active screen
  PreferredSizeWidget _buildTopBarForCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        // Home Screen TopBar: Candidate short name (e.g. Rahul M.) + Circular Filter Button + Notification Button
        final candidate = ApiService.instance.candidate;
        final firstName = candidate?['first_name']?.toString() ?? 'Rahul';
        final lastName = candidate?['last_name']?.toString() ?? 'M.';
        final shortName = lastName.trim().isNotEmpty
            ? '$firstName ${lastName.trim()[0]}.'
            : firstName;

        return RaniTopBar(
          title: shortName,
          notificationCount: _notificationCount,
          onMenuPressed: () {
            _fetchLiveWalletBalance();
            _scaffoldKey.currentState?.openDrawer();
          },
          onNotificationPressed: _openNotificationsSheet,
          actions: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RaniSearchScreen()),
                );
              },
              child: Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE8DFD5)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF750000).withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.slider_horizontal_3,
                  size: 18,
                  color: Color(0xFF750000), // Royal Burgundy
                ),
              ),
            ),
          ],
        );

      case 1:
        // Matches Screen TopBar
        return RaniTopBar(
          title: 'Matches',
          notificationCount: _notificationCount,
          onMenuPressed: () {
            _fetchLiveWalletBalance();
            _scaffoldKey.currentState?.openDrawer();
          },
          onNotificationPressed: _openNotificationsSheet,
        );

      case 2:
        // Interests Screen TopBar
        return RaniTopBar(
          title: 'Connections',
          notificationCount: _notificationCount,
          onMenuPressed: () {
            _fetchLiveWalletBalance();
            _scaffoldKey.currentState?.openDrawer();
          },
          onNotificationPressed: _openNotificationsSheet,
        );

      case 3:
        // Wallet Screen TopBar
        return RaniTopBar(
          title: 'My Wallet',
          notificationCount: _notificationCount,
          onMenuPressed: () {
            _fetchLiveWalletBalance();
            _scaffoldKey.currentState?.openDrawer();
          },
          onNotificationPressed: _openNotificationsSheet,
        );

      case 4:
        // Profile Screen TopBar
        return RaniTopBar(
          title: 'Profile',
          notificationCount: _notificationCount,
          onMenuPressed: () {
            _fetchLiveWalletBalance();
            _scaffoldKey.currentState?.openDrawer();
          },
          onNotificationPressed: _openNotificationsSheet,
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

  /// Normal Home Brand Logo Icon (never disabled / washed out)
  Widget _buildHomeLogoNavIcon({required bool isActive}) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      child: Image.asset(
        'assets/logo.png',
        width: 25,
        height: 25,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Icon(
          CupertinoIcons.circle_grid_hex_fill,
          size: 24,
          color: Color(0xFF750000),
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

  /// Full-Screen Sidebar Drawer:
  /// - Top: Profile image, Candidate ID (fixed), Candidate Name & Close (X) button
  /// - Middle: Scrollable multiple nav items
  /// - Bottom Fixed: Available Wallet Balance & "Recharge Wallet" CTA button
  Widget _buildFullScreenSidebar() {
    final candidate = ApiService.instance.candidate;
    final firstName = candidate?['first_name'] ?? 'Candidate';
    final lastName = candidate?['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final candidateCode = candidate?['candidate_code'] ?? candidate?['profile_id'] ?? 'RM00024';
    final photo = candidate?['profile_picture'] ?? '';
    final screenWidth = MediaQuery.of(context).size.width;

    return Drawer(
      width: screenWidth, // Grabs the whole screen
      backgroundColor: const Color(0xFFFAF7F2),
      child: SafeArea(
        child: Column(
          children: [
            // 1. Fixed Top Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFEFE8DE), width: 1.0),
                ),
              ),
              child: Row(
                children: [
                  // Profile Image
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF750000),
                    backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                    child: photo.isEmpty
                        ? Text(
                            fullName.isNotEmpty ? fullName[0].toUpperCase() : 'R',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),

                  // Candidate Name and Fixed ID
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          fullName.isNotEmpty ? fullName : 'Rani Member',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E1E1E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF750000).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'ID: $candidateCode',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF750000),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Cross Button to Close Sidebar
                  IconButton(
                    icon: const Icon(CupertinoIcons.xmark, size: 22, color: Color(0xFF1E1E1E)),
                    tooltip: 'Close Sidebar',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // 2. Middle Scrollable Nav Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildSidebarItem(
                    icon: CupertinoIcons.sparkles,
                    title: 'Discover Matches',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToTab(1);
                    },
                  ),
                  _buildSidebarItem(
                    icon: CupertinoIcons.heart,
                    title: 'Interests & Requests',
                    count: _interestsCount,
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToTab(2);
                    },
                  ),
                  _buildSidebarItem(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Royal Wallet',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToTab(3);
                    },
                  ),
                  _buildSidebarItem(
                    icon: CupertinoIcons.person,
                    title: 'My Profile',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToTab(4);
                    },
                  ),
                  const Divider(color: Color(0xFFEFE8DE), indent: 16, endIndent: 16),
                  _buildSidebarItem(
                    icon: CupertinoIcons.search,
                    title: 'Advanced Search',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RaniSearchScreen()),
                      );
                    },
                  ),
                  _buildSidebarItem(
                    icon: CupertinoIcons.bookmark,
                    title: 'Shortlisted Profiles',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToTab(1);
                    },
                  ),
                  _buildSidebarItem(
                    icon: CupertinoIcons.slider_horizontal_3,
                    title: 'Partner Preferences',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RaniSearchScreen()),
                      );
                    },
                  ),
                  _buildSidebarItem(
                    icon: CupertinoIcons.checkmark_seal_fill,
                    title: 'Aadhaar & Verification',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RaniAadhaarVerificationScreen()),
                      );
                    },
                  ),
                  _buildSidebarItem(
                    icon: CupertinoIcons.question_circle,
                    title: 'Help & Support',
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildSidebarItem(
                    icon: CupertinoIcons.gear_alt,
                    title: 'Account Settings',
                    onTap: () => Navigator.pop(context),
                  ),
                  const Divider(color: Color(0xFFEFE8DE), indent: 16, endIndent: 16),
                  _buildSidebarItem(
                    icon: Icons.logout_rounded,
                    title: 'Log Out',
                    isDestructive: true,
                    onTap: () {
                      Navigator.pop(context);
                      _showLogoutConfirmDialog();
                    },
                  ),
                ],
              ),
            ),

            // 3. Fixed Bottom Area: Available Wallet Balance & Recharge CTA Button
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.account_balance_wallet_rounded,
                              size: 18,
                              color: Color(0xFF750000),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Available Balance',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF6B6B6B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₹${_walletBalance.toStringAsFixed(2)}',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF750000),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF750000),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        RaniRazorpayService.showRechargeModal(
                          context: context,
                          onPaymentSuccess: (amt) {
                            _fetchLiveWalletBalance();
                          },
                        );
                      },
                      icon: const Icon(Icons.add_card_rounded, size: 18, color: Color(0xFFE5B842)),
                      label: Text(
                        'Recharge Wallet',
                        style: GoogleFonts.outfit(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    int? count,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? const Color(0xFFD32F2F) : const Color(0xFF4A4A4A),
        size: 21,
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: isDestructive ? const Color(0xFFD32F2F) : const Color(0xFF222222),
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
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            )
          : const Icon(CupertinoIcons.chevron_forward, size: 14, color: Color(0xFFB0B0B0)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: _buildTopBarForCurrentScreen(),
      drawer: _buildFullScreenSidebar(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // 0. Home Screen
          RaniHomeScreen(
            key: ValueKey('home_$_homeRefreshKey'),
            showAppBar: false,
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
            onOpenMatches: () => _navigateToTab(1),
            onOpenWallet: () => _navigateToTab(3),
          ),

          // 1. Matches Screen
          RaniMatchesScreen(
            key: ValueKey('matches_$_matchesRefreshKey'),
            showAppBar: false,
            onOpenSearch: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RaniSearchScreen()),
              );
            },
            onOpenNotifications: _openNotificationsSheet,
            onMatchesCountChanged: (count) {
              if (mounted && count > 0 && _matchesCount != count) {
                setState(() => _matchesCount = count);
              }
            },
          ),

          // 2. Interests / Connections Screen (Top 4 tabs: Received, Send, Accepted, Declined)
          RaniConnectionsScreen(
            key: ValueKey('interests_$_interestsRefreshKey'),
            showAppBar: false,
          ),

          // 3. Wallet Screen (Replaces Chat per user request)
          RaniWalletScreen(
            key: ValueKey('wallet_$_walletRefreshKey'),
            showAppBar: false,
          ),

          // 4. Profile Screen
          RaniProfileScreen(
            key: ValueKey('profile_$_profileRefreshKey'),
            showAppBar: false,
          ),
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
            // Tab 0: Home with Normal Brand Logo Icon (Not disabled)
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
            // Tab 2: Interests (Replaced Inbox)
            BottomNavigationBarItem(
              icon: _buildNavBadgeIcon(icon: CupertinoIcons.heart, count: _interestsCount, size: 23),
              activeIcon: _buildNavBadgeIcon(icon: CupertinoIcons.heart_fill, count: _interestsCount, size: 23),
              label: 'Interests',
            ),
            // Tab 3: Wallet (Replaced Chat)
            const BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined, size: 23),
              activeIcon: Icon(Icons.account_balance_wallet, size: 23),
              label: 'Wallet',
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
