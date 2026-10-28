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
  String _selectedTab = 'new'; // 'new', 'accepted', 'shortlisted'
  bool _isLoading = true;
  List<dynamic> _matches = [];
  String? _errorMessage;
  int _newCount = 0;
  int _acceptedCount = 0;
  int _shortlistedCount = 0;

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
      String tabParam = 'todays';
      if (_selectedTab == 'accepted') {
        tabParam = 'accepted';
      } else if (_selectedTab == 'shortlisted') {
        tabParam = 'shortlisted';
      }

      final res = await ApiService.instance.getMatches(tab: tabParam);
      if (!mounted) return;

      if (res['success'] == true) {
        final List<dynamic> list = res['matches'] ?? [];
        final counts = res['counts'];

        setState(() {
          // Strictly guarantee shortlisted candidates do NOT appear in the NEW tab
          if (_selectedTab == 'new') {
            _matches = list.where((m) => m['is_shortlisted'] != true).toList();
          } else {
            _matches = list;
          }
          if (counts is Map) {
            final todays = counts['todays'] ?? counts['my_matches'];
            if (todays != null) {
              _newCount = todays is int ? todays : int.tryParse('$todays') ?? _newCount;
            }

            final accepted = counts['accepted'];
            if (accepted != null) {
              _acceptedCount = accepted is int ? accepted : int.tryParse('$accepted') ?? _acceptedCount;
            }

            final shortlisted = counts['shortlisted'];
            if (shortlisted != null) {
              _shortlistedCount = shortlisted is int ? shortlisted : int.tryParse('$shortlisted') ?? _shortlistedCount;
            }
          } else {
            if (_selectedTab == 'new') _newCount = _matches.length;
            if (_selectedTab == 'accepted') _acceptedCount = list.length;
            if (_selectedTab == 'shortlisted') _shortlistedCount = list.length;
          }
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
          if (isShortlisted) {
            // Once shortlisted, remove from NEW tab immediately
            if (_selectedTab == 'new') {
              _matches.removeWhere((m) {
                final mId = m['candidate_code'] ?? m['profile_id'] ?? m['id']?.toString();
                return mId == profileId || m == candidate;
              });
              if (_newCount > 0) _newCount--;
            }
            if (res['count'] is int) {
              _shortlistedCount = res['count'];
            } else {
              _shortlistedCount++;
            }
          } else {
            // When un-shortlisted from the Shortlisted tab, remove immediately
            if (_selectedTab == 'shortlisted') {
              _matches.removeWhere((m) {
                final mId = m['candidate_code'] ?? m['profile_id'] ?? m['id']?.toString();
                return mId == profileId || m == candidate;
              });
            }
            if (res['count'] is int) {
              _shortlistedCount = res['count'];
            } else {
              _shortlistedCount = _shortlistedCount > 0 ? _shortlistedCount - 1 : 0;
            }
          }
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
            // Tabs Row: Filter icon | (bar) NEW 61 Accepted 12 Shortlisted 8 (Theme styled)
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Filter icon (Theme Burgundy)
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
                            color: const Color(0xFF750000).withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Icon(
                        CupertinoIcons.slider_horizontal_3,
                        size: 18,
                        color: Color(0xFF750000), // Brand Royal Burgundy
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Vertical divider bar |
                  Center(
                    child: Container(
                      width: 1.5,
                      height: 22,
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.5), // Brand Gold tint
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

                  const SizedBox(width: 8),

                  // Shortlisted 8
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedTab = 'shortlisted');
                        _fetchMatches();
                      },
                      child: _buildTabPill('Shortlisted $_shortlistedCount', _selectedTab == 'shortlisted'),
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
        gradient: isSelected
            ? const LinearGradient(
                colors: [Color(0xFF8B0000), Color(0xFF6B0000)], // Royal Burgundy Theme
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
          color: isSelected ? Colors.white : const Color(0xFF5A0812), // Theme Burgundy for text
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
      String emptyTitle = 'No Matches Right Now';
      String emptySubtitle = 'Explore other categories or adjust your filters to discover compatible candidates.';

      if (_selectedTab == 'accepted') {
        emptyTitle = 'No Accepted Matches';
        emptySubtitle = 'When other members accept your connect requests, they will show up here.';
      } else if (_selectedTab == 'shortlisted') {
        emptyTitle = 'No Shortlisted Profiles';
        emptySubtitle = 'Tap the heart icon on any match card to save candidates to your shortlist.';
      }

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
                emptyTitle,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2B0A0D),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                emptySubtitle,
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

    // 1. Single profile per vertical screen view for NEW tab
    if (_selectedTab == 'new') {
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

    // 2. Scrollable ListView for Accepted and Shortlisted candidates
    return RefreshIndicator(
      color: const Color(0xFF750000),
      onRefresh: _fetchMatches,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 24),
        itemCount: _matches.length,
        itemBuilder: (context, index) {
          final candidate = _matches[index];
          return _buildCandidateListCard(
            candidate,
            isAcceptedTab: _selectedTab == 'accepted',
          );
        },
      ),
    );
  }

  /// Candidate List Card for Accepted & Shortlisted tabs
  Widget _buildCandidateListCard(dynamic c, {required bool isAcceptedTab}) {
    final profileId = c['candidate_code'] ?? c['profile_id'] ?? (c['id'] != null ? 'RM${c['id'].toString().padLeft(5, '0')}' : 'RM00024');
    final firstName = c['first_name'] ?? 'Candidate';
    final lastName = c['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final age = c['age']?.toString() ?? '24';
    final height = c['height']?.toString() ?? "5' 4\"";
    final religion = c['religion']?.toString() ?? 'Muslim';
    final community = c['community']?.toString() ?? '';
    final religionWithCommunity = (community.isNotEmpty && community.toLowerCase() != 'all' && community.toLowerCase() != 'all communities')
        ? '$religion, $community'
        : religion;
    final profession = c['profession']?.toString() ?? c['designation']?.toString() ?? 'Professional';
    final income = c['annual_income']?.toString() ?? '';
    final city = c['city']?.toString() ?? 'Kolkata';
    final state = c['state']?.toString() ?? 'West Bengal';
    final locationText = (city.isNotEmpty && state.isNotEmpty) ? '$city, $state' : (city.isNotEmpty ? city : state);
    final photo = c['photo'] ?? c['profile_picture'] ?? '';
    final isVerified = c['verified'] == true || c['is_verified'] == 1 || (c['bluetick'] != null && c['bluetick']['is_accept'] == 1);
    final matchScore = c['match_score']?.toString() ?? c['match_percentage']?.toString() ?? '95';
    final photoCount = (c['photos'] is List && (c['photos'] as List).isNotEmpty)
        ? (c['photos'] as List).length
        : (photo.toString().isNotEmpty ? 1 : 1);
    final isInterestSent = c['request_type'] == 'sent' || c['is_connected'] == true || isAcceptedTab;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                builder: (_) => RaniProfileDetailScreen(
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
                    // Candidate Photo with match badge
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            width: 95,
                            height: 115,
                            child: photo.toString().isNotEmpty
                                ? Image.network(
                                    photo.toString(),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: const Color(0xFFEFE7DC),
                                      child: const Icon(CupertinoIcons.person_fill, size: 45, color: Color(0xFFB5A795)),
                                    ),
                                  )
                                : Container(
                                    color: const Color(0xFFEFE7DC),
                                    child: const Icon(CupertinoIcons.person_fill, size: 45, color: Color(0xFFB5A795)),
                                  ),
                          ),
                        ),
                        // Match score badge
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5B842),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(CupertinoIcons.star_fill, size: 9, color: Color(0xFF4A0000)),
                                const SizedBox(width: 2.5),
                                Text(
                                  '$matchScore%',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF4A0000),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Photo count badge at bottom-right of thumbnail
                        Positioned(
                          bottom: 5,
                          right: 5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  CupertinoIcons.photo_on_rectangle,
                                  color: Color(0xFFE5B842),
                                  size: 9.5,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '$photoCount',
                                  style: GoogleFonts.outfit(
                                    fontSize: 9.5,
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
                                    fontSize: 16.5,
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
                          Text(
                            'ID: $profileId',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF8E8E93),
                            ),
                          ),
                          const SizedBox(height: 5),
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
                                  income.isNotEmpty ? '$profession • $income' : profession,
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
                          const SizedBox(height: 3),
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

                // Action Buttons Row
                if (isAcceptedTab) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFC8E6C9)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(CupertinoIcons.checkmark_alt_circle_fill, size: 13, color: Color(0xFF2E7D32)),
                            const SizedBox(width: 4),
                            Text(
                              'Connected',
                              style: GoogleFonts.outfit(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF750000),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
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
                        icon: const Icon(CupertinoIcons.chat_bubble_2_fill, size: 14),
                        label: Text(
                          'View Contact',
                          style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      // Shortlist Heart Toggle Button (Filled Red Heart)
                      GestureDetector(
                        onTap: () => _toggleShortlist(c),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0F2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFFCDD2)),
                          ),
                          child: const Icon(CupertinoIcons.heart_fill, size: 18, color: Color(0xFFE53935)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Connect CTA Button
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isInterestSent ? const Color(0xFF2E7D32) : const Color(0xFF750000),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: isInterestSent ? null : () => _sendRoyalInterest(c),
                          icon: Icon(
                            isInterestSent ? CupertinoIcons.checkmark_alt : CupertinoIcons.heart,
                            size: 15,
                          ),
                          label: Text(
                            isInterestSent ? 'Connected' : 'Connect Now',
                            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
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
    final photoCount = (c['photos'] is List && (c['photos'] as List).isNotEmpty)
        ? (c['photos'] as List).length
        : (photo.toString().isNotEmpty ? 1 : 1);
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

              // 2. Bottom Royal Burgundy Gradient Overlay for optimal legibility
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        const Color(0xFF260003).withValues(alpha: 0.15),
                        const Color(0xFF200003).withValues(alpha: 0.65),
                        const Color(0xFF150002).withValues(alpha: 0.96),
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
                        color: const Color(0xFF750000).withValues(alpha: 0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.star_fill, size: 12, color: Color(0xFF4A0000)),
                      const SizedBox(width: 4),
                      Text(
                        '$matchScore% Match',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF4A0000), // Theme Burgundy
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
                    // Candidate Name, Blue Tick, ID & Photo Count Badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Left: Candidate Name & ID
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
                              Text(
                                'ID: $profileId',
                                style: GoogleFonts.outfit(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Right: Photo Count Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.60),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                CupertinoIcons.photo_on_rectangle,
                                color: Color(0xFFE5B842),
                                size: 12.5,
                              ),
                              const SizedBox(width: 4.5),
                              Text(
                                '$photoCount Photos',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
