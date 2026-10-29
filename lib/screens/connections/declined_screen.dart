import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../components/rani_skeleton_loader.dart';
import '../matches/details_screen.dart';
import '../search/search_screen.dart';

/// Screen: Declined Connections Screen (Matches Theme, strictly 'declined' as website)
/// Shows connection requests that were declined.
class RaniDeclinedConnectionsScreen extends StatefulWidget {
  final bool showAppBar;
  final VoidCallback? onCountChanged;

  const RaniDeclinedConnectionsScreen({
    super.key,
    this.showAppBar = false,
    this.onCountChanged,
  });

  @override
  State<RaniDeclinedConnectionsScreen> createState() => _RaniDeclinedConnectionsScreenState();
}

class _RaniDeclinedConnectionsScreenState extends State<RaniDeclinedConnectionsScreen> {
  bool _isLoading = true;
  List<dynamic> _requests = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    fetchDeclinedConnections();
  }

  Future<void> fetchDeclinedConnections() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiService.instance.getInbox(tab: 'declined');
      if (!mounted) return;

      if (res['success'] == true) {
        setState(() {
          _requests = res['requests'] ?? [];
          _isLoading = false;
        });
        if (widget.onCountChanged != null) {
          widget.onCountChanged!();
        }
      } else {
        setState(() {
          _errorMessage = res['message'] ?? 'Unable to load declined requests.';
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

  @override
  Widget build(BuildContext context) {
    final content = _buildBody();

    if (widget.showAppBar) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAF7F2),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFAF7F2),
          elevation: 0,
          centerTitle: true,
          title: Text(
            'Declined Connections',
            style: GoogleFonts.playfairDisplay(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2B0A0D),
            ),
          ),
        ),
        body: content,
      );
    }

    return content;
  }

  Widget _buildBody() {
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
                onPressed: fetchDeclinedConnections,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_requests.isEmpty) {
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
                child: const Icon(CupertinoIcons.clear_circled, size: 38, color: Color(0xFF750000)),
              ),
              const SizedBox(height: 18),
              Text(
                'No Declined Requests',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2B0A0D),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You have not declined any connection requests. All your connection requests are active and up-to-date.',
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
                label: const Text('Find Compatible Matches'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF750000),
      backgroundColor: Colors.white,
      onRefresh: fetchDeclinedConnections,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _requests.length,
        itemBuilder: (context, index) {
          final c = _requests[index];
          return _buildDeclinedCard(c);
        },
      ),
    );
  }

  Widget _buildDeclinedCard(dynamic c) {
    final profileId = c['candidate_code'] ?? c['id']?.toString() ?? c['profile_id'] ?? 'RM00024';
    final firstName = c['first_name'] ?? 'Candidate';
    final lastName = c['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final age = c['age']?.toString() ?? '25';
    final height = c['height']?.toString() ?? "5' 5\"";
    final religion = c['religion']?.toString() ?? 'Muslim';
    final community = c['community']?.toString() ?? '';
    final religionWithCommunity = (community.isNotEmpty && community.toLowerCase() != 'all')
        ? '$religion, $community'
        : religion;
    final profession = c['profession']?.toString() ?? c['highest_qualification']?.toString() ?? 'Professional';
    final city = c['city']?.toString() ?? '';
    final state = c['state']?.toString() ?? '';
    final locationText = (city.isNotEmpty && state.isNotEmpty) ? '$city, $state' : (city.isNotEmpty ? city : state);
    final photo = c['photo'] ?? c['profile_picture'] ?? '';
    final isVerified = c['verified'] == true || (c['bluetick'] != null && c['bluetick']['is_accept'] == 1);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEFE8DE), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                    // Photo
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: 90,
                        height: 105,
                        child: photo.toString().isNotEmpty
                            ? Image.network(
                                photo.toString(),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: const Color(0xFFEFE7DC),
                                  child: const Icon(CupertinoIcons.person_fill, size: 40, color: Color(0xFFB5A795)),
                                ),
                              )
                            : Container(
                                color: const Color(0xFFEFE7DC),
                                child: const Icon(CupertinoIcons.person_fill, size: 40, color: Color(0xFFB5A795)),
                              ),
                      ),
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
                                  size: 15,
                                  color: Color(0xFF2196F3),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID: $profileId',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF8E8E93),
                            ),
                          ),
                          const SizedBox(height: 4),
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
                                  profession,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF555555)),
                                ),
                              ),
                            ],
                          ),
                          if (locationText.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(CupertinoIcons.location, size: 12, color: Color(0xFF750000)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    locationText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF555555)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Footer Row: Declined Badge & View Profile
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFFCDD2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(CupertinoIcons.xmark_circle_fill, size: 13, color: Color(0xFFD32F2F)),
                          const SizedBox(width: 4),
                          Text(
                            'Declined',
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFD32F2F),
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF750000),
                        side: const BorderSide(color: Color(0xFF750000)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RaniMatchDetailsScreen(
                              profileId: profileId,
                              initialProfileData: c,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(CupertinoIcons.person_crop_circle, size: 14),
                      label: Text(
                        'View Profile',
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700),
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

