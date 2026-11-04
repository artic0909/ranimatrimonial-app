import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../components/rani_alert.dart';
import '../../components/rani_matrimonial_loader.dart';
import '../../components/rani_skeleton_loader.dart';
import '../../components/rani_top_bar.dart';
import '../../components/rani_sidebar_drawer.dart';
import '../matches/details_screen.dart';
import '../search/search_screen.dart';

/// Screen: Main Connections / Interests Hub
/// Features 4 Top Tabs Styled with Matches / Website Theme:
/// 1. Received (keu amai pathale)
/// 2. Send (kauke ami pathale)
/// 3. Accepted (ami karor accept korle, ba keu amar accept korle)
/// 4. Declined (ami kauke decline korle, as website)
/// Card Design: 100% matched to website Inbox & Requests view
class RaniConnectionsScreen extends StatefulWidget {
  final int initialTabIndex;
  final bool showAppBar;
  final VoidCallback? onOpenMenu;
  final VoidCallback? onOpenNotifications;
  final List<dynamic>? initialRequests;

  const RaniConnectionsScreen({
    super.key,
    this.initialTabIndex = 0,
    this.showAppBar = false,
    this.onOpenMenu,
    this.onOpenNotifications,
    this.initialRequests,
  });

  @override
  State<RaniConnectionsScreen> createState() => _RaniConnectionsScreenState();
}

