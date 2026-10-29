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
  late int _selectedTabIndex; // 0: received, 1: sent, 2: accepted, 3: declined
  bool _isLoading = true;
  List<dynamic> _requests = [];
  String? _errorMessage;

  int _receivedCount = 0;
  int _sentCount = 0;
  int _acceptedCount = 0;
  int _declinedCount = 0;

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
          _receivedCount = (c['received'] ?? c['pending'] as num?)?.toInt() ?? _receivedCount;
          _sentCount = (c['sent'] as num?)?.toInt() ?? _sentCount;
          _acceptedCount = (c['accepted'] as num?)?.toInt() ?? _acceptedCount;
          _declinedCount = (c['declined'] ?? c['rejected'] as num?)?.toInt() ?? _declinedCount;
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
      backgroundColor: const Color(0xFFFAF7F2), // Matches theme ivory canvas
      appBar: widget.showAppBar
          ? RaniTopBar(
              title: 'Connections',
              notificationCount: _receivedCount,
              onMenuPressed: widget.onOpenMenu,
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

  /// Exact Website-Matched Connection Card (Matching Image media_1793275360902_10fb056f.jpg)
  Widget _buildWebsiteConnectionCard(dynamic c) {
    final profileId = (c['candidate_code'] ?? c['id']?.toString() ?? c['profile_id'] ?? 'RM00024').toString();
    final firstName = c['first_name'] ?? 'Candidate';
    final lastName = c['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final age = c['age']?.toString() ?? '22';
    final height = c['height']?.toString() ?? "5' 4\" (162 cm)";
    final religion = c['religion']?.toString() ?? 'Muslim';
    final community = c['community']?.toString() ?? 'Shia';
    final motherTongue = c['mother_tongue']?.toString() ?? 'Bengali';
    final diet = c['diet']?.toString() ?? 'Non-Vegetarian';
    final profession = c['profession']?.toString() ?? 'Doctor';
    final companyName = c['company_name']?.toString() ?? 'ESI Hospital';
    final annualIncome = c['annual_income']?.toString() ?? '4 - 5 Lakhs';
    final highestQualification = c['highest_qualification']?.toString() ?? 'Medical';
    final city = c['city']?.toString() ?? 'Howrah';
    final state = c['state']?.toString() ?? 'West Bengal';
    final photo = c['photo'] ?? c['profile_picture'] ?? '';
    final photosList = (c['photos'] is List) ? (c['photos'] as List) : [photo];
    final isVerified = c['verified'] == true || (c['bluetick'] is Map && c['bluetick']['is_accept'] == 1);
    final matchScore = c['match_score']?.toString() ?? '87';
    final receivedAgo = c['received_ago']?.toString() ?? 'Received recently';
    final matchReasons = (c['match_reasons'] is List)
        ? (c['match_reasons'] as List)
        : ['Muslim Religion', 'Howrah Resident'];

    final isReceived = _selectedTabIndex == 0;
    final isSent = _selectedTabIndex == 1;
    final isAccepted = _selectedTabIndex == 2;
    final isDeclined = _selectedTabIndex == 3;

    final profileMap = (c is Map<String, dynamic>)
        ? c
        : (c is Map ? Map<String, dynamic>.from(c) : <String, dynamic>{});

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEFE8DE), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Photo with Top Badges & Candidate Name (Matching Website)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                    child: SizedBox(
                      width: double.infinity,
                      height: 230,
                      child: photo.toString().isNotEmpty
                          ? Image.network(
                              photo.toString(),
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: const Color(0xFFEFE7DC),
                                child: const Icon(CupertinoIcons.person_fill, size: 64, color: Color(0xFFB5A795)),
                              ),
                            )
                          : Container(
                              color: const Color(0xFFEFE7DC),
                              child: const Icon(CupertinoIcons.person_fill, size: 64, color: Color(0xFFB5A795)),
                            ),
                    ),
                  ),

                  // Vignette gradient for text contrast at the bottom of the photo
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.25),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.75),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Top Badges
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status badge (Amber / Green)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isAccepted
                                ? const Color(0xFF1E7E34)
                                : (isDeclined ? const Color(0xFF6B6B6B) : const Color(0xFFE5B842)),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isAccepted
                                    ? CupertinoIcons.checkmark_seal_fill
                                    : (isSent ? CupertinoIcons.paperplane_fill : CupertinoIcons.check_mark_circled_solid),
                                size: 12,
                                color: isAccepted ? Colors.white : const Color(0xFF1E0A0A),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isReceived
                                    ? 'Received Interest'
                                    : (isSent
                                        ? 'Request Sent'
                                        : (isAccepted ? 'Connected Partner' : 'Declined Request')),
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isAccepted ? Colors.white : const Color(0xFF1E0A0A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        // Time Ago pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            receivedAgo,
                            style: GoogleFonts.outfit(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.95),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom of photo: Candidate Name, ID, Match % and Photos count pill
                  Positioned(
                    bottom: 12,
                    left: 14,
                    right: 14,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
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
                                      style: GoogleFonts.playfairDisplay(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withValues(alpha: 0.6),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (isVerified) ...[
                                    const SizedBox(width: 6),
                                    const Icon(
                                      CupertinoIcons.checkmark_seal_fill,
                                      size: 17,
                                      color: Color(0xFF2196F3),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ID: $profileId  •  $matchScore% Match',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFF3E5AB),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Photos count pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white24, width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(CupertinoIcons.photo, size: 11, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                '${photosList.length} Photos',
                                style: GoogleFonts.outfit(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // 2. Personal & Matrimonial Profile Details (Soft box matching website)
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDFBF7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFF0EAE1)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF7A7067)),
                                    children: [
                                      const TextSpan(text: 'Age / Ht: '),
                                      TextSpan(
                                        text: '$age yrs, $height',
                                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: const Color(0xFF1E0A0A)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF7A7067)),
                                    children: [
                                      const TextSpan(text: 'Religion: '),
                                      TextSpan(
                                        text: '$religion, $community',
                                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: const Color(0xFF1E0A0A)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF7A7067)),
                                    children: [
                                      const TextSpan(text: 'Tongue: '),
                                      TextSpan(
                                        text: motherTongue,
                                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: const Color(0xFF1E0A0A)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF7A7067)),
                                    children: [
                                      const TextSpan(text: 'Diet: '),
                                      TextSpan(
                                        text: diet,
                                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: const Color(0xFF1E0A0A)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Career & Location
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(CupertinoIcons.briefcase, size: 14, color: Color(0xFF750000)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profession,
                                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E0A0A)),
                              ),
                              Text(
                                '$companyName  •  $annualIncome',
                                style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF7A7067)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        const Icon(Icons.school_outlined, size: 15, color: Color(0xFFE5B842)),
                        const SizedBox(width: 8),
                        Text(
                          highestQualification,
                          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF4A4035)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        const Icon(CupertinoIcons.location_solid, size: 14, color: Color(0xFF750000)),
                        const SizedBox(width: 8),
                        Text(
                          '$city, $state',
                          style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6B6055)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Matching reasons chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: matchReasons.map((reason) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF7F2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFEFE8DE)),
                          ),
                          child: Text(
                            '✓ $reason',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF750000),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 14),

                    // 3. Action Buttons Row (Matching Website: Accept + Cross Button)
                    if (isReceived)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E7E34), // Forest Green
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 44),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              onPressed: () => _respondInterest(c, 'accept'),
                              icon: const Icon(CupertinoIcons.checkmark_alt, size: 18),
                              label: Text(
                                'Accept',
                                style: GoogleFonts.outfit(fontSize: 14.5, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => _respondInterest(c, 'decline'),
                            child: Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE5DDD2)),
                              ),
                              child: const Icon(CupertinoIcons.xmark, color: Color(0xFF6B6B6B), size: 19),
                            ),
                          ),
                        ],
                      )
                    else if (isSent)
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF8E1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFFE082)),
                              ),
                              child: Center(
                                child: Text(
                                  '⏳ Pending Candidate Response',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF8D6E63),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 42),
                              backgroundColor: const Color(0xFF750000),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
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
                            child: const Text('View Profile'),
                          ),
                        ],
                      )
                    else if (isAccepted)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 44),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
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
                              icon: const Icon(CupertinoIcons.chat_bubble_2_fill, size: 16),
                              label: Text(
                                'View Contact & Chat',
                                style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Request Declined',
                              style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                            ),
                          ),
                          TextButton(
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
                            child: Text(
                              'View Profile',
                              style: GoogleFonts.outfit(color: const Color(0xFF750000), fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
