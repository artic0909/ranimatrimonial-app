import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../components/rani_alert.dart';
import '../../components/rani_matrimonial_loader.dart';
import '../../components/rani_skeleton_loader.dart';
import '../../components/rani_top_bar.dart';
import '../matches/details_screen.dart';
import '../search/search_screen.dart';
import 'accepted_screen.dart';
import 'declined_screen.dart';

/// Screen: Main Connections / Interests Hub
/// Features 4 Top Tabs Styled with Matches Theme:
/// 1. Received (keu amai pathale)
/// 2. Send (kauke ami pathale)
/// 3. Accepted (ami karor accept korle, ba keu amar accept korle)
/// 4. Declined (ami kauke decline korle, as website)
class RaniConnectionsScreen extends StatefulWidget {
  final int initialTabIndex;
  final bool showAppBar;
  final VoidCallback? onOpenMenu;
  final VoidCallback? onOpenNotifications;

  const RaniConnectionsScreen({
    super.key,
    this.initialTabIndex = 0,
    this.showAppBar = false,
    this.onOpenMenu,
    this.onOpenNotifications,
  });

  @override
  State<RaniConnectionsScreen> createState() => _RaniConnectionsScreenState();
}

class _RaniConnectionsScreenState extends State<RaniConnectionsScreen> {
  late int _selectedTabIndex;
  int _receivedCount = 0;
  int _sentCount = 0;
  int _acceptedCount = 0;
  int _declinedCount = 0;

