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
  String _selectedTab = 'daily'; // 'search', 'new', 'daily', 'all'
  bool _isLoading = true;
  List<dynamic> _matches = [];
  String? _errorMessage;

  final List<Map<String, dynamic>> _tabs = const [
    {'id': 'search', 'label': 'Search', 'icon': CupertinoIcons.search},
    {'id': 'new', 'label': 'New (61)'},
    {'id': 'daily', 'label': 'Daily (18)'},
    {'id': 'all', 'label': 'All Matches'},
  ];

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
      final res = await ApiService.instance.getMatches(tab: _selectedTab == 'new' ? 'new' : 'all');
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

  List<String> _getMatchReasons(dynamic c) {
    if (c['match_reasons'] is List && (c['match_reasons'] as List).isNotEmpty) {
      return (c['match_reasons'] as List).map((e) => e.toString()).toList();
    }

    final List<String> reasons = [];
    final rel = c['religion']?.toString().trim() ?? '';
    if (rel.isNotEmpty) {
      reasons.add('$rel Religion');
    }

    final comm = c['community']?.toString().trim() ?? '';
    if (comm.isNotEmpty && comm.toLowerCase() != 'all' && comm.toLowerCase() != 'all communities') {
      reasons.add('$comm Community');
    }

    final state = c['state']?.toString().trim() ?? '';
    if (state.isNotEmpty) {
      reasons.add('$state State');
    }

    final tongue = c['mother_tongue']?.toString().trim() ?? '';
    if (tongue.isNotEmpty && reasons.length < 3) {
      reasons.add('$tongue Tongue');
    }

    return reasons.isEmpty ? ['Compatible Profile'] : reasons;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF7F2),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
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
            // 1. Horizontal Filter Pills (Search, New (61), Daily (18), All Matches)
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _tabs.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final tab = _tabs[index];
                  final isSearch = tab['id'] == 'search';
                  final isSelected = _selectedTab == tab['id'];

                  return GestureDetector(
                    onTap: () {
                      if (isSearch) {
                        if (widget.onOpenSearch != null) {
                          widget.onOpenSearch!();
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RaniSearchScreen()),
                          );
                        }
                      } else {
                        setState(() {
                          _selectedTab = tab['id'];
                        });
                        _fetchMatches();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF26121B) // Dark pill matching user screenshot
                            : Colors.white,
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (tab['icon'] != null) ...[
                            Icon(
                              tab['icon'] as IconData,
                              size: 13,
                              color: isSelected ? Colors.white : const Color(0xFF555555),
                            ),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            tab['label'] as String,
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected ? Colors.white : const Color(0xFF4A4A4A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // 2. Main Match Content (Immersive Visual Profile Card)
            Expanded(
              child: _buildBody(),
            ),
          ],
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
                'No Matches Right Now',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2B0A0D),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Explore other categories or adjust your search filters to discover more compatible brides and grooms.',
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

    return RefreshIndicator(
      color: const Color(0xFF750000),
      onRefresh: _fetchMatches,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: _matches.length,
        separatorBuilder: (_, _) => const SizedBox(height: 18),
        itemBuilder: (context, index) {
          final candidate = _matches[index];
          return _buildWebsiteStyleMatchCard(candidate);
        },
      ),
    );
  }

  /// Website-Parity Match Card matching user screenshot media_1793185678101_a5d54a59.png
  Widget _buildWebsiteStyleMatchCard(dynamic c) {
    final profileId = c['candidate_code'] ?? c['profile_id'] ?? (c['id'] != null ? 'RM${c['id'].toString().padLeft(5, '0')}' : 'RM00024');
    final firstName = c['first_name'] ?? 'Candidate';
    final lastName = c['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final age = c['age']?.toString() ?? '22';
    final height = c['height']?.toString() ?? "5' 4\"";
    final religion = c['religion']?.toString() ?? 'Muslim';
    final community = c['community']?.toString() ?? '';
    final religionWithCommunity = (community.isNotEmpty && community.toLowerCase() != 'all' && community.toLowerCase() != 'all communities')
        ? '$religion, $community'
        : religion;
    final motherTongue = c['mother_tongue']?.toString() ?? 'Bengali';
    final diet = c['diet']?.toString() ?? 'Non-Vegetarian';
    final profession = c['profession']?.toString() ?? c['designation']?.toString() ?? 'Doctor';
    final income = c['annual_income']?.toString() ?? '';
    final qualification = c['highest_qualification']?.toString() ?? 'Medical';
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
    final matchReasons = _getMatchReasons(c);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFE8DE), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Top Photo Banner
            GestureDetector(
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
              child: Stack(
                children: [
                  // Photo
                  SizedBox(
                    height: 270,
                    width: double.infinity,
                    child: photo.toString().isNotEmpty
                        ? Image.network(
                            photo.toString(),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: const Color(0xFFEFE7DC),
                              child: const Icon(CupertinoIcons.person_fill, size: 70, color: Color(0xFFB5A795)),
                            ),
                          )
                        : Container(
                            color: const Color(0xFFEFE7DC),
                            child: const Icon(CupertinoIcons.person_fill, size: 70, color: Color(0xFFB5A795)),
                          ),
                  ),

                  // Bottom dark gradient overlay for text legibility
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.1),
                            Colors.black.withValues(alpha: 0.85),
                          ],
                          stops: const [0.5, 0.72, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Top-Left Gold Match Score Pill (★ 99% Match)
                  Positioned(
                    top: 12,
                    left: 12,
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
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF26121B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Top-Right Circular Shortlist Heart Button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => _toggleShortlist(c),
                      child: Container(
                        width: 36,
                        height: 36,
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
                          size: 19,
                        ),
                      ),
                    ),
                  ),

                  // Bottom overlay: Name, Blue Tick, ID & Photo counter
                  Positioned(
                    bottom: 12,
                    left: 14,
                    right: 14,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Left: Name, Blue Tick, ID
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
                                      style: GoogleFonts.playfairDisplay(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
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
                                    const SizedBox(width: 5),
                                    const Icon(
                                      CupertinoIcons.checkmark_seal_fill,
                                      size: 18,
                                      color: Color(0xFF2196F3), // Blue Tick
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
                                  color: Colors.white.withValues(alpha: 0.92),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Right: Photo Count Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                CupertinoIcons.photo_on_rectangle,
                                color: Color(0xFFE5B842),
                                size: 12,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '$photoCount Photos',
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
            ),

            // 2. Card Bio & Particulars
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Specs 2x2 Grid (Age/Ht, Religion, Tongue, Diet)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F7F4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFEFE8DE)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Text(
                                    'Age / Ht: ',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color: const Color(0xFF8E8E93),
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      '$age yrs, $height',
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1E1E1E),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Row(
                                children: [
                                  Text(
                                    'Religion: ',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color: const Color(0xFF8E8E93),
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      religionWithCommunity,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1E1E1E),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Text(
                                    'Tongue: ',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color: const Color(0xFF8E8E93),
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      motherTongue,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1E1E1E),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Row(
                                children: [
                                  Text(
                                    'Diet: ',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color: const Color(0xFF8E8E93),
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      diet,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1E1E1E),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Career & Profession (Shows profession & income; NO company name per user instruction)
                  Row(
                    children: [
                      const Icon(CupertinoIcons.briefcase, size: 15, color: Color(0xFF750000)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          income.isNotEmpty ? '$profession • $income' : profession,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E1E1E),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Highest Education
                  Row(
                    children: [
                      const Icon(Icons.school_outlined, size: 15, color: Color(0xFFD4A017)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          qualification,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF4A4A4A),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Location (Shows City, State ONLY; NO distance per user instruction)
                  Row(
                    children: [
                      const Icon(CupertinoIcons.location_solid, size: 15, color: Color(0xFFD32F2F)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          locationText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF4A4A4A),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Matching criteria pills with checkmark
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: matchReasons.map((reason) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF5EC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE8DAC2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(CupertinoIcons.checkmark, size: 10.5, color: Color(0xFF750000)),
                            const SizedBox(width: 4),
                            Text(
                              reason,
                              style: GoogleFonts.outfit(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF4A0000),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 14),

                  // 3. Connect Button (Deep Burgundy CTA matching user photo)
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isInterestSent ? const Color(0xFF2E7D32) : const Color(0xFF4A0000),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isInterestSent ? null : () => _sendRoyalInterest(c),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isInterestSent ? CupertinoIcons.checkmark_alt : CupertinoIcons.heart,
                            size: 17,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isInterestSent ? 'Connected' : 'Connect',
                            style: GoogleFonts.outfit(
                              fontSize: 14.5,
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
    );
  }
}