class _RaniConnectionsScreenState extends State<RaniConnectionsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _selectedTabIndex; // 0: received, 1: sent, 2: accepted, 3: declined
  bool _isLoading = true;
  List<dynamic> _requests = [];
  String? _errorMessage;

  int _receivedCount = 0;
  int _sentCount = 0;
  int _acceptedCount = 0;
  int _declinedCount = 0;

  static int _toInt(dynamic val, [int fallback = 0]) {
    if (val == null) return fallback;
    if (val is num) return val.toInt();
    if (val is String) {
      final clean = val.replaceAll(RegExp(r'[^0-9.-]'), '');
      return int.tryParse(clean) ?? double.tryParse(clean)?.toInt() ?? fallback;
    }
    return fallback;
  }

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
    if (widget.initialRequests != null) {
      _requests = List<dynamic>.from(widget.initialRequests!);
      _isLoading = false;
      if (_selectedTabIndex == 1) _sentCount = _requests.length;
    } else {
      _fetchRequestsForCurrentTab();
    }
  }

  @override
  void didUpdateWidget(covariant RaniConnectionsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTabIndex != widget.initialTabIndex) {
      setState(() {
        _selectedTabIndex = widget.initialTabIndex;
      });
      _fetchRequestsForCurrentTab();
    }
  }

  void _onTabChanged(int index) {
    if (_selectedTabIndex != index) {
      setState(() {
        _selectedTabIndex = index;
      });
      _fetchRequestsForCurrentTab();
    }
  }

  Future<void> _fetchRequestsForCurrentTab() async {
    final tabs = ['received', 'sent', 'accepted', 'declined'];
    final currentTab = tabs[_selectedTabIndex];

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiService.instance.getInbox(tab: currentTab);
      if (!mounted) return;

      if (res['counts'] is Map) {
        final c = res['counts'] as Map;
        setState(() {
          _receivedCount = _toInt(c['received'] ?? c['pending'], _receivedCount);
          _sentCount = _toInt(c['sent'], _sentCount);
          _acceptedCount = _toInt(c['accepted'], _acceptedCount);
          _declinedCount = _toInt(c['declined'] ?? c['rejected'], _declinedCount);
        });
      }

      if (res['success'] == true) {
        final rawRequests = res['requests'];
        final List<dynamic> list = (rawRequests is List) ? List<dynamic>.from(rawRequests) : [];
        setState(() {
          _requests = list;
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
          if (action == 'accept') {
            if (_receivedCount > 0) _receivedCount--;
            _acceptedCount++;
          } else {
            if (_receivedCount > 0) _receivedCount--;
            _declinedCount++;
          }
        });

        if (action == 'accept') {
          RaniAlert.success(
            context,
            'You accepted the connection request with $name! Full profile unlocked.',
            title: 'Connection Accepted! 🎉',
          );
        } else {
          RaniAlert.info(
            context,
            'Connection request with $name declined.',
            title: 'Request Declined',
          );
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
    return Scaffold(
      key: _scaffoldKey,
      drawer: widget.showAppBar ? const RaniSidebarDrawer() : null,
      backgroundColor: const Color(0xFFFAF7F2), // Matches theme ivory canvas
      appBar: widget.showAppBar
          ? RaniTopBar(
              title: 'Connections',
              notificationCount: _receivedCount,
              onMenuPressed: widget.onOpenMenu ?? () => _scaffoldKey.currentState?.openDrawer(),
              onNotificationPressed: widget.onOpenNotifications,
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),

            // Top Header Banner (Matches website: "Inbox & Requests")
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF750000).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(CupertinoIcons.mail_solid, color: Color(0xFF750000), size: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Inbox & Requests',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E0A0A),
                          ),
                        ),
                        Text(
                          'Candidates who have expressed interest in connecting',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            color: const Color(0xFF7A7067),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Top 4 Filter Tabs (Search icon | Received | Send | Accepted | Declined)
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

                  // Divider |
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
                      onTap: () => _onTabChanged(0),
                      child: _buildTabPill('Received $_receivedCount', _selectedTabIndex == 0),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 2. Send Tab
                  Center(
                    child: GestureDetector(
                      onTap: () => _onTabChanged(1),
                      child: _buildTabPill('Send $_sentCount', _selectedTabIndex == 1),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 3. Accepted Tab
                  Center(
                    child: GestureDetector(
                      onTap: () => _onTabChanged(2),
                      child: _buildTabPill('Accepted $_acceptedCount', _selectedTabIndex == 2),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 4. Declined Tab
                  Center(
                    child: GestureDetector(
                      onTap: () => _onTabChanged(3),
                      child: _buildTabPill('Declined $_declinedCount', _selectedTabIndex == 3),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Tab View Body Content
            Expanded(
              child: _buildTabBody(),
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
                colors: [Color(0xFF750000), Color(0xFF5A0000)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isSelected ? null : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? const Color(0xFF750000) : const Color(0xFFE8DFD5),
          width: 1.0,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFF750000).withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          color: isSelected ? Colors.white : const Color(0xFF750000),
        ),
      ),
    );
  }

  Widget _buildTabBody() {
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
                onPressed: _fetchRequestsForCurrentTab,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_requests.isEmpty) {
      final labels = ['Received', 'Sent', 'Accepted', 'Declined'];
      final currentLabel = labels[_selectedTabIndex];

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
                  _selectedTabIndex == 1
                      ? CupertinoIcons.paperplane_fill
                      : (_selectedTabIndex == 2
                          ? CupertinoIcons.checkmark_seal_fill
                          : (_selectedTabIndex == 3 ? CupertinoIcons.xmark_circle_fill : CupertinoIcons.tray_fill)),
                  size: 36,
                  color: const Color(0xFF750000),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'No $currentLabel Requests',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2B0A0D),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedTabIndex == 0
                    ? 'No pending requests received right now. When someone wants to connect with your profile, they will appear here.'
                    : (_selectedTabIndex == 1
                        ? 'You have not sent any pending connection requests yet. Explore compatible matches to connect.'
                        : (_selectedTabIndex == 2
                            ? 'No accepted connections yet. Once requests are mutually accepted, you can connect directly.'
                            : 'No declined connection requests.')),
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
      onRefresh: _fetchRequestsForCurrentTab,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _requests.length,
        itemBuilder: (context, index) {
          final c = _requests[index];
          return _buildWebsiteConnectionCard(c);
        },
      ),
    );
  }

  /// List-View Card for all 4 Connection Tabs (Matching Shortlisted View media_1793280615544_e48f7277.png)
  Widget _buildWebsiteConnectionCard(dynamic c) {
    final rawId = (c['candidate_code'] ?? c['id']?.toString() ?? c['profile_id'] ?? 'RM00024').toString().trim();
    String cleanId = rawId;
    while (cleanId.toUpperCase().startsWith('RMRM')) {
      cleanId = cleanId.substring(2);
    }
    if (!cleanId.toUpperCase().startsWith('RM')) {
      if (int.tryParse(cleanId) != null) {
        cleanId = 'RM${cleanId.padLeft(5, '0')}';
      } else {
        cleanId = 'RM$cleanId';
      }
    }
    final profileId = cleanId;
    final firstName = c['first_name'] ?? 'Candidate';
    final lastName = c['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim().isNotEmpty ? '$firstName $lastName'.trim() : 'Candidate';
    final age = c['age']?.toString() ?? '26';
    final height = c['height']?.toString() ?? "5' 10\" (177 cm)";
    final religion = c['religion']?.toString() ?? 'Muslim';
    final community = c['community']?.toString() ?? '';
    final religionText = community.isNotEmpty ? '$religion, $community' : religion;

    final profession = c['profession']?.toString() ?? c['designation']?.toString() ?? '';
    final income = c['annual_income']?.toString() ?? '';
    String professionText = '';
    if (profession.isNotEmpty && income.isNotEmpty) {
      professionText = '$profession • $income';
    } else if (profession.isNotEmpty) {
      professionText = profession;
    } else if (income.isNotEmpty) {
      professionText = income;
    } else {
      professionText = 'Professional';
    }

    final city = c['city']?.toString() ?? '';
    final state = c['state']?.toString() ?? '';
    final locationText = (city.isNotEmpty && state.isNotEmpty)
        ? '$city, $state'
        : (city.isNotEmpty ? city : (state.isNotEmpty ? state : 'West Bengal'));

    final photo = c['photo'] ?? c['profile_picture'] ?? '';
    final photosList = (c['photos'] is List && (c['photos'] as List).isNotEmpty) ? (c['photos'] as List) : [photo];
    final photoCount = photosList.length;
    final isVerified = c['verified'] == true || (c['bluetick'] is Map && c['bluetick']['is_accept'] == 1);
    final matchScore = c['match_score']?.toString() ?? c['match_percentage']?.toString() ?? '99';

    final isReceived = _selectedTabIndex == 0;
    final isSent = _selectedTabIndex == 1;
    final isAccepted = _selectedTabIndex == 2;

    final profileMap = (c is Map<String, dynamic>)
        ? c
        : (c is Map ? Map<String, dynamic>.from(c) : <String, dynamic>{});

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
                  initialProfileData: profileMap,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Photo Thumbnail (Left) + Information (Right)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Photo Thumbnail with Match Score & Photo Count
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 90,
                        height: 90,
                        color: const Color(0xFFEFE7DC),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            photo.toString().isNotEmpty
                                ? Image.network(
                                    photo.toString(),
                                    fit: BoxFit.cover,
                                    alignment: Alignment.topCenter,
                                    errorBuilder: (context, error, stackTrace) => const Center(
                                      child: Icon(CupertinoIcons.person_fill, size: 48, color: Color(0xFFB5A795)),
                                    ),
                                  )
                                : const Center(
                                    child: Icon(CupertinoIcons.person_fill, size: 48, color: Color(0xFFB5A795)),
                                  ),

                            // Top-Left: Match Score Pill (★ 99%)
                            Positioned(
                              top: 5,
                              left: 5,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE5B842), // Golden Yellow
                                  borderRadius: BorderRadius.circular(7),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.18),
                                      blurRadius: 3,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(CupertinoIcons.star_fill, size: 8.5, color: Color(0xFF4A0000)),
                                    const SizedBox(width: 2.5),
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

                            // Bottom-Right: Photos Count Pill (📷 1)
                            Positioned(
                              bottom: 5,
                              right: 5,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(CupertinoIcons.photo, size: 8.5, color: Colors.white),
                                    const SizedBox(width: 2.5),
                                    Text(
                                      '$photoCount',
                                      style: GoogleFonts.outfit(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // 2. Profile Details Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Candidate Name & Verified Badge
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
                                  size: 16,
                                  color: Color(0xFF2196F3),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 1),

                          // Formatted ID
                          Text(
                            'ID: $profileId',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF8E8E93),
                            ),
                          ),

                          const SizedBox(height: 4),

                          // Age, Height, Religion, Community
                          Text(
                            '$age yrs, $height • $religionText',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 11.8,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4A4A4A),
                            ),
                          ),

                          const SizedBox(height: 3),

                          // Profession & Income
                          Row(
                            children: [
                              const Icon(CupertinoIcons.briefcase, size: 12, color: Color(0xFF750000)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  professionText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF555555),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 2),

                          // Location
                          Row(
                            children: [
                              const Icon(CupertinoIcons.location_solid, size: 12, color: Color(0xFFD32F2F)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  locationText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF666666),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFEFE8DE)),
                const SizedBox(height: 10),

                // 3. Tab-Specific Action Buttons Row
                if (isReceived)
                  // a. in received: accept & declined btn
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E7E34), // Forest Green
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 40),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          onPressed: () => _respondInterest(c, 'accept'),
                          icon: const Icon(CupertinoIcons.checkmark_alt, size: 16),
                          label: Text(
                            'Accept',
                            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF750000),
                            side: const BorderSide(color: Color(0xFFD4AF37), width: 1.0),
                            minimumSize: const Size(0, 40),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _respondInterest(c, 'decline'),
                          icon: const Icon(CupertinoIcons.xmark, size: 14),
                          label: Text(
                            'Decline',
                            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  )
                else if (isSent)
                  // b. in send: waiting for aceeptance like disabled btn
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBF8F3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE8DFD5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          CupertinoIcons.hourglass_bottomhalf_fill,
                          size: 15,
                          color: Color(0xFF8D6E63),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'Waiting for Acceptance',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF8D6E63),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isAccepted)
                  // c. in accepted: view contact & chat themed golden like btn
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD54F), Color(0xFFD4A034)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4A034).withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: const Color(0xFF3E0A10),
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RaniMatchDetailsScreen(
                              profileId: profileId,
                              initialProfileData: profileMap,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(CupertinoIcons.chat_bubble_2_fill, size: 16, color: Color(0xFF4A0000)),
                      label: Text(
                        'View Contact & Chat',
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF3E0A10),
                        ),
                      ),
                    ),
                  )
                else
                  // d. in declined: subtle declined badge + secondary view profile
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECEFF1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCFD8DC)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(CupertinoIcons.xmark_circle_fill, size: 14, color: Color(0xFF78909C)),
                            const SizedBox(width: 5),
                            Text(
                              'Declined',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF546E7A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF750000),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RaniMatchDetailsScreen(
                                profileId: profileId,
                                initialProfileData: profileMap,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(CupertinoIcons.arrow_right_circle, size: 14),
                        label: Text(
                          'View Profile',
                          style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