  final GlobalKey<RaniConnectionRequestListState> _receivedListKey = GlobalKey<RaniConnectionRequestListState>();
  final GlobalKey<RaniConnectionRequestListState> _sentListKey = GlobalKey<RaniConnectionRequestListState>();
  final GlobalKey<_AcceptedConnectionsWrapperState> _acceptedListKey = GlobalKey<_AcceptedConnectionsWrapperState>();
  final GlobalKey<_DeclinedConnectionsWrapperState> _declinedListKey = GlobalKey<_DeclinedConnectionsWrapperState>();

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
    _fetchLiveTabCounts();
  }

  Future<void> _fetchLiveTabCounts() async {
    try {
      final res = await ApiService.instance.getInbox(tab: 'received');
      if (mounted && res['success'] == true && res['counts'] is Map) {
        final c = res['counts'] as Map;
        setState(() {
          _receivedCount = (c['received'] ?? c['pending'] ?? _receivedCount) as int;
          _sentCount = (c['sent'] ?? _sentCount) as int;
          _acceptedCount = (c['accepted'] ?? _acceptedCount) as int;
          _declinedCount = (c['declined'] ?? c['rejected'] ?? _declinedCount) as int;
        });
      }
    } catch (_) {}
  }

  void _onAcceptSuccess() {
    setState(() {
      if (_receivedCount > 0) _receivedCount--;
      _acceptedCount++;
    });
    _fetchLiveTabCounts();
  }

  void _onDeclineSuccess() {
    setState(() {
      if (_receivedCount > 0) _receivedCount--;
      _declinedCount++;
    });
    _fetchLiveTabCounts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: widget.showAppBar
          ? RaniTopBar(
              title: 'Connections',
              notificationCount: 3,
              onMenuPressed: widget.onOpenMenu,
              onNotificationPressed: widget.onOpenNotifications,
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            // Top 4 Tabs Row (Matches Theme: Filter/Search icon | Received | Send | Accepted | Rejected)
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Search / Filter icon
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RaniSearchScreen()),
                      );
                    },
                    child: Container(
                      width: 38,
                      height: 38,
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
                        CupertinoIcons.search,
                        size: 17,
                        color: Color(0xFF750000), // Royal Burgundy
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Vertical divider |
                  Center(
                    child: Container(
                      width: 1.5,
                      height: 22,
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // 1. Received Tab
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        if (_selectedTabIndex != 0) {
                          setState(() => _selectedTabIndex = 0);
                          _receivedListKey.currentState?.refreshList();
                          _fetchLiveTabCounts();
                        }
                      },
                      child: _buildTabPill('Received $_receivedCount', _selectedTabIndex == 0),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 2. Send Tab
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        if (_selectedTabIndex != 1) {
                          setState(() => _selectedTabIndex = 1);
                          _sentListKey.currentState?.refreshList();
                          _fetchLiveTabCounts();
                        }
                      },
                      child: _buildTabPill('Send $_sentCount', _selectedTabIndex == 1),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 3. Accepted Tab
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        if (_selectedTabIndex != 2) {
                          setState(() => _selectedTabIndex = 2);
                          _acceptedListKey.currentState?.refreshList();
                          _fetchLiveTabCounts();
                        }
                      },
                      child: _buildTabPill('Accepted $_acceptedCount', _selectedTabIndex == 2),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 4. Declined Tab
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        if (_selectedTabIndex != 3) {
                          setState(() => _selectedTabIndex = 3);
                          _declinedListKey.currentState?.refreshList();
                          _fetchLiveTabCounts();
                        }
                      },
                      child: _buildTabPill('Declined $_declinedCount', _selectedTabIndex == 3),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Tab View Body
            Expanded(
              child: IndexedStack(
                index: _selectedTabIndex,
                children: [
                  // 0. Received
                  RaniConnectionRequestList(
                    key: _receivedListKey,
                    type: 'received',
                    onAcceptSuccess: _onAcceptSuccess,
                    onDeclineSuccess: _onDeclineSuccess,
                  ),

                  // 1. Sent
                  RaniConnectionRequestList(
                    key: _sentListKey,
                    type: 'sent',
                  ),

                  // 2. Accepted
                  _AcceptedConnectionsWrapper(
                    key: _acceptedListKey,
                    onCountChanged: _fetchLiveTabCounts,
                  ),

                  // 3. Declined
                  _DeclinedConnectionsWrapper(
                    key: _declinedListKey,
                    onCountChanged: _fetchLiveTabCounts,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabPill(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
                colors: [Color(0xFF8B0000), Color(0xFF6B0000)], // Royal Burgundy
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isSelected ? null : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? const Color(0xFF8B0000) : const Color(0xFFE8DFD5),
          width: 1.2,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: const Color(0xFF750000).withValues(alpha: 0.32),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 12.5,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          color: isSelected ? Colors.white : const Color(0xFF5A0812),
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Helper wrapper for Accepted Screen inside tab stack
class _AcceptedConnectionsWrapper extends StatefulWidget {
  final VoidCallback? onCountChanged;

  const _AcceptedConnectionsWrapper({super.key, this.onCountChanged});

  @override
  State<_AcceptedConnectionsWrapper> createState() => _AcceptedConnectionsWrapperState();
}

class _AcceptedConnectionsWrapperState extends State<_AcceptedConnectionsWrapper> {
  final GlobalKey<State<RaniAcceptedConnectionsScreen>> _screenKey = GlobalKey();

  void refreshList() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return RaniAcceptedConnectionsScreen(
      key: _screenKey,
      showAppBar: false,
      onCountChanged: widget.onCountChanged,
    );
  }
}

/// Helper wrapper for Declined Screen inside tab stack
class _DeclinedConnectionsWrapper extends StatefulWidget {
  final VoidCallback? onCountChanged;

  const _DeclinedConnectionsWrapper({super.key, this.onCountChanged});

  @override
  State<_DeclinedConnectionsWrapper> createState() => _DeclinedConnectionsWrapperState();
}

class _DeclinedConnectionsWrapperState extends State<_DeclinedConnectionsWrapper> {
  final GlobalKey<State<RaniDeclinedConnectionsScreen>> _screenKey = GlobalKey();

  void refreshList() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return RaniDeclinedConnectionsScreen(
      key: _screenKey,
      showAppBar: false,
      onCountChanged: widget.onCountChanged,
    );
  }
}

/// Reusable list view component for Received & Sent Connection Requests
class RaniConnectionRequestList extends StatefulWidget {
  final String type; // 'received' or 'sent'
  final VoidCallback? onAcceptSuccess;
  final VoidCallback? onDeclineSuccess;

  const RaniConnectionRequestList({
    super.key,
    required this.type,
    this.onAcceptSuccess,
    this.onDeclineSuccess,
  });

  @override
  State<RaniConnectionRequestList> createState() => RaniConnectionRequestListState();
}

class RaniConnectionRequestListState extends State<RaniConnectionRequestList> {
  bool _isLoading = true;
  List<dynamic> _requests = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    refreshList();
  }

  Future<void> refreshList() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tabParam = widget.type == 'sent' ? 'sent' : 'received';
      final res = await ApiService.instance.getInbox(tab: tabParam);
      if (!mounted) return;

      if (res['success'] == true) {
        setState(() {
          _requests = res['requests'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = res['message'] ?? 'Unable to load connection requests.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Network error: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _respondInterest(dynamic c, String action) async {
    final profileId = (c['candidate_code'] ?? c['id']?.toString() ?? c['profile_id'] ?? '').toString();
    final name = '${c['first_name'] ?? 'Candidate'}'.trim();

    RaniMatrimonialLoader.show(
      context,
      message: action == 'accept' ? 'Accepting connection request...' : 'Declining request...',
    );

    try {
      final res = await ApiService.instance.respondInterest(profileId, action);
      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);

      if (res['success'] == true) {
        setState(() {
          _requests.removeWhere((item) {
            final itemId = (item['candidate_code'] ?? item['id']?.toString() ?? item['profile_id'] ?? '').toString();
            return itemId == profileId || item == c;
          });
        });

        if (action == 'accept') {
          RaniAlert.success(
            context,
            'You accepted the connection request with $name! Full profile unlocked.',
            title: 'Connection Accepted! 🎉',
          );
          if (widget.onAcceptSuccess != null) widget.onAcceptSuccess!();
        } else {
          RaniAlert.info(
            context,
            'Connection request with $name declined.',
            title: 'Request Declined',
          );
          if (widget.onDeclineSuccess != null) widget.onDeclineSuccess!();
        }
      } else {
        RaniAlert.error(context, res['message'] ?? 'Unable to process connection response.');
      }
    } catch (e) {
      if (mounted) {
        RaniMatrimonialLoader.hide(context);
        RaniAlert.error(context, 'Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const RaniSkeletonCandidateList(isAcceptedTab: false);
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.exclamationmark_triangle, size: 44, color: Color(0xFFD32F2F)),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 13.5),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF750000),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: refreshList,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final isSent = widget.type == 'sent';

    if (_requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF750000).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSent ? CupertinoIcons.paperplane_fill : CupertinoIcons.tray_fill,
                  size: 36,
                  color: const Color(0xFF750000),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                isSent ? 'No Sent Requests' : 'No Received Requests',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2B0A0D),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSent
                    ? 'You have not sent any pending connection requests yet. Explore matches to send connections.'
                    : 'No pending requests received from candidates right now. When someone wants to connect, they will appear here.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF6B6B6B), height: 1.4),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF750000),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RaniSearchScreen()),
                  );
                },
                icon: const Icon(CupertinoIcons.search, size: 16),
                label: const Text('Discover Candidates'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF750000),
      backgroundColor: Colors.white,
      onRefresh: refreshList,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _requests.length,
        itemBuilder: (context, index) {
          final c = _requests[index];
          return _buildRequestCard(c, isSent: isSent);
        },
      ),
    );
  }

  Widget _buildRequestCard(dynamic c, {required bool isSent}) {
    final profileId = c['candidate_code'] ?? c['id']?.toString() ?? c['profile_id'] ?? 'RM00024';
    final firstName = c['first_name'] ?? 'Candidate';
    final lastName = c['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final age = c['age']?.toString() ?? '25';
    final height = c['height']?.toString() ?? "5' 5\"";
    final religion = c['religion']?.toString() ?? 'Muslim';
    final community = c['community']?.toString() ?? '';
    final religionWithCommunity = (community.isNotEmpty && community.toLowerCase() != 'all')
        ? '$religion, $community'
        : religion;
    final profession = c['profession']?.toString() ?? c['highest_qualification']?.toString() ?? 'Professional';
    final city = c['city']?.toString() ?? '';
    final state = c['state']?.toString() ?? '';
    final locationText = (city.isNotEmpty && state.isNotEmpty) ? '$city, $state' : (city.isNotEmpty ? city : state);
    final photo = c['photo'] ?? c['profile_picture'] ?? '';
    final isVerified = c['verified'] == true || (c['bluetick'] != null && c['bluetick']['is_accept'] == 1);
    final matchScore = c['match_score']?.toString() ?? '95';
    final receivedAgo = c['received_ago']?.toString() ?? 'Recently';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEFE8DE), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RaniMatchDetailsScreen(
                  profileId: profileId,
                  initialProfileData: c,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo with match badge
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            width: 92,
                            height: 110,
                            child: photo.toString().isNotEmpty
                                ? Image.network(
                                    photo.toString(),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: const Color(0xFFEFE7DC),
                                      child: const Icon(CupertinoIcons.person_fill, size: 42, color: Color(0xFFB5A795)),
                                    ),
                                  )
                                : Container(
                                    color: const Color(0xFFEFE7DC),
                                    child: const Icon(CupertinoIcons.person_fill, size: 42, color: Color(0xFFB5A795)),
                                  ),
                          ),
                        ),
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5B842),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(CupertinoIcons.star_fill, size: 8.5, color: Color(0xFF4A0000)),
                                const SizedBox(width: 2),
                                Text(
                                  '$matchScore%',
                                  style: GoogleFonts.outfit(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF4A0000),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 12),

                    // Info Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  fullName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1E1E1E),
                                  ),
                                ),
                              ),
                              if (isVerified) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  CupertinoIcons.checkmark_seal_fill,
                                  size: 15,
                                  color: Color(0xFF2196F3),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID: $profileId',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF8E8E93),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$age yrs, $height • $religionWithCommunity',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4A4A4A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(CupertinoIcons.briefcase, size: 12, color: Color(0xFF750000)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  profession,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF555555)),
                                ),
                              ),
                            ],
                          ),
                          if (locationText.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(CupertinoIcons.location, size: 12, color: Color(0xFF750000)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    locationText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF555555)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            isSent ? 'Sent $receivedAgo' : 'Received $receivedAgo',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Action Bar
                if (!isSent) ...[
                  // Received mode: Accept and Decline buttons (Styled as in website)
                  Row(
                    children: [
                      // Accept CTA (Green Gradient)
                      Expanded(
                        child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2E7D32).withValues(alpha: 0.28),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _respondInterest(c, 'accept'),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(CupertinoIcons.checkmark_alt, size: 17, color: Colors.white),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Accept',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Decline CTA (Rose Button)
                      SizedBox(
                        width: 46,
                        height: 42,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFF0F2),
                            side: const BorderSide(color: Color(0xFFFFCDD2)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () => _respondInterest(c, 'decline'),
                          child: const Icon(CupertinoIcons.xmark, size: 18, color: Color(0xFFD32F2F)),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Sent mode: Pending confirmation status + View Profile
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E7),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFFE082)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(CupertinoIcons.clock_fill, size: 14, color: Color(0xFFB78103)),
                              const SizedBox(width: 6),
                              Text(
                                'Pending Response',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF8D6200),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF750000),
                          side: const BorderSide(color: Color(0xFF750000)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RaniMatchDetailsScreen(
                                profileId: profileId,
                                initialProfileData: c,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(CupertinoIcons.person_crop_circle, size: 14),
                        label: Text(
                          'View Profile',
                          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
