import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../components/rani_alert.dart';
import '../../components/rani_top_bar.dart';
import '../search/search_screen.dart';
import '../matches/details_screen.dart';
import '../matches/matches_screen.dart';
import '../auth/aadhaar_verification_screen.dart';
import '../auth/profile_completion_screen.dart';
import '../wallet/wallet_screen.dart';

/// Screen: Modern Home Screen redesigned matching the Matches screen theme
/// Theme: Ivory/Cream canvas (#FAF7F2), Royal Burgundy (#750000), Gold (#E5B842)
/// Updates:
/// 1. Flat, non-card style for action items (no 3D shadow or border boxes) with clean text, icons, and dividers (hr)
/// 2. Fixed search bar staying pinned at the top during scrolling
/// 3. Recommended for you profiles in a single line horizontal scrollable row (left to right & right to left)
class RaniHomeScreen extends StatefulWidget {
  final bool showAppBar;
  final VoidCallback? onOpenSearch;
  final VoidCallback? onOpenFilter;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenMatches;
  final bool showCandidateHeader;

  const RaniHomeScreen({
    super.key,
    this.showAppBar = true,
    this.onOpenSearch,
    this.onOpenFilter,
    this.onOpenProfile,
    this.onOpenMatches,
    this.showCandidateHeader = true,
  });

  @override
  State<RaniHomeScreen> createState() => _RaniHomeScreenState();
}

class _RaniHomeScreenState extends State<RaniHomeScreen> {
  bool _isLoading = true;
  List<dynamic> _matches = [];
  String? _errorMessage;

  // Search controller
  final TextEditingController _searchController = TextEditingController();

  // Cached candidate profile data
  Map<String, dynamic>? _candidate;

  @override
  void initState() {
    super.initState();
    _candidate = ApiService.instance.candidate;
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Fetch logged-in candidate profile data
      final profileRes = await ApiService.instance.getMyProfile();
      if (mounted && profileRes['success'] == true && profileRes['candidate'] != null) {
        _candidate = profileRes['candidate'] as Map<String, dynamic>;
      } else {
        _candidate = ApiService.instance.candidate;
      }

      // 2. Fetch matches for recommended section
      final res = await ApiService.instance.getMatches(tab: 'all');
      if (mounted) {
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

  int _calculateCompletionPercentage(Map<String, dynamic>? candidate) {
    if (candidate == null) return 60;
    if (candidate['profile_completed'] != null) {
      final val = candidate['profile_completed'];
      if (val is num) return val.toInt();
    }
    if (candidate['completion_percentage'] != null) {
      final val = candidate['completion_percentage'];
      if (val is num) return val.toInt();
    }

    int score = 40; // Base from initial registration
    if ((candidate['profile_picture'] ?? '').toString().isNotEmpty) score += 15;
    if ((candidate['about_me'] ?? candidate['about'] ?? '').toString().isNotEmpty) score += 10;
    if ((candidate['highest_qualification'] ?? candidate['education'] ?? '').toString().isNotEmpty) score += 10;
    if ((candidate['profession'] ?? candidate['designation'] ?? '').toString().isNotEmpty) score += 10;
    if ((candidate['father_profession'] ?? '').toString().isNotEmpty) score += 5;
    if (candidate['verified'] == true || candidate['aadhaar_verified'] == true) score += 10;
    return score.clamp(0, 100);
  }

  String _getShortCandidateName(Map<String, dynamic>? candidate) {
    final firstName = candidate?['first_name']?.toString() ?? 'Rahul';
    final lastName = candidate?['last_name']?.toString() ?? '';
    if (lastName.trim().isNotEmpty) {
      return '$firstName ${lastName.trim()[0]}.';
    }
    return firstName;
  }

  void _openSearchScreen([String? query]) {
    if (widget.onOpenSearch != null && (query == null || query.isEmpty)) {
      widget.onOpenSearch!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RaniSearchScreen(
            initialFilters: (query != null && query.isNotEmpty) ? {'keyword': query} : null,
          ),
        ),
      );
    }
  }

