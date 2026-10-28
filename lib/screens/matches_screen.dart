import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../components/rani_alert.dart';
import '../components/rani_matrimonial_loader.dart';
import '../components/rani_skeleton_loader.dart';
import 'profile_detail_screen.dart';

/// Screen: Matches Screen (matching website matches.blade.php)
/// Features:
/// - Sub-tabs: All Matches, New Matches, Shortlisted, Premium
/// - Match Cards with high-res photo, Royal Match Score badge, Blue Tick verification
/// - Action buttons: Send Interest, Toggle Shortlist, Request WhatsApp Chat, View Profile
class RaniMatchesScreen extends StatefulWidget {
  final String initialTab;

  const RaniMatchesScreen({
    super.key,
    this.initialTab = 'all',
  });

  @override
  State<RaniMatchesScreen> createState() => _RaniMatchesScreenState();
}

class _RaniMatchesScreenState extends State<RaniMatchesScreen> {
  late String _currentTab;
  bool _isLoading = true;
  List<dynamic> _matches = [];
  Map<String, dynamic> _counts = {};
  String? _errorMessage;

  final List<Map<String, String>> _tabs = const [
    {'id': 'all', 'label': 'All Matches'},
    {'id': 'new', 'label': 'New'},
    {'id': 'shortlisted', 'label': 'Shortlisted'},
    {'id': 'connected', 'label': 'Connected'},
  ];

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
    _fetchMatches();
  }

  Future<void> _fetchMatches() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiService.instance.getMatches(tab: _currentTab);
      if (mounted) {
        if (res['success'] == true) {
          setState(() {
            _matches = res['matches'] ?? [];
            _counts = res['counts'] ?? {};
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
          _errorMessage = 'Network connection error: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendInterest(String profileId, String name) async {
    RaniMatrimonialLoader.show(context, message: 'Sending Royal Interest to $name...');
    try {
      final res = await ApiService.instance.sendInterest(profileId);
      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);

      if (res['success'] == true) {
        RaniAlert.success(
          context,
          res['message'] ?? 'Connection interest sent successfully!',
          title: 'Interest Sent',
        );
        _fetchMatches();
      } else {
        RaniAlert.error(
          context,
          res['message'] ?? 'Unable to send interest.',
          title: 'Action Failed',
        );
      }
    } catch (e) {
      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);
      RaniAlert.error(context, 'Error: $e', title: 'Error');
    }
  }

  Future<void> _toggleShortlist(String profileId, String name) async {
    try {
      final res = await ApiService.instance.toggleShortlist(profileId);
      if (!mounted) return;

      if (res['success'] == true) {
        final isShortlisted = res['shortlisted'] == true;
        RaniAlert.success(
          context,
          isShortlisted ? '$name added to Shortlist!' : '$name removed from Shortlist.',
          title: isShortlisted ? 'Shortlisted' : 'Removed',
        );
        _fetchMatches();
      } else {
        RaniAlert.error(context, res['message'] ?? 'Shortlist action failed.');
      }
    } catch (e) {
      if (mounted) {
        RaniAlert.error(context, 'Error: $e');
      }
    }
  }

  Future<void> _requestWhatsAppChat(String profileId, String name) async {
    RaniMatrimonialLoader.show(context, message: 'Requesting WhatsApp chat unlock...');
    try {
      final res = await ApiService.instance.requestWhatsAppChat(profileId);
      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);

      if (res['success'] == true) {
        RaniAlert.success(
          context,
          res['message'] ?? 'WhatsApp chat request sent to $name!',
          title: 'Chat Requested',
        );
        _fetchMatches();
      } else {
        RaniAlert.error(
          context,
          res['message'] ?? 'Unable to request WhatsApp chat.',
          title: 'Chat Request Failed',
        );
      }
    } catch (e) {
      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);
      RaniAlert.error(context, 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF140505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF200707),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Royal Matches',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFF3E5AB),
            letterSpacing: 0.5,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: _buildSubTabs(),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFFD4A034),
        backgroundColor: const Color(0xFF26121B),
        onRefresh: _fetchMatches,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildSubTabs() {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 6, left: 12, right: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tab = _tabs[index];
          final isSelected = _currentTab == tab['id'];
          final countKey = tab['id'];
          final count = _counts[countKey] ?? 0;

          return GestureDetector(
            onTap: () {
              if (_currentTab != tab['id']) {
                setState(() {
                  _currentTab = tab['id']!;
                });
                _fetchMatches();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFD4A034)
                    : const Color(0xFF260D0D),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFFDF73)
                      : const Color(0xFF5A2525),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tab['label']!,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? const Color(0xFF1E0A0A) : const Color(0xFFD5CCC4),
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF1E0A0A) : const Color(0xFF8B0000),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? const Color(0xFFF3E5AB) : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const SingleChildScrollView(
        child: RaniSkeletonGrid(itemCount: 6),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 54, color: Color(0xFFE57373)),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4A034),
                  foregroundColor: const Color(0xFF1E0A0A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: _fetchMatches,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
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
              const Icon(Icons.favorite_border_rounded, size: 64, color: Color(0xFFD4A034)),
              const SizedBox(height: 16),
              Text(
                'No Matches in this Category',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFF3E5AB),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Explore our Search tab or update your partner preferences to see more prospective brides and grooms.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 13, color: Colors.white60),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _matches.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final candidate = _matches[index];
        return _buildMatchCard(candidate);
      },
    );
  }

  Widget _buildMatchCard(dynamic candidate) {
    final profileId = candidate['id']?.toString() ?? '';
    final name = '${candidate['first_name'] ?? 'Candidate'} ${candidate['last_name'] ?? ''}'.trim();
    final age = candidate['age'] ?? '26';
    final height = candidate['height'] ?? "5' 5\"";
    final profession = candidate['profession'] ?? candidate['designation'] ?? 'Professional';
    final city = candidate['city'] ?? 'India';
    final state = candidate['state'] ?? '';
    final religion = candidate['religion'] ?? 'Hindu';
    final community = candidate['community'] ?? 'Community';
    final highestQualification = candidate['highest_qualification'] ?? 'Graduate';
    final photo = candidate['photo'] ?? '';
    final isVerified = candidate['verified'] == true;
    final matchScore = candidate['match_score'] ?? 85;
    final isShortlisted = candidate['is_shortlisted'] == true;
    final requestType = candidate['request_type'] ?? 'none';
    final isAccepted = candidate['is_accepted'] == true || requestType == 'accepted';
    final isSent = requestType == 'sent';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF220808),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFD4A034).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo & Overlay Badges
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                child: AspectRatio(
                  aspectRatio: 16 / 11,
                  child: Image.network(
                    photo,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFF381212),
                      child: const Center(
                        child: Icon(Icons.person, size: 64, color: Color(0xFFD4A034)),
                      ),
                    ),
                  ),
                ),
              ),

              // Gradient Shade at Bottom of Photo
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.2),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.75),
                      ],
                    ),
                  ),
                ),
              ),

              // Match Score Pill (Top Left)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E0A0A).withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD4A034), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars_rounded, size: 15, color: Color(0xFFFFDF73)),
                      const SizedBox(width: 4),
                      Text(
                        '$matchScore% Match',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFF3E5AB),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Shortlist Heart Button (Top Right)
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () => _toggleShortlist(profileId, name),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E0A0A).withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isShortlisted ? const Color(0xFFE53935) : const Color(0xFFD4A034),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      isShortlisted ? Icons.favorite : Icons.favorite_border,
                      size: 19,
                      color: isShortlisted ? const Color(0xFFE53935) : const Color(0xFFF3E5AB),
                    ),
                  ),
                ),
              ),

              // Name, Age & Verified badge over bottom of image
              Positioned(
                bottom: 12,
                left: 14,
                right: 14,
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              '$name, $age',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified, size: 18, color: Color(0xFF4FC3F7)),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E0C0C).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFD4A034).withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        profileId,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFF3E5AB),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Details Information Section
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick info pills
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildInfoBadge(Icons.height, height),
                    _buildInfoBadge(Icons.temple_hindu_outlined, '$religion • $community'),
                    _buildInfoBadge(Icons.work_outline, profession),
                    _buildInfoBadge(Icons.school_outlined, highestQualification),
                    _buildInfoBadge(Icons.location_on_outlined, state.isNotEmpty ? '$city, $state' : city),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(color: Color(0xFF421616), height: 1),
                const SizedBox(height: 12),

                // Bottom Action Buttons
                Row(
                  children: [
                    // View Profile Button
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFF3E5AB),
                          side: const BorderSide(color: Color(0xFFD4A034), width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RaniProfileDetailScreen(
                                profileId: profileId,
                                initialProfileData: candidate,
                              ),
                            ),
                          ).then((_) => _fetchMatches());
                        },
                        child: Text(
                          'View Profile',
                          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Primary Connection Action Button
                    Expanded(
                      flex: 3,
                      child: _buildActionButton(candidate, profileId, name, isAccepted, isSent),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    dynamic candidate,
    String profileId,
    String name,
    bool isAccepted,
    bool isSent,
  ) {
    if (isAccepted) {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF25D366),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 11),
        ),
        onPressed: () => _requestWhatsAppChat(profileId, name),
        icon: const Icon(Icons.chat, size: 16),
        label: Text(
          'WhatsApp Chat',
          style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w700),
        ),
      );
    }

    if (isSent) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4A1818),
          foregroundColor: const Color(0xFFD5CCC4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 11),
        ),
        onPressed: null,
        child: Text(
          'Interest Sent',
          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      );
    }

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFD4A034),
        foregroundColor: const Color(0xFF1E0A0A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 11),
        elevation: 2,
      ),
      onPressed: () => _sendInterest(profileId, name),
      icon: const Icon(Icons.favorite_rounded, size: 16),
      label: Text(
        'Send Interest',
        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF190606),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF4A1919), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFFD4A034)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                color: const Color(0xFFE0D5CC),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
