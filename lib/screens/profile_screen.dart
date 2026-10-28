import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../components/rani_alert.dart';
import '../components/rani_matrimonial_loader.dart';
import '../components/rani_skeleton_loader.dart';
import 'splash_screen.dart';
import 'wallet_screen.dart';
import 'help_support_screen.dart';

/// Screen: Candidate Profile & Account Dashboard (matching website my_profile.blade.php)
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
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.instance.getMyProfile();
      final walletRes = await ApiService.instance.getWallet();

      if (mounted) {
        if (res['success'] == true) {
          setState(() {
            _candidate = res['candidate'];
            _bluetick = res['bluetick'];
            _wallet = walletRes['wallet'];
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changeProfilePhoto() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked == null || !mounted) return;

      RaniMatrimonialLoader.show(context, message: 'Updating Profile Photo...');
      final res = await ApiService.instance.uploadProfilePicture(File(picked.path));
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
      RaniAlert.error(context, 'Error: $e');
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF26121B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFD4A034), width: 1.2),
        ),
        title: Text(
          'Royal Farewell',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
            color: const Color(0xFFF3E5AB),
          ),
        ),
        content: Text(
          'Are you sure you wish to log out from Rani Matrimonial?',
          style: GoogleFonts.outfit(color: const Color(0xFFD5CCC4)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B0000),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              RaniMatrimonialLoader.show(context, message: 'Logging out...');
              try {
                await ApiService.instance.logout();
              } catch (_) {}
              if (!mounted) return;
              RaniMatrimonialLoader.hide(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const RaniSplashScreen()),
                (route) => false,
              );
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _candidate == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAF7F2),
        body: SafeArea(
          child: RaniSkeletonProfile(),
        ),
      );
    }

    final c = _candidate ?? {};
    final name = '${c['first_name'] ?? 'Candidate'} ${c['last_name'] ?? ''}'.trim();
    final profileCode = c['candidate_code'] ?? c['profile_id'] ?? 'RM-PROFILE';
    final photo = c['profile_picture'] ?? '';
    final balance = (_wallet?['avl_balance'] as num?)?.toDouble() ?? 0.0;
    final isBlueTickVerified = _bluetick != null && _bluetick!['is_accept'] == 1;

    return Scaffold(
      backgroundColor: const Color(0xFF140505),
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: const Color(0xFF200707),
              elevation: 0,
              centerTitle: true,
              title: Text(
                'My Sanctuary',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFF3E5AB),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Color(0xFFEF5350)),
                  onPressed: _showLogoutDialog,
                  tooltip: 'Log Out',
                ),
              ],
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. Profile Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2C0B0B), Color(0xFF1B0707)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFD4A034), width: 1.2),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFFFFDF73), Color(0xFFD4A034)],
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 46,
                          backgroundColor: const Color(0xFF381212),
                          backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                          child: photo.isEmpty
                              ? const Icon(Icons.person, size: 50, color: Color(0xFFD4A034))
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _changeProfilePhoto,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: const BoxDecoration(
                              color: Color(0xFFD4A034),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, size: 16, color: Color(0xFF1E0A0A)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFF3E5AB),
                        ),
                      ),
                      if (isBlueTickVerified) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, size: 18, color: Color(0xFF4FC3F7)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E0707),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFD4A034).withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      profileCode,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFFDF73),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. Blue Tick Aadhaar Verification Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF200707),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isBlueTickVerified ? const Color(0xFF4FC3F7) : const Color(0xFFD4A034),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isBlueTickVerified ? Icons.verified : Icons.verified_user_outlined,
                    color: isBlueTickVerified ? const Color(0xFF4FC3F7) : const Color(0xFFD4A034),
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBlueTickVerified ? 'Blue Tick Government Verified' : 'Aadhaar Verification',
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFF3E5AB),
                          ),
                        ),
                        Text(
                          isBlueTickVerified
                              ? 'Your government identity is fully verified.'
                              : 'Gain 5x more trust and unlock royal matches by verifying Aadhaar.',
                          style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFFD5CCC4)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. Navigation List Tiles
            _buildNavigationTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Royal Wallet',
              subtitle: 'Available: ₹ ${balance.toStringAsFixed(2)}',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RaniWalletScreen()))
                    .then((_) => _loadProfileData());
              },
            ),

            const SizedBox(height: 10),

            _buildNavigationTile(
              icon: Icons.help_outline_rounded,
              title: 'Help & Support Desk',
              subtitle: 'FAQs, Helplines & Support Tickets',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RaniHelpSupportScreen()));
              },
            ),

            const SizedBox(height: 24),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF5350),
                  side: const BorderSide(color: Color(0xFFEF5350), width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _showLogoutDialog,
                icon: const Icon(Icons.logout),
                label: Text(
                  'Log Out of Account',
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF200707),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF381212)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF140505),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFFD4A034), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFFF3E5AB)),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFFBCAAA4)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFD4A034), size: 20),
          ],
        ),
      ),
    );
  }
}

