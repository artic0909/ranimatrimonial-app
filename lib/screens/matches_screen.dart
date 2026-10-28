import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../components/rani_alert.dart';
import '../components/rani_skeleton_loader.dart';
import 'profile_detail_screen.dart';
import 'search_screen.dart';

/// Screen: Matches Screen (Matches the exact UI of user's phone screenshot)
/// Features:
/// - Top bar: Hamburger/Menu, "Matches", Notification Bell
/// - Horizontal Filter Pills: Search, New (61), Daily (18), All Matches
/// - Immersive vertical profile match card:
///   - Candidate photo with photo counter badge (📷 1) & 3-dot options
///   - Name, Age, Blue Tick verified badge (e.g. Sumaiya K, 26 ✔)
///   - Height • Religion/Caste • Profession (e.g. 5' 1" • Sunni • Teacher)
///   - Location (e.g. Midnapore, West Bengal)
///   - Activity badges: 🟢 20h ago, 👥 You & Her
///   - Bottom Royal Action Bar: "Like this Profile? Connect Now" + Large Circular Green Checkmark Button
class RaniMatchesScreen extends StatefulWidget {
  final VoidCallback? onOpenSearch;
  final VoidCallback? onOpenNotifications;

  const RaniMatchesScreen({
    super.key,
    this.onOpenSearch,
    this.onOpenNotifications,
  });

  @override
  State<RaniMatchesScreen> createState() => _RaniMatchesScreenState();
}

class _RaniMatchesScreenState extends State<RaniMatchesScreen> {
  String _selectedTab = 'new'; // 'new' or 'accepted'
  bool _isLoading = true;
  List<dynamic> _matches = [];
  String? _errorMessage;
  final int _newCount = 61;
  final int _acceptedCount = 12;

  @override
  void initState() {
    super.initState();
    _fetchMatches();
  }

  Future<void> _fetchMatches() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tabParam = _selectedTab == 'accepted' ? 'connected' : 'new';
      final res = await ApiService.instance.getMatches(tab: tabParam);
      if (!mounted) return;

