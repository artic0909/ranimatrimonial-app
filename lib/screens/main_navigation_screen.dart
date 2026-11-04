import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/rani_top_bar.dart';
import '../components/rani_sidebar_drawer.dart';
import '../services/api_service.dart';
import 'home/home_screen.dart';
import 'matches/matches_screen.dart';
import 'matches/details_screen.dart';
import 'connections/connection_request.dart';
import 'wallet/wallet_screen.dart';
import 'profile/profile_screen.dart';
import 'search/search_screen.dart';
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
  final int? initialConnectionTabIndex;
  final String? initialMatchesTab;

  const RaniMainNavigationScreen({
    super.key,
    this.initialIndex = 1, // Default directly to Matches screen ('new' tab) per user specification
    this.initialConnectionTabIndex,
    this.initialMatchesTab,
  });

  @override
  State<RaniMainNavigationScreen> createState() => _RaniMainNavigationScreenState();
}

class _RaniMainNavigationScreenState extends State<RaniMainNavigationScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _currentIndex;
  int? _connectionsTabIndex;
  String? _matchesTab;
  int _notificationCount = 0;
  int _matchesCount = 0;
  int _interestsCount = 0;
  int _acceptedCount = 0;
  int _sentCount = 0;
  double _walletBalance = 0.00;
  List<dynamic> _dynamicNotifications = [];
  final Set<String> _dismissedNotificationIds = {};

  // Refresh counters: incrementing forces full refresh & skeleton shimmer when switching tabs
  int _homeRefreshKey = 0;
  int _matchesRefreshKey = 0;
  int _interestsRefreshKey = 0;
  int _walletRefreshKey = 0;
  int _profileRefreshKey = 0;

  // Tab navigation history stack for back navigation:
  // e.g. User starts at Matches (1) -> Interests (2) -> Profile (4)
  // Back presses: Profile (4) -> Interests (2) -> Matches (1) -> Home (0) -> Close app
  final List<int> _tabHistory = [0];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _connectionsTabIndex = widget.initialConnectionTabIndex;
    _matchesTab = widget.initialMatchesTab;
    if (widget.initialIndex != 0) {
      _tabHistory.add(widget.initialIndex);
    }
    ApiService.instance.candidateNotifier.addListener(_onMainCandidateChanged);
    ApiService.instance.walletBalanceNotifier.addListener(_onMainWalletChanged);
    _loadDismissedNotifications();
    _fetchLiveMetrics();
    PushNotificationService.syncDeviceToken();
  }

  void _onMainCandidateChanged() {
    if (mounted) setState(() {});
  }

  void _onMainWalletChanged() {
    if (mounted) {
      setState(() {
        _walletBalance = ApiService.instance.walletBalanceNotifier.value;
      });
    }
  }

  @override
  void dispose() {
    ApiService.instance.candidateNotifier.removeListener(_onMainCandidateChanged);
    ApiService.instance.walletBalanceNotifier.removeListener(_onMainWalletChanged);
    super.dispose();
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
          data['metrics']?['total_matches_count'] ??
              data['metrics']?['new_matches_count'] ??
              data['totalMatchesCount'] ??
              data['newMatchesCount'],
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
            // Prefer total new / my_matches count over subset today's picks
            count = _toInt(c['new'] ?? c['my_matches'] ?? c['all'] ?? c['todays']);
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
        final acc = _toInt(counts['accepted']);
        final total = _toInt(counts['total']);

        setState(() {
          if (rec > 0) {
            _interestsCount = rec;
          } else if (total > 0) {
            _interestsCount = total;
          } else if (sent > 0) {
            _interestsCount = sent;
          }
          if (acc > 0) _acceptedCount = acc;
          if (sent > 0) _sentCount = sent;
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
  void _navigateToTab(
    int index, {
    int? connectionTabIndex,
    String? matchesTab,
    bool addToHistory = true,
  }) {
    final bool subTabChanged = (connectionTabIndex != null && connectionTabIndex != _connectionsTabIndex) ||
        (matchesTab != null && matchesTab != _matchesTab);

    if (index == _currentIndex && !subTabChanged) return;

    if (connectionTabIndex != null) {
      _connectionsTabIndex = connectionTabIndex;
    }
    if (matchesTab != null) {
      _matchesTab = matchesTab;
    }

    if (addToHistory) {
      if (_tabHistory.isEmpty || _tabHistory.last != index) {
        _tabHistory.add(index);
      }
    }

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

  /// Handle system / Android back button:
  /// 1. Close drawer if open
  /// 2. Step back to previous tab in history
  /// 3. If history exhausted, go to Home tab (0)
  /// 4. Only if currently on Home tab (0) with empty history, exit the app
  void _handleBackNavigation() {
    // 1. If drawer is open, close drawer first
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      _scaffoldKey.currentState?.closeDrawer();
      return;
    }

    // 2. If tab history has previous tabs, step back to the previous tab
    if (_tabHistory.length > 1) {
      _tabHistory.removeLast(); // remove current tab
      final prevTab = _tabHistory.last;
      _navigateToTab(prevTab, addToHistory: false);
      return;
    }

    // 3. If not on Home tab (0), go to Home tab
    if (_currentIndex != 0) {
      _tabHistory.clear();
      _tabHistory.add(0);
      _navigateToTab(0, addToHistory: false);
      return;
    }

    // 4. Currently on Home tab with exhausted history -> close app cleanly
    SystemNavigator.pop();
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

  /// Compute currently active sidebar navigation item based on screen and sub-tab
  String _computeActiveSidebarItem() {
    switch (_currentIndex) {
      case 0:
        return 'home';
      case 1:
        return (_matchesTab == 'shortlisted') ? 'shortlisted' : 'matches';
      case 2:
        final connTab = _connectionsTabIndex ?? 0;
        if (connTab == 2) return 'accepted_connections';
        if (connTab == 1) return 'sent_requests';
        return 'received_connections';
      case 3:
        return 'wallet';
      case 4:
        return 'account_settings';
      default:
        return 'matches';
    }
  }

  /// Full-Screen Royal Matrimonial Sidebar Drawer
  Widget _buildFullScreenSidebar() {
    return RaniSidebarDrawer(
      activeItem: _computeActiveSidebarItem(),
      onNavigateToTab: (index, {connectionTabIndex, matchesTab}) {
        _navigateToTab(index, connectionTabIndex: connectionTabIndex, matchesTab: matchesTab);
      },
      interestsCount: _interestsCount,
      acceptedCount: _acceptedCount,
      sentCount: _sentCount,
      matchesCount: _matchesCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: Scaffold(
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
            key: ValueKey('matches_${_matchesRefreshKey}_${_matchesTab ?? "new"}'),
            showAppBar: false,
            initialTab: _matchesTab ?? 'new',
            onTabChanged: (tab) {
              if (mounted && _matchesTab != tab) {
                setState(() => _matchesTab = tab);
              }
            },
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
            key: ValueKey('interests_${_interestsRefreshKey}_${_connectionsTabIndex ?? 0}'),
            showAppBar: false,
            initialTabIndex: _connectionsTabIndex ?? 0,
            onTabChanged: (tabIdx) {
              if (mounted && _connectionsTabIndex != tabIdx) {
                setState(() => _connectionsTabIndex = tabIdx);
              }
            },
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
    ),
  );
}
}
