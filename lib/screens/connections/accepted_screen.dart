import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../components/rani_alert.dart';
import '../../components/rani_skeleton_loader.dart';
import '../matches/details_screen.dart';
import '../search/search_screen.dart';

/// Screen: Accepted Connections Screen (Matches Theme)
/// Shows mutual matches where either candidate accepted connection request.
/// Contact details (Phone, WhatsApp, Family & Full Profile) are fully unlocked.
class RaniAcceptedConnectionsScreen extends StatefulWidget {
  final bool showAppBar;
  final VoidCallback? onCountChanged;

  const RaniAcceptedConnectionsScreen({
    super.key,
    this.showAppBar = false,
    this.onCountChanged,
  });

  @override
  State<RaniAcceptedConnectionsScreen> createState() => _RaniAcceptedConnectionsScreenState();
}

class _RaniAcceptedConnectionsScreenState extends State<RaniAcceptedConnectionsScreen> {
  bool _isLoading = true;
  List<dynamic> _requests = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    fetchAcceptedConnections();
  }

  Future<void> fetchAcceptedConnections() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiService.instance.getInbox(tab: 'accepted');
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
          _errorMessage = res['message'] ?? 'Unable to load accepted connections.';
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

  void _showContactDialog(BuildContext context, dynamic c) {
    final name = '${c['first_name'] ?? 'Candidate'} ${c['last_name'] ?? ''}'.trim();
    final details = c['details'] is Map ? c['details'] as Map : {};
    final mobile = details['mobile']?.toString() ?? c['mobile']?.toString() ?? '+91 98201 49842';
    final rawMobile = details['raw_mobile']?.toString() ?? c['raw_mobile']?.toString() ?? '9820149842';
    final email = details['email']?.toString() ?? c['email']?.toString() ?? 'candidate@ranimatrimonial.com';
    final address = details['full_address']?.toString() ?? c['full_address']?.toString() ?? '${c['city'] ?? 'City'}, ${c['state'] ?? 'State'}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: Color(0xFFFAF7F2),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(CupertinoIcons.checkmark_seal_fill, color: Color(0xFF2E7D32), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Direct Contact Unlocked',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2E7D32),
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2B0A0D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Container(height: 1, color: const Color(0xFFEFE8DE)),
            const SizedBox(height: 18),

            // Phone
            _buildContactRow(
              icon: CupertinoIcons.phone_fill,
              iconColor: const Color(0xFF2E7D32),
              title: 'Mobile Phone',
              value: mobile,
              onCopy: () {
                Clipboard.setData(ClipboardData(text: rawMobile));
                Navigator.pop(ctx);
                RaniAlert.success(context, 'Mobile number copied: $mobile', title: 'Copied');
              },
            ),

            const SizedBox(height: 14),

            // WhatsApp
            _buildContactRow(
              icon: CupertinoIcons.chat_bubble_2_fill,
              iconColor: const Color(0xFF25D366),
              title: 'WhatsApp Contact',
              value: mobile,
              onCopy: () {
                Clipboard.setData(ClipboardData(text: rawMobile));
                Navigator.pop(ctx);
                RaniAlert.success(context, 'WhatsApp number copied: $rawMobile', title: 'WhatsApp Number');
              },
            ),

            const SizedBox(height: 14),

            // Email
            _buildContactRow(
              icon: CupertinoIcons.mail_solid,
              iconColor: const Color(0xFF750000),
              title: 'Email Address',
              value: email,
              onCopy: () {
                Clipboard.setData(ClipboardData(text: email));
                Navigator.pop(ctx);
                RaniAlert.success(context, 'Email copied: $email', title: 'Copied');
              },
            ),

            const SizedBox(height: 14),

            // Address
            _buildContactRow(
              icon: CupertinoIcons.location_solid,
              iconColor: const Color(0xFFD4AF37),
              title: 'Residence',
              value: address,
              onCopy: null,
            ),

            const SizedBox(height: 22),

            // Close CTA
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF750000),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text('Done', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required VoidCallback? onCopy,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEFE8DE)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF8E8E93), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(fontSize: 13.5, color: const Color(0xFF1E1E1E), fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              icon: const Icon(CupertinoIcons.doc_on_doc, size: 18, color: Color(0xFF750000)),
              tooltip: 'Copy',
              onPressed: onCopy,
            ),
        ],
      ),
    );
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
            'Accepted Connections',
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
      return const RaniSkeletonCandidateList(isAcceptedTab: true);
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
                onPressed: fetchAcceptedConnections,
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
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.checkmark_seal_fill, size: 40, color: Color(0xFF2E7D32)),
              ),
              const SizedBox(height: 18),
              Text(
                'No Accepted Connections Yet',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2B0A0D),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'When you accept a connection request (or someone accepts yours), full verified contact details and mutual matching will unlock here.',
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
                label: const Text('Discover Matches'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF750000),
      backgroundColor: Colors.white,
      onRefresh: fetchAcceptedConnections,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _requests.length,
        itemBuilder: (context, index) {
          final c = _requests[index];
          return _buildAcceptedCard(c);
        },
      ),
    );
  }

  Widget _buildAcceptedCard(dynamic c) {
    final profileId = c['candidate_code'] ?? c['id']?.toString() ?? c['profile_id'] ?? 'RM00024';
    final firstName = c['first_name'] ?? 'Candidate';
    final lastName = c['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final age = c['age']?.toString() ?? '26';
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
    final matchScore = c['match_score']?.toString() ?? '96';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.05),
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
                builder: (_) => RaniMatchDetailsScreen(
                  profileId: profileId,
                  initialProfileData: c,
                ),
              ),
            );
          },
          child: Column(
            children: [
              // Top Celebration Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.sparkles, color: Color(0xFFE5B842), size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Mutual Match • Unlocked Direct Contact',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const Icon(CupertinoIcons.lock_open_fill, color: Colors.white70, size: 13),
                  ],
                ),
              ),

              // Main Card Details
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Photo with match badge
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: SizedBox(
                                width: 92,
                                height: 110,
                                child: photo.toString().isNotEmpty
                                    ? Image.network(
                                        photo.toString(),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          color: const Color(0xFFEFE7DC),
                                          child: const Icon(CupertinoIcons.person_fill, size: 42, color: Color(0xFFB5A795)),
                                        ),
                                      )
                                    : Container(
                                        color: const Color(0xFFEFE7DC),
                                        child: const Icon(CupertinoIcons.person_fill, size: 42, color: Color(0xFFB5A795)),
                                      ),
                              ),
                            ),
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE5B842),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(CupertinoIcons.star_fill, size: 8.5, color: Color(0xFF4A0000)),
                                    const SizedBox(width: 2),
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

                    // Action Buttons: Direct Contact & View Profile
                    Row(
                      children: [
                        // View Contact Modal CTA
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _showContactDialog(context, c),
                            icon: const Icon(CupertinoIcons.phone_fill, size: 14),
                            label: Text(
                              'View Contact',
                              style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // View Full Profile
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF750000),
                              side: const BorderSide(color: Color(0xFF750000), width: 1.2),
                              padding: const EdgeInsets.symmetric(vertical: 10),
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
                            icon: const Icon(CupertinoIcons.person_crop_circle, size: 15),
                            label: Text(
                              'Full Profile',
                              style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w700),
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
        ),
      ),
    );
  }
}
