import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../components/rani_alert.dart';
import '../components/rani_matrimonial_loader.dart';
import '../components/rani_skeleton_loader.dart';

/// Screen: Candidate Profile Details (matching website profile_view.blade.php)
/// Displays:
/// - Photo Gallery Carousel
/// - Compatibility Score with breakdown reasons
/// - About Yourself
/// - Personal, Physical, Kundli / Astrological Information
/// - Career & Education
/// - Family Background
/// - Contact details (unlocked upon accepted WhatsApp chat)
/// - Sticky Bottom Royal Action Bar (Send Interest, Shortlist, Request Chat)
class RaniProfileDetailScreen extends StatefulWidget {
  final String profileId;
  final Map<String, dynamic>? initialProfileData;

  const RaniProfileDetailScreen({
    super.key,
    this.profileId = 'RM-SAMPLE',
    Map<String, dynamic>? initialProfileData,
    Map<String, dynamic>? profile,
  }) : initialProfileData = initialProfileData ?? profile;

  @override
  State<RaniProfileDetailScreen> createState() => _RaniProfileDetailScreenState();
}

class _RaniProfileDetailScreenState extends State<RaniProfileDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _data;
  String? _errorMessage;
  int _activePhotoIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    if (widget.initialProfileData != null) {
      _data = widget.initialProfileData;
      _isLoading = false;
    }
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final res = await ApiService.instance.getProfileDetails(widget.profileId);
      if (mounted) {
        if (res['success'] == true && res['candidate'] != null) {
          setState(() {
            _data = res['candidate'];
            _isLoading = false;
          });
        } else if (_data == null) {
          setState(() {
            _errorMessage = res['message'] ?? 'Unable to load candidate profile.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted && _data == null) {
        setState(() {
          _errorMessage = 'Network error: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendInterest() async {
    if (_data == null) return;
    final name = _data!['first_name'] ?? 'Candidate';
    RaniMatrimonialLoader.show(context, message: 'Sending Royal Interest to $name...');

    try {
      final res = await ApiService.instance.sendInterest(widget.profileId);
      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);

      if (res['success'] == true) {
        RaniAlert.success(
          context,
          res['message'] ?? 'Interest sent successfully!',
          title: 'Interest Sent',
        );
        setState(() {
          _data!['request_type'] = 'sent';
        });
      } else {
        RaniAlert.error(context, res['message'] ?? 'Unable to send interest.');
      }
    } catch (e) {
      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);
      RaniAlert.error(context, 'Error: $e');
    }
  }

  Future<void> _toggleShortlist() async {
    try {
      final res = await ApiService.instance.toggleShortlist(widget.profileId);
      if (!mounted) return;

      if (res['success'] == true) {
        final isShortlisted = res['shortlisted'] == true;
        RaniAlert.success(
          context,
          isShortlisted ? 'Profile added to your shortlist.' : 'Removed from shortlist.',
          title: isShortlisted ? 'Shortlisted' : 'Removed',
        );
        setState(() {
          _data!['is_shortlisted'] = isShortlisted;
        });
      }
    } catch (e) {
      if (mounted) RaniAlert.error(context, 'Error: $e');
    }
  }

  Future<void> _requestWhatsAppChat() async {
    final name = _data?['first_name'] ?? 'Candidate';
    RaniMatrimonialLoader.show(context, message: 'Requesting WhatsApp chat unlock with $name...');

    try {
      final res = await ApiService.instance.requestWhatsAppChat(widget.profileId);
      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);

      if (res['success'] == true) {
        RaniAlert.success(
          context,
          res['message'] ?? 'WhatsApp chat unlock request sent!',
          title: 'Chat Requested',
        );
        _fetchProfile();
      } else {
        RaniAlert.error(context, res['message'] ?? 'Unable to request chat.');
      }
    } catch (e) {
      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);
      RaniAlert.error(context, 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _data == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAF7F2),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFAF7F2),
          elevation: 0,
          leading: const BackButton(color: Color(0xFF750000)),
        ),
        body: const SafeArea(
          child: RaniSkeletonProfile(),
        ),
      );
    }

    if (_errorMessage != null && _data == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF140505),
        appBar: AppBar(backgroundColor: const Color(0xFF200707)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 54, color: Color(0xFFE57373)),
                const SizedBox(height: 12),
                Text(_errorMessage!, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _fetchProfile,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final d = _data!;
    final name = '${d['first_name'] ?? 'Candidate'} ${d['last_name'] ?? ''}'.trim();
    final profileCode = d['id']?.toString() ?? widget.profileId;
    final age = d['age'] ?? '26';
    final height = d['height'] ?? "5' 5\"";
    final profession = d['profession'] ?? d['designation'] ?? 'Professional';
    final city = d['city'] ?? 'City';
    final state = d['state'] ?? 'State';
    final isVerified = d['verified'] == true;
    final matchScore = d['match_score'] ?? 85;
    final matchReasons = (d['match_reasons'] as List<dynamic>?) ?? ['High Compatibility'];
    final isShortlisted = d['is_shortlisted'] == true;
    final requestType = d['request_type'] ?? 'none';
    final isAccepted = d['is_accepted'] == true || requestType == 'accepted';
    final isSent = requestType == 'sent';

    List<String> photos = [];
    if (d['photos'] != null && (d['photos'] as List).isNotEmpty) {
      photos = (d['photos'] as List).map((e) => e.toString()).toList();
    } else if (d['photo'] != null) {
      photos = [d['photo'].toString()];
    }

    return Scaffold(
      backgroundColor: const Color(0xFF140505),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 1. Photo Carousel Header with Silver App Bar
              SliverAppBar(
                expandedHeight: 380,
                pinned: true,
                backgroundColor: const Color(0xFF200707),
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Color(0xFFF3E5AB), size: 18),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isShortlisted ? Icons.favorite : Icons.favorite_border,
                        color: isShortlisted ? const Color(0xFFE53935) : const Color(0xFFF3E5AB),
                        size: 20,
                      ),
                    ),
                    onPressed: _toggleShortlist,
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: photos.isEmpty ? 1 : photos.length,
                        onPageChanged: (i) => setState(() => _activePhotoIndex = i),
                        itemBuilder: (context, i) {
                          if (photos.isEmpty) {
                            return Container(
                              color: const Color(0xFF381212),
                              child: const Icon(Icons.person, size: 80, color: Color(0xFFD4A034)),
                            );
                          }
                          return Image.network(
                            photos[i],
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: const Color(0xFF381212),
                              child: const Icon(Icons.person, size: 80, color: Color(0xFFD4A034)),
                            ),
                          );
                        },
                      ),

                      // Gradient Bottom Overlay
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.3),
                                Colors.transparent,
                                const Color(0xFF140505).withValues(alpha: 0.95),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // Carousel indicator dots
                      if (photos.length > 1)
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              photos.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: _activePhotoIndex == index ? 20 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _activePhotoIndex == index
                                      ? const Color(0xFFD4A034)
                                      : Colors.white.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 2. Profile Details Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card: Name, Verified Badge, Profile Code
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '$name, $age',
                                        style: GoogleFonts.playfairDisplay(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFFF3E5AB),
                                        ),
                                      ),
                                    ),
                                    if (isVerified) ...[
                                      const SizedBox(width: 8),
                                      const Icon(Icons.verified, size: 22, color: Color(0xFF4FC3F7)),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$profession • $city, $state',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    color: const Color(0xFFD5CCC4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A0B0B),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFD4A034).withValues(alpha: 0.6)),
                            ),
                            child: Text(
                              profileCode,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFF3E5AB),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Royal Compatibility Score Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2C0B0B), Color(0xFF1B0707)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFD4A034), width: 1.2),
                        ),
                        child: Row(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 58,
                                  height: 58,
                                  child: CircularProgressIndicator(
                                    value: matchScore / 100,
                                    backgroundColor: const Color(0xFF4A1919),
                                    valueColor: const AlwaysStoppedAnimation(Color(0xFFD4A034)),
                                    strokeWidth: 5,
                                  ),
                                ),
                                Text(
                                  '$matchScore%',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFFFDF73),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Astrological & Lifestyle Match',
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFF3E5AB),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    matchReasons.join(' • '),
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: const Color(0xFFD5CCC4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Section: About
                      _buildSectionCard(
                        title: 'About Yourself',
                        icon: Icons.person_outline,
                        child: Text(
                          d['about_yourself'] ?? 'I am a family-oriented individual looking for a caring, compatible life partner.',
                          style: GoogleFonts.outfit(fontSize: 14, height: 1.5, color: const Color(0xFFE5DDD5)),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Section: Basic & Religious Information
                      _buildSectionCard(
                        title: 'Personal & Religious Details',
                        icon: Icons.temple_hindu_outlined,
                        child: Column(
                          children: [
                            _buildDataRow('Gender', d['gender'] ?? 'Not Specified'),
                            _buildDataRow('Height', height),
                            _buildDataRow('Marital Status', d['marital_status'] ?? 'Never Married'),
                            _buildDataRow('Mother Tongue', d['mother_tongue'] ?? 'Bengali'),
                            _buildDataRow('Religion', d['religion'] ?? 'Hindu'),
                            _buildDataRow('Community / Caste', d['community'] ?? 'All Communities'),
                            _buildDataRow('Sub Community', d['sub_community'] ?? 'Not Disclosed'),
                            _buildDataRow('Gothra', d['gothra'] ?? 'Kashyap'),
                            _buildDataRow('Manglik', d['manglik'] ?? 'Non-Manglik'),
                            _buildDataRow('Diet', d['diet'] ?? 'Vegetarian'),
                            _buildDataRow('Blood Group', d['blood_group'] ?? 'O+'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Section: Education & Career
                      _buildSectionCard(
                        title: 'Education & Career',
                        icon: Icons.work_outline,
                        child: Column(
                          children: [
                            _buildDataRow('Highest Qualification', d['highest_qualification'] ?? 'Graduate'),
                            _buildDataRow('College / University', d['college_name'] ?? 'Reputed University'),
                            _buildDataRow('Working With', d['working_with'] ?? 'Private Sector'),
                            _buildDataRow('Profession', profession),
                            _buildDataRow('Company Name', d['company_name'] ?? 'Corporate Organization'),
                            _buildDataRow('Annual Income', d['annual_income'] ?? 'Not Disclosed'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Section: Family Background
                      _buildSectionCard(
                        title: 'Family Background',
                        icon: Icons.family_restroom_outlined,
                        child: Column(
                          children: [
                            _buildDataRow('Father Profession', d['father_profession'] ?? 'Businessman'),
                            _buildDataRow('Mother Profession', d['mother_profession'] ?? 'Homemaker'),
                            _buildDataRow('Family Financial Status', d['family_financial_status'] ?? 'Upper Middle Class'),
                            _buildDataRow('Brothers', d['brothers_count']?.toString() ?? '1'),
                            _buildDataRow('Sisters', d['sisters_count']?.toString() ?? '0'),
                            _buildDataRow('Family Location', d['family_location'] ?? '$city, $state'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Section: Contact & Verification Status
                      _buildSectionCard(
                        title: 'Contact Information',
                        icon: Icons.phone_outlined,
                        child: isAccepted
                            ? Column(
                                children: [
                                  _buildDataRow('Contact Number', d['mobile'] ?? '+91 98201 49842'),
                                  _buildDataRow('Email Address', d['email'] ?? 'candidate@ranimatrimonial.com'),
                                  _buildDataRow('Address', d['full_address'] ?? '$city, $state'),
                                ],
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E0A0A),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFD4A034).withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.lock_outline, color: Color(0xFFD4A034)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Contact details are locked for privacy. Send interest and connect on WhatsApp to unlock.',
                                        style: GoogleFonts.outfit(fontSize: 12.5, color: Colors.white70),
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
            ],
          ),

          // 3. Sticky Bottom Royal Action Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E0A0A),
                border: const Border(
                  top: BorderSide(color: Color(0xFFD4A034), width: 1.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Shortlist button
                  IconButton(
                    onPressed: _toggleShortlist,
                    icon: Icon(
                      isShortlisted ? Icons.favorite : Icons.favorite_border,
                      color: isShortlisted ? const Color(0xFFE53935) : const Color(0xFFF3E5AB),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Primary Button
                  Expanded(
                    child: isAccepted
                        ? ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: _requestWhatsAppChat,
                            icon: const Icon(Icons.chat),
                            label: Text(
                              'Open WhatsApp Chat',
                              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                          )
                        : isSent
                            ? ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4A1818),
                                  foregroundColor: const Color(0xFFD5CCC4),
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: null,
                                child: Text(
                                  'Interest Already Sent',
                                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                              )
                            : ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD4A034),
                                  foregroundColor: const Color(0xFF1E0A0A),
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 3,
                                ),
                                onPressed: _sendInterest,
                                icon: const Icon(Icons.favorite_rounded),
                                label: Text(
                                  'Send Connection Interest',
                                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700),
                                ),
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E0707),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4A1919), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFFD4A034)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFF3E5AB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF381212), height: 1),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: const Color(0xFFBCAAA4),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFF3E5AB),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
