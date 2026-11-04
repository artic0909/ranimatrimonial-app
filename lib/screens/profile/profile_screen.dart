import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../components/rani_alert.dart';
import '../../components/rani_image_cropper_modal.dart';
import '../../components/rani_matrimonial_loader.dart';
import '../../components/rani_skeleton_loader.dart';
import '../wallet/wallet_screen.dart';
import '../home/photos.dart';
import '../home/profile_edit.dart';
import '../auth/aadhaar_verification_screen.dart';
import 'edit_section_modal.dart';

/// Screen: Candidate Profile & Account Dashboard
/// Features Windows Card Design, All Profile Information & Live Wallet Balance
class RaniProfileScreen extends StatefulWidget {
  final bool showAppBar;

  const RaniProfileScreen({
    super.key,
    this.showAppBar = true,
  });

  @override
  State<RaniProfileScreen> createState() => _RaniProfileScreenState();
}

class _RaniProfileScreenState extends State<RaniProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _candidate;
  Map<String, dynamic>? _wallet;
  Map<String, dynamic>? _bluetick;

  @override
  void initState() {
    super.initState();
    // Pre-populate with cached candidate data so screen displays fast
    _candidate = ApiService.instance.candidate;
    ApiService.instance.candidateNotifier.addListener(_onProfileCandidateChanged);
    ApiService.instance.walletBalanceNotifier.addListener(_onProfileWalletChanged);
    _loadProfileData();
  }

  void _onProfileCandidateChanged() {
    if (mounted) {
      setState(() {
        _candidate = ApiService.instance.candidate;
      });
    }
  }

  void _onProfileWalletChanged() {
    if (mounted && ApiService.instance.walletBalanceNotifier.value > 0) {
      setState(() {
        _wallet = {
          ...?_wallet,
          'avl_balance': ApiService.instance.walletBalanceNotifier.value,
        };
      });
    }
  }

  @override
  void dispose() {
    ApiService.instance.candidateNotifier.removeListener(_onProfileCandidateChanged);
    ApiService.instance.walletBalanceNotifier.removeListener(_onProfileWalletChanged);
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.instance.getMyProfile();
      final walletRes = await ApiService.instance.getWallet();

      if (mounted) {
        if (res['success'] == true && res['candidate'] != null) {
          setState(() {
            _candidate = res['candidate'] as Map<String, dynamic>;
            _bluetick = res['bluetick'] as Map<String, dynamic>?;
            if (walletRes['success'] == true && walletRes['wallet'] != null) {
              _wallet = walletRes['wallet'] as Map<String, dynamic>;
            }
            _isLoading = false;
          });
        } else {
          setState(() {
            if (walletRes['success'] == true && walletRes['wallet'] != null) {
              _wallet = walletRes['wallet'] as Map<String, dynamic>;
            }
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('[RaniProfileScreen] Load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatPhotoUrl(dynamic raw) {
    return ApiService.formatImageUrl(raw);
  }

  Future<void> _changeProfilePhoto() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Update Profile Photo',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadPhoto(ImageSource.camera);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.camera_fill, color: Color(0xFF750000), size: 22),
                      const SizedBox(width: 14),
                      Text('Take a Photo with Camera', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadPhoto(ImageSource.gallery);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.photo_fill, color: Color(0xFF750000), size: 22),
                      const SizedBox(width: 14),
                      Text('Choose from Gallery', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 92,
      );
      if (picked == null || !mounted) return;

      final rawFile = File(picked.path);

      // Open interactive cropping modal
      final croppedFile = await RaniImageCropperModal.show(
        context,
        imageFile: rawFile,
        title: 'Adjust Profile Photo',
        isCircle: true,
      );

      if (croppedFile == null || !mounted) return;

      RaniMatrimonialLoader.show(context, message: 'Updating Profile Photo...');
      final res = await ApiService.instance.uploadProfilePicture(croppedFile);
      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);

      if (res['success'] == true) {
        RaniAlert.success(context, 'Profile picture updated successfully!');
        _loadProfileData();
      } else {
        RaniAlert.error(context, res['message'] ?? 'Unable to update photo.');
      }
    } catch (e) {
      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);
      RaniAlert.error(context, 'Upload error: $e');
    }
  }

  void _openEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RaniProfileEditScreen(initialCandidate: _candidate),
      ),
    ).then((val) {
      if (val == true || mounted) {
        _loadProfileData();
      }
    });
  }

  Future<void> _openSectionEdit(ProfileSection section) async {
    if (_candidate == null) return;

    await RaniSectionEditModal.show(
      context: context,
      section: section,
      candidate: _candidate!,
      onSave: (sectionKey, data) async {
        try {
          final res = await ApiService.instance.updateProfile(sectionKey, data);
          if (!mounted) return false;

          if (res['success'] == true) {
            setState(() {
              if (res['candidate'] != null && res['candidate'] is Map<String, dynamic>) {
                _candidate = res['candidate'] as Map<String, dynamic>;
              } else {
                _candidate = {...?_candidate, ...data};
              }
            });
            RaniAlert.success(context, 'Section updated successfully!');
            _loadProfileData();
            return true;
          } else {
            RaniAlert.error(context, res['message'] ?? 'Failed to update section.');
            return false;
          }
        } catch (e) {
          if (mounted) {
            RaniAlert.error(context, 'Error updating section: $e');
          }
          return false;
        }
      },
    );
  }

  int _calculateCompleteness(Map<String, dynamic> c) {
    return ApiService.calculateProfileCompleteness(c);
  }

  @override
  Widget build(BuildContext context) {
    // Show window skeleton loader on initial loading when no cached data exists
    if (_isLoading && _candidate == null) {
      if (!widget.showAppBar) {
        return const Material(
          color: Color(0xFFFAF7F2),
          child: SafeArea(
            child: RaniSkeletonProfileWindows(),
          ),
        );
      }
      return Scaffold(
        backgroundColor: const Color(0xFFFAF7F2),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(CupertinoIcons.back, color: Color(0xFF750000)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'My Profile',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E1E1E),
            ),
          ),
        ),
        body: const SafeArea(
          child: RaniSkeletonProfileWindows(),
        ),
      );
    }

    final c = _candidate ?? {};
    final name = (c['full_name'] != null && c['full_name'].toString().trim().isNotEmpty)
        ? c['full_name'].toString()
        : '${c['first_name'] ?? 'Candidate'} ${c['last_name'] ?? ''}'.trim();
    final profileCode = c['candidate_code'] ?? c['profile_id'] ?? 'RM-PROFILE';
    final rawPhoto = c['profile_picture_url'] ?? c['profile_picture'] ?? c['photo'];
    final photoUrl = _formatPhotoUrl(rawPhoto);

    final rawBal = _wallet?['avl_balance'];
    final double balance = (rawBal is num)
        ? rawBal.toDouble()
        : double.tryParse(rawBal?.toString().replaceAll(RegExp(r'[^0-9.-]'), '') ?? '') ?? 0.0;

    final isBlueTickVerified = c['is_bluetick_verified'] == true ||
        (_bluetick != null && _bluetick!['is_accept'] == 1);
    final completeness = _calculateCompleteness(c);

    final content = RefreshIndicator(
      color: const Color(0xFF750000),
      onRefresh: _loadProfileData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          children: [
            // 1. Profile Hero Window Card
            _buildHeroProfileCard(
              name: name,
              profileCode: profileCode,
              photoUrl: photoUrl,
              completeness: completeness,
              isVerified: isBlueTickVerified,
              profileFor: c['profile_for']?.toString() ?? 'Self',
            ),

            const SizedBox(height: 14),

            // 2. Royal Wallet Balance Card (Prominently featured per user request)
            _buildWalletBalanceCard(balance),

            const SizedBox(height: 14),

            // 3. Verification & Trust Banner
            _buildBlueTickVerificationBanner(isBlueTickVerified),

            const SizedBox(height: 14),

            // 4. Window Card: Personality & About Me
            _buildAboutWindowCard(c['about_yourself']?.toString(), c['hobbies_interests']),

            const SizedBox(height: 14),

            // 5. Window Card: Basics & Lifestyle
            _buildBasicsLifestyleCard(c),

            const SizedBox(height: 14),

            // 6. Window Card: Religious & Cultural Background
            _buildReligiousCard(c),

            const SizedBox(height: 14),

            // 7. Window Card: Astro & Kundli Details
            _buildAstroCard(c),

            const SizedBox(height: 14),

            // 8. Window Card: Education & Career
            _buildEducationCareerCard(c),

            const SizedBox(height: 14),

            // 9. Window Card: Location Details
            _buildLocationCard(c),

            const SizedBox(height: 14),

            // 10. Window Card: Family Details
            _buildFamilyCard(c),

            const SizedBox(height: 14),

            // 11. Window Card: Contact Information
            _buildContactCard(c),

            const SizedBox(height: 14),

            // 12. Quick Services & Settings Links
            _buildQuickServicesCard(),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (!widget.showAppBar) {
      return Material(
        color: const Color(0xFFFAF7F2),
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: Text(
          'My Profile',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1E1E),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.square_pencil, color: Color(0xFF750000)),
            tooltip: 'Edit Profile',
            onPressed: _openEditProfile,
          ),
        ],
      ),
      body: content,
    );
  }

  /// 1. Profile Hero Window Card with Photo, Badges & Profile Completeness
  Widget _buildHeroProfileCard({
    required String name,
    required String profileCode,
    required String photoUrl,
    required int completeness,
    required bool isVerified,
    required String profileFor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFE8DE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Circular Avatar with Gold Gradient Frame & Camera Button
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(3.5),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFE5B842), Color(0xFF9E721D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: ClipOval(
                  child: Container(
                    width: 92,
                    height: 92,
                    color: const Color(0xFFFAF7F2),
                    child: photoUrl.isNotEmpty
                        ? Image.network(
                            photoUrl,
                            width: 92,
                            height: 92,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Icon(CupertinoIcons.person_fill, size: 48, color: Color(0xFF750000)),
                            ),
                          )
                        : const Center(
                            child: Icon(CupertinoIcons.person_fill, size: 48, color: Color(0xFF750000)),
                          ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _changeProfilePhoto,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF750000),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(CupertinoIcons.camera_fill, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Candidate Name & Verification Tick
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1E1E),
                  ),
                ),
              ),
              if (isVerified) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified, size: 20, color: Color(0xFF2E7D32)),
              ],
            ],
          ),

          const SizedBox(height: 6),

          // Profile ID & Profile For Pills
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF750000).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ID: $profileCode',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF750000),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFE8DE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Profile for $profileFor',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5A4E46),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFEFE8DE)),
          const SizedBox(height: 14),

          // Profile Completeness Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Profile Completeness',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6E6E6E),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$completeness%',
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF750000),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: completeness / 100,
              minHeight: 8,
              backgroundColor: const Color(0xFFEFE8DE),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF750000)),
            ),
          ),
          const SizedBox(height: 12),

          // Edit Profile Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF750000),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                elevation: 0,
              ),
              onPressed: _openEditProfile,
              icon: const Icon(CupertinoIcons.pencil, size: 15),
              label: Text(
                'Edit Full Profile',
                style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Royal Wallet Balance Card (Keep wallet balance prominently displayed per user request)
  Widget _buildWalletBalanceCard(double balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5B842), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE5B842).withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE5B842), Color(0xFF9E721D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Royal Wallet Balance',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6E6E6E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹ ${balance.toStringAsFixed(2)}',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E1E1E),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF750000),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RaniWalletScreen()),
              ).then((_) => _loadProfileData());
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, size: 15),
                const SizedBox(width: 4),
                Text(
                  'Top Up',
                  style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Blue Tick Aadhaar Verification Banner
  Widget _buildBlueTickVerificationBanner(bool isVerified) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isVerified
            ? const Color(0xFF2E7D32).withValues(alpha: 0.06)
            : const Color(0xFF750000).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isVerified ? const Color(0xFF2E7D32).withValues(alpha: 0.3) : const Color(0xFFE5B842),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isVerified ? Icons.verified_rounded : Icons.verified_user_outlined,
            color: isVerified ? const Color(0xFF2E7D32) : const Color(0xFF750000),
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isVerified ? 'Blue Tick Government Verified' : 'Aadhaar Blue Tick Verification',
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isVerified ? const Color(0xFF2E7D32) : const Color(0xFF750000),
                  ),
                ),
                Text(
                  isVerified
                      ? 'Your profile is 100% verified with government Aadhaar.'
                      : 'Gain 5x more trust and royal visibility by verifying your Aadhaar.',
                  style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF6E6E6E)),
                ),
              ],
            ),
          ),
          if (!isVerified)
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RaniAadhaarVerificationScreen()),
                ).then((_) => _loadProfileData());
              },
              child: Text(
                'Verify',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF750000),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 4. Personality & About Window Card
  Widget _buildAboutWindowCard(String? about, dynamic rawHobbies) {
    List<String> hobbiesList = [];
    if (rawHobbies is List) {
      hobbiesList = rawHobbies.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    } else if (rawHobbies is String && rawHobbies.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawHobbies);
        if (decoded is List) {
          hobbiesList = decoded.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
        } else {
          hobbiesList = rawHobbies.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        }
      } catch (_) {
        hobbiesList = rawHobbies.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
    }

    return _buildSectionWindow(
      title: 'Personality & About',
      icon: CupertinoIcons.person_crop_circle,
      onEdit: () => _openSectionEdit(ProfileSection.about),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            about != null && about.trim().isNotEmpty
                ? about
                : 'No description provided yet. Tap "Edit" to tell potential matches about your values, passions, and life goals.',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: const Color(0xFF4A4A4A),
              height: 1.45,
            ),
          ),
          if (hobbiesList.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Hobbies & Interests',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF750000),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: hobbiesList.map((hobby) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEFE8DE)),
                  ),
                  child: Text(
                    hobby,
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E1E1E),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// 5. Basics & Lifestyle Window Card
  Widget _buildBasicsLifestyleCard(Map<String, dynamic> c) {
    return _buildSectionWindow(
      title: 'Basics & Lifestyle',
      icon: CupertinoIcons.heart_circle,
      onEdit: () => _openSectionEdit(ProfileSection.basics),
      child: Column(
        children: [
          _buildInfoRowPair(
            label1: 'Age / DOB',
            val1: c['age'] != null ? '${c['age']} yrs (${c['dob'] ?? ''})' : c['dob'] ?? '-',
            label2: 'Height',
            val2: c['height'] ?? '-',
          ),
          _buildInfoRowPair(
            label1: 'Marital Status',
            val1: c['marital_status'] ?? '-',
            label2: 'Diet',
            val2: c['diet'] ?? '-',
          ),
          _buildInfoRowPair(
            label1: 'Blood Group',
            val1: c['blood_group'] ?? '-',
            label2: 'Health Info',
            val2: c['health_info'] ?? 'Normal',
          ),
          _buildInfoRowPair(
            label1: 'Grew Up In',
            val1: c['grew_up_in'] ?? '-',
            label2: 'Disability',
            val2: c['disability'] ?? 'None',
          ),
        ],
      ),
    );
  }

  /// 6. Religious & Cultural Background Window Card
  Widget _buildReligiousCard(Map<String, dynamic> c) {
    return _buildSectionWindow(
      title: 'Religious Background',
      icon: CupertinoIcons.book_circle,
      onEdit: () => _openSectionEdit(ProfileSection.religious),
      child: Column(
        children: [
          _buildInfoRowPair(
            label1: 'Religion',
            val1: c['religion'] ?? '-',
            label2: 'Community (Caste)',
            val2: c['community'] ?? '-',
          ),
          _buildInfoRowPair(
            label1: 'Sub-Community',
            val1: c['sub_community'] ?? '-',
            label2: 'Mother Tongue',
            val2: c['mother_tongue'] ?? '-',
          ),
          _buildInfoRowPair(
            label1: 'Gothra',
            val1: c['gothra'] ?? '-',
            label2: 'Living In',
            val2: c['living_in'] ?? c['city'] ?? '-',
          ),
        ],
      ),
    );
  }

  /// 7. Astro & Kundli Details Window Card
  Widget _buildAstroCard(Map<String, dynamic> c) {
    return _buildSectionWindow(
      title: 'Astro Details',
      icon: CupertinoIcons.sparkles,
      onEdit: () => _openSectionEdit(ProfileSection.astro),
      child: Column(
        children: [
          _buildInfoRowPair(
            label1: 'Manglik Status',
            val1: c['manglik'] ?? '-',
            label2: 'Time of Birth',
            val2: c['time_of_birth'] ?? '-',
          ),
          _buildInfoRowPair(
            label1: 'City of Birth',
            val1: c['city_of_birth'] ?? '-',
            label2: 'Gothra',
            val2: c['gothra'] ?? '-',
          ),
        ],
      ),
    );
  }

  /// 8. Education & Career Window Card
  Widget _buildEducationCareerCard(Map<String, dynamic> c) {
    return _buildSectionWindow(
      title: 'Education & Career',
      icon: CupertinoIcons.briefcase,
      onEdit: () => _openSectionEdit(ProfileSection.educationCareer),
      child: Column(
        children: [
          _buildInfoRowPair(
            label1: 'Highest Qualification',
            val1: c['highest_qualification'] ?? '-',
            label2: 'College / University',
            val2: c['college_name'] ?? '-',
          ),
          _buildInfoRowPair(
            label1: 'Working With',
            val1: c['working_with'] ?? '-',
            label2: 'Profession',
            val2: c['profession'] ?? '-',
          ),
          _buildInfoRowPair(
            label1: 'Designation',
            val1: c['designation'] ?? '-',
            label2: 'Company Name',
            val2: c['company_name'] ?? '-',
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildInfoItem('Annual Income', c['annual_income'] ?? '-')),
              const SizedBox(width: 14),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ],
      ),
    );
  }

  /// 9. Location Details Window Card
  Widget _buildLocationCard(Map<String, dynamic> c) {
    return _buildSectionWindow(
      title: 'Location Details',
      icon: CupertinoIcons.location_circle,
      onEdit: () => _openSectionEdit(ProfileSection.location),
      child: Column(
        children: [
          _buildInfoRowPair(
            label1: 'Country',
            val1: c['country'] ?? 'India',
            label2: 'State',
            val2: c['state'] ?? '-',
          ),
          _buildInfoRowPair(
            label1: 'City',
            val1: c['city'] ?? '-',
            label2: 'Residency Status',
            val2: c['residency_status'] ?? 'Citizen',
          ),
          _buildInfoRowPair(
            label1: 'Pincode / Zip Code',
            val1: c['pincode'] ?? c['zip_code'] ?? '-',
            label2: 'Police Station',
            val2: c['police_st'] ?? '-',
          ),
        ],
      ),
    );
  }

  /// 10. Family Details Window Card
  Widget _buildFamilyCard(Map<String, dynamic> c) {
    return _buildSectionWindow(
      title: 'Family Details',
      icon: CupertinoIcons.person_3_fill,
      onEdit: () => _openSectionEdit(ProfileSection.family),
      child: Column(
        children: [
          _buildInfoRowPair(
            label1: "Father's Profession",
            val1: c['father_profession'] ?? '-',
            label2: "Mother's Profession",
            val2: c['mother_profession'] ?? '-',
          ),
          _buildInfoRowPair(
            label1: 'Brothers Count',
            val1: c['brothers_count']?.toString() ?? '0',
            label2: 'Sisters Count',
            val2: c['sisters_count']?.toString() ?? '0',
          ),
          _buildInfoRowPair(
            label1: 'Family Location',
            val1: c['family_location'] ?? '-',
            label2: 'Financial Status',
            val2: c['family_financial_status'] ?? 'Middle Class',
          ),
        ],
      ),
    );
  }

  /// 11. Contact Information Window Card
  Widget _buildContactCard(Map<String, dynamic> c) {
    return _buildSectionWindow(
      title: 'Contact Details',
      icon: CupertinoIcons.phone_circle,
      onEdit: () => _openSectionEdit(ProfileSection.contact),
      child: Column(
        children: [
          _buildInfoRowPair(
            label1: 'Mobile Number',
            val1: c['mobile'] ?? '-',
            label2: 'Email Address',
            val2: c['email'] ?? '-',
          ),
          if (c['full_address'] != null && c['full_address'].toString().trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Full Address',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8E8E93),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        c['full_address'].toString(),
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E1E1E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 12. Quick Navigation & Services
  Widget _buildQuickServicesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEFE8DE)),
      ),
      child: _buildQuickTile(
        icon: CupertinoIcons.photo_on_rectangle,
        title: 'Manage Photo Gallery',
        subtitle: 'Add, reorder or adjust privacy of your photos',
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RaniPhotosScreen()),
          ).then((_) => _loadProfileData());
        },
      ),
    );
  }

  Widget _buildQuickTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    BorderRadius? borderRadius,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFF750000).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF750000), size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E1E1E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        color: const Color(0xFF6E6E6E),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(CupertinoIcons.chevron_forward, size: 16, color: Color(0xFF8E8E93)),
            ],
          ),
        ),
      ),
    );
  }

  /// Reusable Section Window Container with Header & Edit Action
  Widget _buildSectionWindow({
    required String title,
    required IconData icon,
    VoidCallback? onEdit,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEFE8DE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(icon, size: 18, color: const Color(0xFF750000)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E1E1E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF750000).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(CupertinoIcons.pencil, size: 12, color: Color(0xFF750000)),
                        const SizedBox(width: 4),
                        Text(
                          'Edit',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF750000),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  /// Reusable 2-Column Key-Value Row Pair
  Widget _buildInfoRowPair({
    required String label1,
    required dynamic val1,
    required String label2,
    required dynamic val2,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildInfoItem(label1, val1)),
          const SizedBox(width: 14),
          Expanded(child: _buildInfoItem(label2, val2)),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, dynamic value) {
    final strVal = (value != null && value.toString().trim().isNotEmpty)
        ? value.toString().trim()
        : '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF8E8E93),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          strVal,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E1E1E),
          ),
        ),
      ],
    );
  }
}
