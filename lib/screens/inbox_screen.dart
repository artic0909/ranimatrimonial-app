import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../components/rani_alert.dart';
import '../components/rani_matrimonial_loader.dart';
import '../components/rani_skeleton_loader.dart';
import 'profile_detail_screen.dart';

/// Screen: Candidate Inbox (matching website inbox.blade.php)
/// Sub-tabs: Received, Accepted, Declined
/// Action: Accept / Decline connection requests, Start WhatsApp Chat
class RaniInboxScreen extends StatefulWidget {
  final String initialTab;

  const RaniInboxScreen({
    super.key,
    this.initialTab = 'received',
  });

  @override
  State<RaniInboxScreen> createState() => _RaniInboxScreenState();
}

class _RaniInboxScreenState extends State<RaniInboxScreen> {
  late String _activeTab;
  bool _isLoading = true;
  List<dynamic> _requests = [];
  Map<String, dynamic> _counts = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    _fetchInbox();
  }

  Future<void> _fetchInbox() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiService.instance.getInbox(tab: _activeTab);
      if (mounted) {
        if (res['success'] == true) {
          setState(() {
            _requests = res['requests'] ?? [];
            _counts = res['counts'] ?? {};
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = res['message'] ?? 'Unable to load inbox requests.';
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

  Future<void> _respondInterest(String profileId, String action, String name) async {
    RaniMatrimonialLoader.show(
      context,
      message: action == 'accept' ? 'Accepting interest from $name...' : 'Declining request...',
    );

    try {
      final res = await ApiService.instance.respondInterest(profileId, action);
      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);

      if (res['success'] == true) {
        RaniAlert.success(
          context,
          res['message'] ?? 'Response recorded successfully!',
          title: action == 'accept' ? 'Request Accepted' : 'Request Declined',
        );
        _fetchInbox();
      } else {
        RaniAlert.error(context, res['message'] ?? 'Action failed.');
      }
    } catch (e) {
      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);
      RaniAlert.error(context, 'Error: $e');
    }
  }

  Future<void> _requestWhatsAppChat(String profileId, String name) async {
    RaniMatrimonialLoader.show(context, message: 'Unlocking WhatsApp chat...');
    try {
      final res = await ApiService.instance.requestWhatsAppChat(profileId);
      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);

      if (res['success'] == true) {
        RaniAlert.success(
          context,
          res['message'] ?? 'WhatsApp chat unlocked!',
          title: 'Chat Ready',
        );
        _fetchInbox();
      } else {
        RaniAlert.error(context, res['message'] ?? 'Unable to unlock chat.');
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
          'Royal Inbox',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFF3E5AB),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _buildSubTabs(),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFFD4A034),
        backgroundColor: const Color(0xFF200707),
        onRefresh: _fetchInbox,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildSubTabs() {
    final tabs = [
      {'id': 'received', 'label': 'Received', 'count': _counts['pending'] ?? 0},
      {'id': 'accepted', 'label': 'Accepted', 'count': _counts['accepted'] ?? 0},
      {'id': 'declined', 'label': 'Declined', 'count': _counts['declined'] ?? 0},
    ];

    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF160404),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF381212), width: 1),
      ),
      child: Row(
        children: tabs.map((t) {
          final isSelected = _activeTab == t['id'];
          final count = t['count'] as int;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (_activeTab != t['id']) {
                  setState(() => _activeTab = t['id'] as String);
                  _fetchInbox();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFD4A034) : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      t['label'] as String,
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? const Color(0xFF1E0A0A) : const Color(0xFFD5CCC4),
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF1E0A0A) : const Color(0xFF8B0000),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: GoogleFonts.outfit(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? const Color(0xFFF3E5AB) : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const SingleChildScrollView(
        child: RaniSkeletonList(itemCount: 6),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 54, color: Color(0xFFE57373)),
              const SizedBox(height: 12),
              Text(_errorMessage!, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _fetchInbox, child: const Text('Retry')),
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
              const Icon(Icons.mail_outline_rounded, size: 64, color: Color(0xFFD4A034)),
              const SizedBox(height: 16),
              Text(
                'No ${_activeTab.capitalize()} Requests',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFF3E5AB),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'When candidates express interest or respond to your connection requests, they will appear here.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 13, color: Colors.white60),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _requests.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, i) {
        final item = _requests[i];
        return _buildInboxCard(item);
      },
    );
  }

  Widget _buildInboxCard(dynamic item) {
    final profileCode = item['id']?.toString() ?? '';
    final name = '${item['first_name'] ?? 'Candidate'} ${item['last_name'] ?? ''}'.trim();
    final age = item['age'] ?? '26';
    final height = item['height'] ?? "5' 5\"";
    final profession = item['profession'] ?? 'Professional';
    final city = item['city'] ?? 'City';
    final photo = item['photo'] ?? '';
    final isVerified = item['verified'] == true;
    final matchScore = item['match_score'] ?? 85;
    final timeAgo = item['received_ago'] ?? 'Recently';
    final status = item['status'] ?? 'pending';
    final isAccepted = status == 'accepted';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF200707),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4A1919), width: 1),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  photo,
                  width: 76,
                  height: 94,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 76,
                    height: 94,
                    color: const Color(0xFF381212),
                    child: const Icon(Icons.person, color: Color(0xFFD4A034)),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '$name, $age',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFF3E5AB),
                            ),
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 5),
                          const Icon(Icons.verified, size: 16, color: Color(0xFF4FC3F7)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$profession • $height',
                      style: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFFD5CCC4)),
                    ),
                    Text(
                      city,
                      style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFFBCAAA4)),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E0C0C),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFD4A034).withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            '$matchScore% Match',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFFDF73),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          timeAgo,
                          style: GoogleFonts.outfit(fontSize: 11, color: Colors.white54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: Color(0xFF381212), height: 1),
          const SizedBox(height: 10),

          // Action row
          Row(
            children: [
              // View Profile Outline
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF3E5AB),
                    side: const BorderSide(color: Color(0xFFD4A034), width: 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RaniProfileDetailScreen(
                          profileId: profileCode,
                          initialProfileData: item,
                        ),
                      ),
                    ).then((_) => _fetchInbox());
                  },
                  child: Text('View Profile', style: GoogleFonts.outfit(fontSize: 12)),
                ),
              ),

              const SizedBox(width: 8),

              // Accept / Decline or WhatsApp Chat
              if (status == 'pending') ...[
                // Decline
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFFEF5350)),
                  onPressed: () => _respondInterest(profileCode, 'decline', name),
                  tooltip: 'Decline',
                ),
                // Accept
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4A034),
                      foregroundColor: const Color(0xFF1E0A0A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () => _respondInterest(profileCode, 'accept', name),
                    icon: const Icon(Icons.check, size: 16),
                    label: Text(
                      'Accept',
                      style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ] else if (isAccepted) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () => _requestWhatsAppChat(profileCode, name),
                    icon: const Icon(Icons.chat, size: 16),
                    label: Text(
                      'WhatsApp Chat',
                      style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  'Declined',
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
