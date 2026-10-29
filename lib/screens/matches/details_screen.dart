import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../components/rani_alert.dart';
import '../../components/rani_matrimonial_loader.dart';
import '../../components/rani_skeleton_loader.dart';

/// Screen: Candidate Details Screen (Matches Theme)
/// Features:
/// 0. Profile images carousel with bottom pill dots; tap image to view in full-screen pinch-zoom viewer
/// 1. About Myself section
/// 2. Match compatibility score (%) & specific matching criteria items
/// 3. Personal details (Gender, Height, Marital status, Mother tongue, Religion, Community/Caste, Sub community, Gotra, Manglik, Diet, Blood group)
/// 4. Education & career details (Highest qualification, Working with, Annual income, Profession)
/// 5. Family background (Father's profession, Mother's profession, Financial status, Family location)
/// 6. Fixed bottom action bar: Shortlist heart button & Connect / Send connection button
class RaniMatchDetailsScreen extends StatefulWidget {
  final String profileId;
  final Map<String, dynamic>? initialProfileData;

  const RaniMatchDetailsScreen({
    super.key,
    required this.profileId,
    this.initialProfileData,
  });

  @override
  State<RaniMatchDetailsScreen> createState() => _RaniMatchDetailsScreenState();
}

class _RaniMatchDetailsScreenState extends State<RaniMatchDetailsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _data;
  int _activePhotoIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    if (widget.initialProfileData != null) {
      _data = Map<String, dynamic>.from(widget.initialProfileData!);
      _isLoading = false;
    }
    _fetchDetails();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetails() async {
    try {
      final res = await ApiService.instance.getProfileDetails(widget.profileId);
      if (mounted) {
        if (res['success'] == true && res['candidate'] != null) {
          setState(() {
            final fetched = Map<String, dynamic>.from(res['candidate']);
            // Merge existing data with freshly fetched profile
            if (_data != null) {
              _data!.addAll(fetched);
            } else {
              _data = fetched;
            }
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleShortlist() async {
    if (_data == null) return;
    final isCurrentlyShortlisted = _data!['is_shortlisted'] == true;
    final name = _data!['first_name'] ?? 'Candidate';

    setState(() {
      _data!['is_shortlisted'] = !isCurrentlyShortlisted;
    });

    try {
      final res = await ApiService.instance.toggleShortlist(widget.profileId);
      if (!mounted) return;

      if (res['success'] == true) {
        final isShortlisted = res['shortlisted'] == true;
        setState(() {
          _data!['is_shortlisted'] = isShortlisted;
        });
        RaniAlert.success(
          context,
          isShortlisted ? '$name added to your shortlist.' : 'Removed from shortlist.',
          title: isShortlisted ? 'Shortlisted' : 'Removed',
        );
      } else {
        setState(() {
          _data!['is_shortlisted'] = isCurrentlyShortlisted;
        });
        RaniAlert.error(context, res['message'] ?? 'Action failed.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _data!['is_shortlisted'] = isCurrentlyShortlisted;
        });
        RaniAlert.error(context, 'Error: $e');
      }
    }
  }

  Future<void> _sendRoyalInterest() async {
    if (_data == null) return;
    final name = _data!['first_name'] ?? 'Candidate';

    RaniMatrimonialLoader.show(context, message: 'Sending connection request to $name...');

    try {
      final res = await ApiService.instance.sendInterest(widget.profileId);
      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);

      if (res['success'] == true) {
        setState(() {
          _data!['request_type'] = 'sent';
          _data!['is_connected'] = true;
        });
        RaniAlert.success(
          context,
          res['message'] ?? 'Connection request sent to $name!',
          title: 'Connected',
        );
      } else {
        RaniAlert.error(context, res['message'] ?? 'Unable to send connection request.');
      }
    } catch (e) {
      if (mounted) {
        RaniMatrimonialLoader.hide(context);
        RaniAlert.error(context, 'Error: $e');
      }
    }
  }

  List<String> _extractPhotos() {
    final List<String> list = [];
    if (_data == null) return list;

    if (_data!['photos'] is List && (_data!['photos'] as List).isNotEmpty) {
      for (final p in _data!['photos']) {
        if (p is String && p.trim().isNotEmpty) {
          list.add(p);
        } else if (p is Map && p['photo_path'] != null) {
          list.add(p['photo_path'].toString());
        }
      }
    }

    final singlePhoto = _data!['photo'] ?? _data!['profile_picture'];
    if (singlePhoto is String && singlePhoto.isNotEmpty && !list.contains(singlePhoto)) {
      list.insert(0, singlePhoto);
    }

    return list;
  }

  void _openFullScreenViewer(List<String> photos, int initialIndex) {
    if (photos.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenPhotoViewer(
          photos: photos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _data == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAF7F2),
        body: SafeArea(child: RaniSkeletonProfile()),
      );
    }

    final d = _data ?? {};
    final photos = _extractPhotos();
    final firstName = d['first_name'] ?? 'Candidate';
    final lastName = d['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final profileCode = d['candidate_code'] ?? d['profile_id'] ?? (d['id'] != null ? 'RM${d['id'].toString().padLeft(5, '0')}' : widget.profileId);
    final age = d['age']?.toString() ?? '24';
    final height = d['height']?.toString() ?? "5' 4\"";
    final profession = d['profession'] ?? d['designation'] ?? 'Professional';
    final city = d['city']?.toString() ?? 'Kolkata';
    final state = d['state']?.toString() ?? 'West Bengal';
    final locationText = (city.isNotEmpty && state.isNotEmpty) ? '$city, $state' : (city.isNotEmpty ? city : state);
    final isVerified = d['verified'] == true || d['is_verified'] == 1 || (d['bluetick'] != null && d['bluetick']['is_accept'] == 1);
    final matchScore = int.tryParse(d['match_score']?.toString() ?? d['match_percentage']?.toString() ?? '95') ?? 95;
    final isShortlisted = d['is_shortlisted'] == true;
    final isConnected = d['request_type'] == 'sent' || d['request_type'] == 'accepted' || d['is_connected'] == true;

    // About Myself
    final aboutMyself = (d['about_yourself'] ?? d['about'] ?? d['bio'] ?? d['details']?['about_yourself'] ?? '').toString().trim();
    final displayBio = aboutMyself.isNotEmpty
        ? aboutMyself
        : 'I am a warm, values-driven individual with strong cultural and family values. Looking for a compatible and understanding partner to share life\'s beautiful journey.';

    // Personal details
    final gender = d['gender'] ?? 'Female';
    final maritalStatus = d['marital_status'] ?? d['marital'] ?? 'Never Married';
    final motherTongue = d['mother_tongue'] ?? 'Bengali';
    final religion = d['religion'] ?? 'Muslim';
    final community = d['community'] ?? d['caste'] ?? 'Sunni';
    final subCommunity = d['sub_community'] ?? d['sub_caste'] ?? d['sect'] ?? 'General';
    final gotra = d['gothra'] ?? d['gotra'] ?? d['details']?['gothra'] ?? 'Kashyap';
    final manglik = d['manglik'] ?? d['details']?['manglik'] ?? 'Non-Manglik';
    final diet = d['diet'] ?? 'Non-Vegetarian';
    final bloodGroup = d['blood_group'] ?? d['details']?['blood_group'] ?? 'O+';

    // Education & Career
    final highestQualification = d['highest_qualification'] ?? d['qualification'] ?? d['education'] ?? 'Post Graduate';
    final workingWith = d['working_with'] ?? d['details']?['working_with'] ?? d['employed_in'] ?? 'Private Company';
    final annualIncome = d['annual_income'] ?? d['income'] ?? '₹ 15 - 20 Lakh';

    // Family Background
    final fatherProfession = d['father_profession'] ?? d['father_occupation'] ?? d['details']?['father_profession'] ?? 'Business Owner';
    final motherProfession = d['mother_profession'] ?? d['mother_occupation'] ?? d['details']?['mother_profession'] ?? 'Homemaker';
    final financialStatus = d['family_financial_status'] ?? d['details']?['family_financial_status'] ?? 'Upper Middle Class';
    final familyLocation = d['family_location'] ?? d['details']?['family_location'] ?? locationText;

    // Match criteria breakdown
    final List<String> matchReasons = [];
    if (d['match_reasons'] is List && (d['match_reasons'] as List).isNotEmpty) {
      for (final r in d['match_reasons']) {
        matchReasons.add(r.toString());
      }
    }
    if (matchReasons.isEmpty) {
      if (religion.isNotEmpty) matchReasons.add('$religion Religion Match');
      if (community.isNotEmpty && community.toLowerCase() != 'all') matchReasons.add('$community Community Compatibility');
      if (city.isNotEmpty) matchReasons.add('$city Resident Preference');
      if (diet.isNotEmpty) matchReasons.add('$diet Diet Lifestyle');
      if (motherTongue.isNotEmpty) matchReasons.add('$motherTongue Mother Tongue');
      matchReasons.add('Educational Compatibility');
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 0. Profile Images Carousel with bottom pill dots & tap to view full-screen
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    // Carousel View
                    SizedBox(
                      height: 380,
                      width: double.infinity,
                      child: photos.isNotEmpty
                          ? PageView.builder(
                              controller: _pageController,
                              itemCount: photos.length,
                              onPageChanged: (idx) => setState(() => _activePhotoIndex = idx),
                              itemBuilder: (context, idx) {
                                return GestureDetector(
                                  onTap: () => _openFullScreenViewer(photos, idx),
                                  child: Image.network(
                                    photos[idx],
                                    fit: BoxFit.cover,
                                    alignment: Alignment.topCenter,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: const Color(0xFFDED5C9),
                                      child: const Center(
                                        child: Icon(CupertinoIcons.person_fill, size: 80, color: Colors.white70),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: const Color(0xFFDED5C9),
                              child: const Center(
                                child: Icon(CupertinoIcons.person_fill, size: 80, color: Colors.white70),
                              ),
                            ),
                    ),

                    // Top Gradient Shadow for app bar buttons
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 100,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.55),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Bottom subtle gradient overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 70,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              const Color(0xFF150002).withValues(alpha: 0.65),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Top Action Bar: Back button, Candidate ID pill, Tap to full-screen hint
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Back Button
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                              ),
                              child: const Icon(CupertinoIcons.back, color: Colors.white, size: 20),
                            ),
                          ),

                          // ID Capsule
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.50),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                            ),
                            child: Text(
                              'ID: $profileCode',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          // Full-screen zoom indicator
                          GestureDetector(
                            onTap: () => _openFullScreenViewer(photos, _activePhotoIndex),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                              ),
                              child: const Icon(CupertinoIcons.fullscreen, color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Carousel Pill Dots Indicator at the bottom
                    if (photos.length > 1)
                      Positioned(
                        bottom: 14,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            photos.length,
                            (idx) => AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: _activePhotoIndex == idx ? 22 : 7,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _activePhotoIndex == idx
                                    ? const Color(0xFFE5B842) // Brand Gold
                                    : Colors.white.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Content Details
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Candidate Main Header Card
                      _buildMainHeaderCard(
                        fullName: fullName,
                        age: age,
                        height: height,
                        profession: profession,
                        locationText: locationText,
                        isVerified: isVerified,
                        profileCode: profileCode,
                      ),

                      const SizedBox(height: 16),

                      // 2. Compatibility Match Score & What items matched
                      _buildMatchCompatibilitySection(
                        matchScore: matchScore,
                        matchReasons: matchReasons,
                      ),

                      const SizedBox(height: 16),

                      // 1. About Myself
                      _buildSectionCard(
                        icon: CupertinoIcons.sparkles,
                        title: 'About Myself',
                        child: Text(
                          displayBio,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            height: 1.55,
                            color: const Color(0xFF3A3A3A),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 3. Personal Details
                      _buildSectionCard(
                        icon: CupertinoIcons.person_crop_circle,
                        title: 'Personal Details',
                        child: Column(
                          children: [
                            _buildDetailRow('Gender', gender),
                            _buildDetailRow('Height', height),
                            _buildDetailRow('Marital Status', maritalStatus),
                            _buildDetailRow('Mother Tongue', motherTongue),
                            _buildDetailRow('Religion', religion),
                            _buildDetailRow('Community / Caste', community),
                            _buildDetailRow('Sub Community', subCommunity),
                            _buildDetailRow('Gotra', gotra),
                            _buildDetailRow('Manglik Status', manglik),
                            _buildDetailRow('Diet', diet),
                            _buildDetailRow('Blood Group', bloodGroup, isLast: true),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 4. Education & Career Details
                      _buildSectionCard(
                        icon: CupertinoIcons.briefcase,
                        title: 'Education & Career',
                        child: Column(
                          children: [
                            _buildDetailRow('Highest Qualification', highestQualification),
                            _buildDetailRow('Working With', workingWith),
                            _buildDetailRow('Profession / Role', profession),
                            _buildDetailRow('Annual Income', annualIncome, isLast: true),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 5. Family Background
                      _buildSectionCard(
                        icon: CupertinoIcons.person_3,
                        title: 'Family Background',
                        child: Column(
                          children: [
                            _buildDetailRow("Father's Profession", fatherProfession),
                            _buildDetailRow("Mother's Profession", motherProfession),
                            _buildDetailRow('Financial Status', financialStatus),
                            _buildDetailRow('Family Location', familyLocation, isLast: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 6. Fixed Bottom Action Buttons (Wishlist Heart & Send Connection)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomActionBar(
              isShortlisted: isShortlisted,
              isConnected: isConnected,
            ),
          ),
        ],
      ),
    );
  }

  /// Main Candidate Header Card
  Widget _buildMainHeaderCard({
    required String fullName,
    required String age,
    required String height,
    required String profession,
    required String locationText,
    required bool isVerified,
    required String profileCode,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8DFD5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF750000).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  '$fullName, $age',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E1E1E),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (isVerified) ...[
                const SizedBox(width: 8),
                const Icon(
                  CupertinoIcons.checkmark_seal_fill,
                  size: 20,
                  color: Color(0xFF2196F3), // Verified Blue Tick
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(CupertinoIcons.briefcase, size: 14, color: Color(0xFF750000)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$profession • $height',
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4A4A4A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(CupertinoIcons.location_solid, size: 14, color: Color(0xFF750000)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  locationText,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B6B6B),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 2. Compatibility Match Score & Matched Items
  Widget _buildMatchCompatibilitySection({
    required int matchScore,
    required List<String> matchReasons,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8DFD5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF750000).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF750000).withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.heart_circle_fill,
                        color: Color(0xFF750000),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Compatibility',
                        style: GoogleFonts.outfit(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E1E1E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Percentage Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE5B842), Color(0xFFD4AF37)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE5B842).withValues(alpha: 0.3),
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
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF4A0000),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Compatibility Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (matchScore / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFEFE8DE),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF750000)),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            'What matches with your partner preferences:',
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6E6E6E),
            ),
          ),

          const SizedBox(height: 8),

          // Matched item pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: matchReasons.map((reason) {
              final screenWidth = MediaQuery.of(context).size.width;
              final maxChipWidth = screenWidth > 64 ? screenWidth - 64 : 260.0;
              return Container(
                constraints: BoxConstraints(maxWidth: maxChipWidth),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F6F0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE8DFD5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.checkmark_alt, size: 13, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        reason,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2B2B2B),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Reusable Card Container for Sections
  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8DFD5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF750000).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF750000).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF750000), size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1E1E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  /// Reusable Key-Value Detail Row
  Widget _buildDetailRow(String label, dynamic value, {bool isLast = false}) {
    final textValue = value?.toString() ?? 'Not Specified';
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF7A7A7A),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              textValue.isNotEmpty ? textValue : 'Not Specified',
              style: GoogleFonts.outfit(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF222222),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 6. Fixed Bottom Action Bar: Heart Wishlist & Send Connection
  Widget _buildBottomActionBar({
    required bool isShortlisted,
    required bool isConnected,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom + 6 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFEFE8DE), width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Wishlist Heart Button
          GestureDetector(
            onTap: _toggleShortlist,
            child: Container(
              width: 50,
              height: 48,
              decoration: BoxDecoration(
                color: isShortlisted ? const Color(0xFFFFF0F2) : const Color(0xFFF7F5F0),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isShortlisted ? const Color(0xFFFFCDD2) : const Color(0xFFE8DFD5),
                ),
              ),
              child: Icon(
                isShortlisted ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                color: isShortlisted ? const Color(0xFFE53935) : const Color(0xFF4A4A4A),
                size: 22,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Send Connection Button
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isConnected ? const Color(0xFF2E7D32) : const Color(0xFF750000), // Royal burgundy
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: isConnected ? null : _sendRoyalInterest,
                icon: Icon(
                  isConnected ? CupertinoIcons.checkmark_alt : CupertinoIcons.heart,
                  size: 18,
                ),
                label: Text(
                  isConnected ? 'Connection Sent' : 'Connect Now',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 0. Full-Screen Interactive Photo Viewer with Pinch-Zoom
class FullScreenPhotoViewer extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;

  const FullScreenPhotoViewer({
    super.key,
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<FullScreenPhotoViewer> createState() => _FullScreenPhotoViewerState();
}

class _FullScreenPhotoViewerState extends State<FullScreenPhotoViewer> {
  late int _currentIndex;
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Interactive PageView
          PageView.builder(
            controller: _controller,
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, i) {
              return InteractiveViewer(
                minScale: 0.8,
                maxScale: 3.5,
                child: Center(
                  child: Image.network(
                    widget.photos[i],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      CupertinoIcons.photo,
                      size: 80,
                      color: Colors.white38,
                    ),
                  ),
                ),
              );
            },
          ),

          // Top Bar with Close button and Page Counter
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Close button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(CupertinoIcons.xmark, color: Colors.white, size: 20),
                  ),
                ),

                // Counter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.photos.length}',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