      if (res['success'] == true) {
        setState(() {
          _matches = res['matches'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = res['message'] ?? 'Unable to load matches.';
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

  Future<void> _sendRoyalInterest(dynamic candidate) async {
    final candidateId = candidate['id']?.toString() ?? candidate['candidate_code'] ?? candidate['profile_id'] ?? '';
    final name = '${candidate['first_name'] ?? 'Candidate'}'.trim();

    try {
      final res = await ApiService.instance.sendInterest(candidateId);
      if (!mounted) return;

      if (res['success'] == true) {
        setState(() {
          candidate['request_type'] = 'sent';
          candidate['is_connected'] = true;
        });
        RaniAlert.success(
          context,
          'Interest sent to $name! You will be notified when accepted.',
          title: 'Connected!',
        );
      } else {
        RaniAlert.error(context, res['message'] ?? 'Could not send interest.');
      }
    } catch (e) {
      if (mounted) RaniAlert.error(context, 'Error: $e');
    }
  }

  Future<void> _toggleShortlist(dynamic candidate) async {
    final profileId = candidate['candidate_code'] ?? candidate['profile_id'] ?? candidate['id']?.toString() ?? '';
    final name = '${candidate['first_name'] ?? 'Candidate'}'.trim();
    final isCurrentlyShortlisted = candidate['is_shortlisted'] == true;

    setState(() {
      candidate['is_shortlisted'] = !isCurrentlyShortlisted;
    });

    try {
      final res = await ApiService.instance.toggleShortlist(profileId);
      if (!mounted) return;

      if (res['success'] == true) {
        final isShortlisted = res['shortlisted'] == true;
        setState(() {
          candidate['is_shortlisted'] = isShortlisted;
        });
        RaniAlert.success(
          context,
          isShortlisted ? '$name added to Shortlist!' : '$name removed from Shortlist.',
          title: isShortlisted ? 'Shortlisted' : 'Removed',
        );
      } else {
        setState(() {
          candidate['is_shortlisted'] = isCurrentlyShortlisted;
        });
        RaniAlert.error(context, res['message'] ?? 'Action failed.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          candidate['is_shortlisted'] = isCurrentlyShortlisted;
        });
        RaniAlert.error(context, 'Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF7F2),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: const Border(), // Explicitly removes bottom border line
        leading: IconButton(
          icon: const Icon(CupertinoIcons.line_horizontal_3, color: Color(0xFF1E1E1E), size: 24),
          onPressed: () {},
        ),
        title: Text(
          'Matches',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.bell, color: Color(0xFF1E1E1E), size: 22),
            onPressed: widget.onOpenNotifications,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Tabs Row: Filter icon | (bar) NEW 61 Accepted 12 (Horizontally scrollable for small screens)
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Filter icon
                  GestureDetector(
                    onTap: () {
                      if (widget.onOpenSearch != null) {
                        widget.onOpenSearch!();
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RaniSearchScreen()),
                        );
                      }
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
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Icon(
                        CupertinoIcons.slider_horizontal_3,
                        size: 18,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Vertical divider bar |
                  Center(
                    child: Container(
                      width: 1.5,
                      height: 22,
                      color: const Color(0xFFD6CDC1),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // NEW 61
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedTab = 'new');
                        _fetchMatches();
                      },
                      child: _buildTabPill('NEW $_newCount', _selectedTab == 'new'),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Accepted 12
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedTab = 'accepted');
                        _fetchMatches();
                      },
                      child: _buildTabPill('Accepted $_acceptedCount', _selectedTab == 'accepted'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Main Content: Full-image single card vertical PageView
            Expanded(
              child: _buildBody(),
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
        color: isSelected ? const Color(0xFF26121B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? const Color(0xFF26121B) : const Color(0xFFE8DFD5),
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 12.5,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          color: isSelected ? Colors.white : const Color(0xFF4A4A4A),
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: RaniSkeletonGrid(itemCount: 2),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.exclamationmark_triangle, size: 48, color: Color(0xFFD32F2F)),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 14),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF750000),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _fetchMatches,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_matches.isEmpty) {
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
                child: const Icon(CupertinoIcons.heart_fill, size: 36, color: Color(0xFF750000)),
              ),
              const SizedBox(height: 16),
              Text(
                _selectedTab == 'accepted' ? 'No Accepted Matches' : 'No Matches Right Now',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2B0A0D),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedTab == 'accepted'
                    ? 'When other members accept your connect requests, they will show up here.'
                    : 'Explore other categories or adjust your filters to discover compatible candidates.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF6B6B6B)),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF750000),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RaniSearchScreen()),
                  );
                },
                icon: const Icon(CupertinoIcons.search, size: 16),
                label: const Text('Search All Candidates'),
              ),
            ],
          ),
        ),
      );
    }

    // Single profile per vertical screen view
    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: _matches.length,
      itemBuilder: (context, index) {
        final candidate = _matches[index];
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
          child: _buildFullImageMatchCard(candidate),
        );
      },
    );
  }

  /// Full-Image Immersive Profile Match Card
  Widget _buildFullImageMatchCard(dynamic c) {
    final profileId = c['candidate_code'] ?? c['profile_id'] ?? (c['id'] != null ? 'RM${c['id'].toString().padLeft(5, '0')}' : 'RM00024');
    final firstName = c['first_name'] ?? 'Candidate';
    final lastName = c['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final age = c['age']?.toString() ?? '22';
    final religion = c['religion']?.toString() ?? 'Muslim';
    final profession = c['profession']?.toString() ?? c['designation']?.toString() ?? 'Doctor';
    final city = c['city']?.toString() ?? 'Howrah';
    final state = c['state']?.toString() ?? 'West Bengal';
    final locationText = (city.isNotEmpty && state.isNotEmpty) ? '$city, $state' : (city.isNotEmpty ? city : state);
    final photo = c['photo'] ?? c['profile_picture'] ?? '';
    final isVerified = c['verified'] == true || c['is_verified'] == 1 || (c['bluetick'] != null && c['bluetick']['is_accept'] == 1);
    final isShortlisted = c['is_shortlisted'] == true;
    final matchScore = c['match_score']?.toString() ?? c['match_percentage']?.toString() ?? '99';
    final isInterestSent = c['request_type'] == 'sent' || c['is_connected'] == true;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RaniProfileDetailScreen(
              profileId: profileId,
              initialProfileData: c,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Full Image Background
              photo.toString().isNotEmpty
                  ? Image.network(
                      photo.toString(),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFFDED5C9),
                        child: const Icon(CupertinoIcons.person_fill, size: 80, color: Colors.white70),
                      ),
                    )
                  : Container(
                      color: const Color(0xFFDED5C9),
                      child: const Icon(CupertinoIcons.person_fill, size: 80, color: Colors.white70),
                    ),

              // 2. Bottom Dark Gradient Overlay for optimal legibility
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.52),
                        Colors.black.withValues(alpha: 0.94),
                      ],
                      stops: const [0.42, 0.62, 0.80, 1.0],
                    ),
                  ),
                ),
              ),

              // 3. Top-Left Corner: Percentage of Matching
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5B842), // Golden yellow
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.star_fill, size: 12, color: Color(0xFF26121B)),
                      const SizedBox(width: 4),
                      Text(
                        '$matchScore% Match',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF26121B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Top-Right Corner: Wishlist Heart Icon
              Positioned(
                top: 14,
                right: 14,
                child: GestureDetector(
                  onTap: () => _toggleShortlist(c),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      isShortlisted ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                      color: isShortlisted ? const Color(0xFFE53935) : const Color(0xFF333333),
                      size: 20,
                    ),
                  ),
                ),
              ),

              // 5. Bottom Info Content (Name, Blue Tick, ID, Age, Religion, Professional, Location, Connect Button)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Candidate Name & Blue Tick
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.2,
                              shadows: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            CupertinoIcons.checkmark_seal_fill,
                            size: 20,
                            color: Color(0xFF2196F3), // Verified Blue Tick
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 2),

                    // Candidate ID
                    Text(
                      'ID: $profileId',
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                        letterSpacing: 0.3,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Age • Religion • Professional
                    Text(
                      '$age yrs • $religion • $profession',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.95),
                        shadows: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 3),

                    // Location (City, State)
                    Row(
                      children: [
                        const Icon(
                          CupertinoIcons.location_solid,
                          size: 14,
                          color: Color(0xFFFF5252),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            locationText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.88),
                              shadows: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Connect Button Just
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isInterestSent ? const Color(0xFF2E7D32) : const Color(0xFF750000),
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: isInterestSent ? null : () => _sendRoyalInterest(c),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isInterestSent ? CupertinoIcons.checkmark_alt : CupertinoIcons.heart,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isInterestSent ? 'Connected' : 'Connect',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
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
            ],
          ),
        ),
      ),
    );
  }
}