  void _openFilterScreen() {
    if (widget.onOpenFilter != null) {
      widget.onOpenFilter!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RaniSearchScreen()),
      );
    }
  }

  void _showAddPhotoDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0D8CE),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Upload Profile Photo',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose a clear, front-facing photo to increase your connection requests.',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: const Color(0xFF6E6E6E),
                  ),
                ),
                const SizedBox(height: 18),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF750000).withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(CupertinoIcons.camera_fill, color: Color(0xFF750000), size: 20),
                  ),
                  title: Text(
                    'Take a Photo',
                    style: GoogleFonts.outfit(fontSize: 14.5, fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(CupertinoIcons.chevron_right, size: 16, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(ctx);
                    RaniAlert.info(context, 'Camera capture will open.');
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF750000).withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(CupertinoIcons.photo_fill_on_rectangle_fill, color: Color(0xFF750000), size: 20),
                  ),
                  title: Text(
                    'Choose from Gallery',
                    style: GoogleFonts.outfit(fontSize: 14.5, fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(CupertinoIcons.chevron_right, size: 16, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(ctx);
                    RaniAlert.info(context, 'Gallery picker will open.');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final candidate = _candidate ?? ApiService.instance.candidate;
    final shortName = _getShortCandidateName(candidate);
    final completionPercent = _calculateCompletionPercentage(candidate);
    final isVerified = candidate?['verified'] == true || candidate?['aadhaar_verified'] == true;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2), // Theme ivory canvas
      // Topbar with candidate name, circular filter button & notification button with count
      appBar: widget.showAppBar
          ? RaniTopBar(
              title: shortName,
              notificationCount: 3,
              onNotificationPressed: () => RaniTopBar.showNotificationsSheet(context, 3),
              actions: [
                _buildCircularFilterButton(),
              ],
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            // 3. Fixed Search Bar pinned at the top during scrolling
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: _buildFixedSearchBar(),
            ),

            // Scrollable Content
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF750000),
                onRefresh: _loadInitialData,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  children: [
                    // 4. Candidate Profile Info (Flat on canvas, no heavy box)
                    _buildCandidateHeader(candidate, isVerified),

                    const SizedBox(height: 12),

                    // 5. In one line: Profile Edit button & Add Money button
                    _buildProfileAndMoneyActionButtons(),

                    // 6. Horizontal Divider (hr)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Divider(height: 1, thickness: 1, color: Color(0xFFEFE8DE)),
                    ),

                    // 7. Verify Your Profile (Flat list tile style: text and icon, no card/shadow/border)
                    _buildVerifyProfileRow(isVerified),

                    // 8. Horizontal Divider (hr)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Divider(height: 1, thickness: 1, color: Color(0xFFEFE8DE)),
                    ),

                    // 9. Complete Your Profile (Flat list tile style with % details & progress bar, no card/shadow/border)
                    _buildCompleteProfileRow(completionPercent),

                    // 10. Horizontal Divider (hr)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Divider(height: 1, thickness: 1, color: Color(0xFFEFE8DE)),
                    ),

                    // 11. Add Photos (Flat list tile style: text and icon, no card/shadow/border)
                    _buildAddPhotosRow(),

                    // Divider before recommended matches
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1, thickness: 1, color: Color(0xFFEFE8DE)),
                    ),

                    const SizedBox(height: 10),

                    // Recommended Matches Section (Single line left to right & right to left scrollable)
                    _buildRecommendedMatchesSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Circular Filter Button (white circle with royal burgundy slider icon)
  Widget _buildCircularFilterButton() {
    return GestureDetector(
      onTap: _openFilterScreen,
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
          color: Color(0xFF750000), // Royal burgundy
        ),
      ),
    );
  }

  /// 3. Fixed Search Bar pinned at the top
  Widget _buildFixedSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8DFD5), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF750000).withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.outfit(
          fontSize: 14,
          color: const Color(0xFF1E1E1E),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Search by ID, name, city, religion...',
          hintStyle: GoogleFonts.outfit(
            fontSize: 13.5,
            color: const Color(0xFF8E8E93),
          ),
          prefixIcon: const Icon(
            CupertinoIcons.search,
            color: Color(0xFF750000), // Brand royal burgundy
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(CupertinoIcons.clear_circled_solid, size: 18, color: Color(0xFF8E8E93)),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onSubmitted: (val) => _openSearchScreen(val),
      ),
    );
  }

  /// 4. Left: Round profile image with plus corner icon; Right: ID, below it Full Name (Flat, non-card, responsive)
  Widget _buildCandidateHeader(Map<String, dynamic>? candidate, bool isVerified) {
    final firstName = candidate?['first_name']?.toString() ?? 'Rahul';
    final lastName = candidate?['last_name']?.toString() ?? 'Mukherjee';
    final fullName = '$firstName $lastName'.trim().isNotEmpty ? '$firstName $lastName'.trim() : 'Royal Candidate';
    final candidateCode = candidate?['candidate_code'] ?? candidate?['profile_id'] ?? 'RM00024';
    final photo = candidate?['profile_picture']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          // Left: Round profile image with plus corner icon
          GestureDetector(
            onTap: _showAddPhotoDialog,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE5B842), width: 2.5), // Brand Gold ring
                  ),
                  child: ClipOval(
                    child: photo.isNotEmpty
                        ? Image.network(
                            photo,
                            width: 66,
                            height: 66,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildInitialsAvatar(firstName, 66),
                          )
                        : _buildInitialsAvatar(firstName, 66),
                  ),
                ),
                // Plus corner icon
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0xFF750000), // Royal burgundy
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.0),
                    ),
                    child: const Center(
                      child: Icon(
                        CupertinoIcons.plus,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // Right: ID, below it Full Name (Responsive Flexible/Expanded)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ID Capsule & verified tick
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
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
                    if (isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        CupertinoIcons.checkmark_seal_fill,
                        size: 16,
                        color: Color(0xFF2196F3),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                // Full name on the line below ID
                Text(
                  fullName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 18.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E1E1E),
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 5. In one line: Profile Edit button & Add Money button
  Widget _buildProfileAndMoneyActionButtons() {
    return Row(
      children: [
        // Profile Edit Button
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF750000),
              side: const BorderSide(color: Color(0xFF750000), width: 1.2),
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RaniProfileCompletionScreen()),
              ).then((_) => _loadInitialData());
            },
            icon: const Icon(CupertinoIcons.pencil_ellipsis_rectangle, size: 16, color: Color(0xFF750000)),
            label: Text(
              'Edit Profile',
              style: GoogleFonts.outfit(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF750000),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Add Money Button
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF750000),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RaniWalletScreen()),
              );
            },
            icon: const Icon(Icons.account_balance_wallet_rounded, size: 16, color: Color(0xFFE5B842)),
            label: Text(
              'Add Money',
              style: GoogleFonts.outfit(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 7. Verify Your Profile (Flat list tile style: text and icon, no card/shadow/border)
  Widget _buildVerifyProfileRow(bool isVerified) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RaniAadhaarVerificationScreen()),
        ).then((_) => _loadInitialData());
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isVerified
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFF750000).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.checkmark_seal_fill,
                size: 20,
                color: isVerified ? const Color(0xFF2E7D32) : const Color(0xFF750000),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Verify Your Profile',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E1E1E),
                          ),
                        ),
                      ),
                      if (isVerified) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Verified',
                            style: GoogleFonts.outfit(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isVerified
                        ? 'Your identity is fully verified with Aadhaar'
                        : 'Upload Aadhaar to get the trusted Blue Badge',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF757575),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(CupertinoIcons.chevron_right, size: 16, color: Color(0xFF750000)),
          ],
        ),
      ),
    );
  }

  /// 9. Complete your profile (Flat list tile style with % details & progress bar, no card/shadow/border)
  Widget _buildCompleteProfileRow(int completionPercent) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RaniProfileCompletionScreen()),
        ).then((_) => _loadInitialData());
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5B842).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.person_crop_circle_badge_checkmark,
                    size: 20,
                    color: Color(0xFF750000),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Complete your profile',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E1E1E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Fill remaining details to get 3x more matches',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF1DF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5B842).withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    '$completionPercent%',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF750000),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(CupertinoIcons.chevron_right, size: 16, color: Color(0xFF750000)),
              ],
            ),
            const SizedBox(height: 10),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (completionPercent / 100.0).clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: const Color(0xFFEFE8DE),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF750000)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 10. Add Photos (Flat list tile style: text and icon, no card/shadow/border)
  Widget _buildAddPhotosRow() {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: _showAddPhotoDialog,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF750000).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.photo_on_rectangle,
                size: 20,
                color: Color(0xFF750000),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Photos',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E1E1E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Upload recent photos to showcase your lifestyle',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF757575),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(CupertinoIcons.chevron_right, size: 16, color: Color(0xFF750000)),
          ],
        ),
      ),
    );
  }

  void _navigateToMatchesScreen() {
    if (widget.onOpenMatches != null) {
      widget.onOpenMatches!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RaniMatchesScreen()),
      );
    }
  }

  /// Recommended matches section with Single Line Left-to-Right & Right-to-Left Scrollable Profiles
  /// Shows max 4 candidate data cards + 1 'View More' card with an arrow navigating to Matches screen
  Widget _buildRecommendedMatchesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Recommended For You',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E1E1E),
                  letterSpacing: -0.2,
                ),
              ),
            ),
            TextButton(
              onPressed: _navigateToMatchesScreen,
              child: Text(
                'View All',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF750000),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (_isLoading)
          SizedBox(
            height: 235,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: 4,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) => Container(
                width: 155,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8DFD5)),
                ),
                child: const Center(
                  child: CupertinoActivityIndicator(color: Color(0xFF750000)),
                ),
              ),
            ),
          )
        else if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8DFD5)),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.exclamationmark_circle, color: Color(0xFF750000), size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[700]),
                  ),
                ),
                TextButton(
                  onPressed: _loadInitialData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        else if (_matches.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8DFD5)),
            ),
            child: Center(
              child: Text(
                'No recommended profiles right now.',
                style: GoogleFonts.outfit(fontSize: 13.5, color: Colors.grey[600]),
              ),
            ),
          )
        else ...[
          // Show max 4 data cards + 1 'View More' card with arrow
          Builder(
            builder: (context) {
              final displayMatches = _matches.take(4).toList();
              final totalCount = displayMatches.length + 1;

              return SizedBox(
                height: 235,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: totalCount,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    if (index < displayMatches.length) {
                      final candidate = displayMatches[index];
                      return _buildHorizontalCandidateCard(candidate);
                    } else {
                      return _buildViewMoreMatchesCard();
                    }
                  },
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  /// Last Card in the horizontal list: Contains arrow to navigate directly to Matches screen
  Widget _buildViewMoreMatchesCard() {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DFD5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF750000).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _navigateToMatchesScreen,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Circular button with forward arrow
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF750000), // Theme Royal Burgundy
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF750000).withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      CupertinoIcons.arrow_right,
                      color: Color(0xFFE5B842), // Brand Gold Arrow
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'View More',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'All Matches',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF750000),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Single card in the horizontal single line scrollable row
  Widget _buildHorizontalCandidateCard(dynamic candidate) {
    final profileId = candidate['candidate_code'] ?? candidate['profile_id'] ?? candidate['id']?.toString() ?? '';
    final firstName = candidate['first_name'] ?? 'Candidate';
    final lastName = candidate['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final age = candidate['age']?.toString() ?? '24';
    final profession = candidate['profession'] ?? candidate['designation'] ?? 'Professional';
    final city = candidate['city'] ?? 'Kolkata';
    final photo = candidate['profile_picture'] ?? candidate['photo'] ?? '';
    final matchScore = (candidate['match_score'] as num?)?.toInt() ?? 92;

    return Container(
      width: 155,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DFD5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF750000).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RaniMatchDetailsScreen(
                  profileId: profileId,
                  initialProfileData: candidate,
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Thumbnail with match badge
              Expanded(
                flex: 12,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    photo.toString().isNotEmpty
                        ? Image.network(
                            photo.toString(),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: const Color(0xFFF3ECE4),
                              child: const Icon(CupertinoIcons.person_fill, size: 40, color: Color(0xFF8B0000)),
                            ),
                          )
                        : Container(
                            color: const Color(0xFFF3ECE4),
                            child: const Icon(CupertinoIcons.person_fill, size: 40, color: Color(0xFF8B0000)),
                          ),
                    // Match score pill
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5B842),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(CupertinoIcons.star_fill, size: 9, color: Color(0xFF4A0000)),
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
                  ],
                ),
              ),

              // Details
              Padding(
                padding: const EdgeInsets.all(9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$fullName, $age',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E1E1E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profession,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: const Color(0xFF6B6B6B),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      city,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 10.5,
                        color: const Color(0xFF8E8E93),
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

  Widget _buildInitialsAvatar(String name, double size) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'R';
    return Container(
      width: size,
      height: size,
      color: const Color(0xFF750000), // Royal burgundy
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.outfit(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}
