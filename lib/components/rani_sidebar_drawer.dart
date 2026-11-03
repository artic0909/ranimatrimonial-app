import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/razorpay_service.dart';
import '../screens/auth/aadhaar_verification_screen.dart';
import '../screens/help_support_screen.dart';
import '../screens/main_navigation_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/splash_screen.dart';

/// Royal Theme Full-Screen Sliding Sidebar Drawer
/// Features:
/// 1. Reactive profile image from candidateNotifier with Royal Gold ring & fallback monogram
/// 2. Candidate name and ID tag
/// 3. Themed squircle Royal Burgundy icons
/// 4. Organized sections: Explore & Connect, Matchmaking & Search, Security & Support, Session
/// 5. Live dynamic wallet balance connected to walletBalanceNotifier
/// 6. Direct Razorpay recharge CTA
class RaniSidebarDrawer extends StatelessWidget {
  final Function(int tabIndex)? onNavigateToTab;
  final int interestsCount;

  const RaniSidebarDrawer({
    super.key,
    this.onNavigateToTab,
    this.interestsCount = 0,
  });

  void _handleTabNavigation(BuildContext context, int index) {
    Navigator.pop(context); // Close drawer
    if (onNavigateToTab != null) {
      onNavigateToTab!(index);
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => RaniMainNavigationScreen(initialIndex: index),
        ),
        (route) => false,
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Log Out',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: const Color(0xFF1E1E1E),
          ),
        ),
        content: Text(
          'Are you sure you want to log out of Rani Matrimonial?',
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: const Color(0xFF6B6B6B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(
                color: const Color(0xFF6B6B6B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF750000),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ApiService.instance.logout();
              if (!context.mounted) return;
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
    final screenWidth = MediaQuery.of(context).size.width;

    return Drawer(
      width: screenWidth,
      backgroundColor: const Color(0xFFFAF7F2),
      child: SafeArea(
        child: Column(
          children: [
            // 1. Top Header with Profile Picture, Candidate ID and Close Button
            ValueListenableBuilder<Map<String, dynamic>?>(
              valueListenable: ApiService.instance.candidateNotifier,
              builder: (context, candidate, _) {
                final firstName = candidate?['first_name'] ?? 'Candidate';
                final lastName = candidate?['last_name'] ?? '';
                final fullName = '$firstName $lastName'.trim();
                final candidateCode = candidate?['candidate_code'] ?? candidate?['profile_id'] ?? 'RM00026';
                final rawPhoto = candidate?['profile_picture_url'] ?? candidate?['profile_picture'] ?? candidate?['photo'] ?? '';
                final photoUrl = ApiService.formatImageUrl(rawPhoto);

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFEFE8DE), width: 1.0),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Profile Image with Royal Gold border ring
                      GestureDetector(
                        onTap: () => _handleTabNavigation(context, 4),
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE5B842), width: 2.0),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF750000).withValues(alpha: 0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: photoUrl.isNotEmpty
                                ? Image.network(
                                    photoUrl,
                                    width: 52,
                                    height: 52,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) => _buildAvatarFallback(fullName),
                                  )
                                : _buildAvatarFallback(fullName),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Candidate Name & ID
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _handleTabNavigation(context, 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                fullName.isNotEmpty ? fullName : 'Rani Member',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E1E1E),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF750000).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFF750000).withValues(alpha: 0.16),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  'ID: $candidateCode',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF750000),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Cross Button to Close Sidebar
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F3EC),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFE8DFD5)),
                            ),
                            child: const Icon(CupertinoIcons.xmark, size: 18, color: Color(0xFF1E1E1E)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // 2. Scrollable Middle Nav Items with Categories
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildSectionHeader('EXPLORE & CONNECT'),
                  _buildSidebarItem(
                    icon: CupertinoIcons.sparkles,
                    title: 'Discover Matches',
                    onTap: () => _handleTabNavigation(context, 1),
                  ),
                  _buildSidebarItem(
                    icon: CupertinoIcons.heart_fill,
                    title: 'Interests & Requests',
                    count: interestsCount,
                    onTap: () => _handleTabNavigation(context, 2),
                  ),
                  _buildSidebarItem(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Royal Wallet',
                    onTap: () => _handleTabNavigation(context, 3),
                  ),
                  _buildSidebarItem(
                    icon: CupertinoIcons.person_crop_circle_fill,
                    title: 'My Profile',
                    onTap: () => _handleTabNavigation(context, 4),
                  ),

                  _buildSectionHeader('SEARCH & DISCOVERY'),
                  _buildSidebarItem(
                    icon: CupertinoIcons.search,
                    title: 'Advanced Search',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RaniSearchScreen()),
                      );
                    },
                  ),
                  _buildSidebarItem(
                    icon: CupertinoIcons.bookmark_fill,
                    title: 'Shortlisted Profiles',
                    onTap: () => _handleTabNavigation(context, 1),
                  ),
                  _buildSidebarItem(
                    icon: CupertinoIcons.slider_horizontal_3,
                    title: 'Partner Preferences',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RaniSearchScreen()),
                      );
                    },
                  ),

                  _buildSectionHeader('SECURITY & SUPPORT'),
                  _buildSidebarItem(
                    icon: CupertinoIcons.checkmark_shield_fill,
                    title: 'Aadhaar & Verification',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RaniAadhaarVerificationScreen()),
                      );
                    },
                  ),
                  _buildSidebarItem(
                    icon: CupertinoIcons.question_circle_fill,
                    title: 'Help & Support Desk',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RaniHelpSupportScreen()),
                      );
                    },
                  ),
                  _buildSidebarItem(
                    icon: CupertinoIcons.gear_alt_fill,
                    title: 'Account Settings',
                    onTap: () => _handleTabNavigation(context, 4),
                  ),

                  _buildSectionHeader('SESSION'),
                  _buildSidebarItem(
                    icon: Icons.logout_rounded,
                    title: 'Log Out',
                    isDestructive: true,
                    onTap: () {
                      Navigator.pop(context);
                      _showLogoutDialog(context);
                    },
                  ),
                ],
              ),
            ),

            // 3. Fixed Bottom Area: Dynamic Wallet Balance & Recharge CTA Button
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEFE8DE), width: 1.0)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 10,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF750000).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                size: 16,
                                color: Color(0xFF750000),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Available Balance',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF6B6B6B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ValueListenableBuilder<double>(
                        valueListenable: ApiService.instance.walletBalanceNotifier,
                        builder: (context, balance, _) {
                          return Text(
                            '₹${balance.toStringAsFixed(2)}',
                            maxLines: 1,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF750000),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF750000),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        RaniRazorpayService.showRechargeModal(
                          context: context,
                          onPaymentSuccess: (amt) {
                            ApiService.instance.getWallet();
                          },
                        );
                      },
                      icon: const Icon(Icons.add_card_rounded, size: 18, color: Color(0xFFE5B842)),
                      label: Text(
                        'Recharge Wallet',
                        style: GoogleFonts.outfit(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
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

  Widget _buildAvatarFallback(String fullName) {
    return Container(
      color: const Color(0xFF750000),
      alignment: Alignment.center,
      child: Text(
        fullName.isNotEmpty ? fullName[0].toUpperCase() : 'R',
        style: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: const Color(0xFFE5B842),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF9E8E7E),
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    int? count,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    final primaryColor = isDestructive ? const Color(0xFFD32F2F) : const Color(0xFF750000);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.5),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDestructive
                      ? const Color(0xFFD32F2F).withValues(alpha: 0.08)
                      : const Color(0xFF750000).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDestructive
                        ? const Color(0xFFD32F2F).withValues(alpha: 0.18)
                        : const Color(0xFF750000).withValues(alpha: 0.12),
                    width: 0.8,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: isDestructive ? const Color(0xFFD32F2F) : const Color(0xFF1E1E1E),
                  ),
                ),
              ),
              if (count != null && count > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF750000),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              Icon(
                CupertinoIcons.chevron_forward,
                size: 14,
                color: isDestructive
                    ? const Color(0xFFD32F2F).withValues(alpha: 0.5)
                    : const Color(0xFFC2B6A6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

