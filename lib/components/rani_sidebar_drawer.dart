import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../screens/auth/aadhaar_verification_screen.dart';
import '../screens/help_support_screen.dart';
import '../screens/main_navigation_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/connections/connection_request.dart';
import '../screens/matches/matches_screen.dart';
import '../services/razorpay_service.dart';

/// Royal Full-Screen Matrimonial Sliding Sidebar Drawer
/// Matches the luxury Indian theme with:
/// 1. Full-screen width
/// 2. Deep Royal Burgundy header with top-right golden corner artwork, centered logo & branding, avatar, candidate ID & "👑 Premium Member" pill
/// 3. Strictly the 11 user-specified navigation items
/// 4. Fixed bottom Available Balance & "Recharge Wallet" CTA button
class RaniSidebarDrawer extends StatelessWidget {
  final Function(int tabIndex)? onNavigateToTab;
  final int interestsCount;
  final int acceptedCount;
  final int sentCount;
  final int matchesCount;

  const RaniSidebarDrawer({
    super.key,
    this.onNavigateToTab,
    this.interestsCount = 0,
    this.acceptedCount = 0,
    this.sentCount = 0,
    this.matchesCount = 0,
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

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFD32F2F).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(CupertinoIcons.trash_fill, color: Color(0xFFD32F2F), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete Account',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: const Color(0xFF1E1E1E),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete your Rani Matrimonial account?\n\nThis will remove your candidate profile, connections, messages, and uploaded photos. This action cannot be undone.',
          style: GoogleFonts.outfit(
            fontSize: 13.5,
            color: const Color(0xFF555555),
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF6B6B6B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    Navigator.pop(context); // Close drawer
                    await ApiService.instance.logout();
                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const RaniSplashScreen()),
                      (route) => false,
                    );
                  },
                  child: Text(
                    'Delete',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Drawer(
      width: screenWidth, // Whole screen width as requested
      backgroundColor: const Color(0xFFFAF7F2),
      child: SafeArea(
        top: false, // Allow header to extend smoothly to top notch
        child: Column(
          children: [
            // 1. Top Royal Burgundy Header
            _buildTopRoyalHeader(context),

            // 2. Middle Scrollable Nav Items (Strictly the 11 Items)
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                children: [
                  // a. My Matches
                  _buildSidebarItem(
                    icon: CupertinoIcons.sparkles,
                    title: 'My Matches',
                    count: matchesCount > 0 ? matchesCount : null,
                    onTap: () => _handleTabNavigation(context, 1),
                  ),

                  // b. Accepted Connections
                  _buildSidebarItem(
                    icon: CupertinoIcons.checkmark_seal_fill,
                    iconColor: const Color(0xFF00796B),
                    title: 'Accepted Connections',
                    count: acceptedCount > 0 ? acceptedCount : null,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RaniConnectionsScreen(
                            initialTabIndex: 2,
                            showAppBar: true,
                          ),
                        ),
                      );
                    },
                  ),

                  // c. Received Connections
                  _buildSidebarItem(
                    icon: CupertinoIcons.arrow_down_left_circle_fill,
                    iconColor: const Color(0xFF750000),
                    title: 'Received Connections',
                    count: interestsCount > 0 ? interestsCount : null,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RaniConnectionsScreen(
                            initialTabIndex: 0,
                            showAppBar: true,
                          ),
                        ),
                      );
                    },
                  ),

                  // d. Send Requests
                  _buildSidebarItem(
                    icon: CupertinoIcons.paperplane_fill,
                    iconColor: const Color(0xFF1976D2),
                    title: 'Send Requests',
                    count: sentCount > 0 ? sentCount : null,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RaniConnectionsScreen(
                            initialTabIndex: 1,
                            showAppBar: true,
                          ),
                        ),
                      );
                    },
                  ),

                  // e. My Wallet
                  _buildSidebarItem(
                    icon: Icons.account_balance_wallet_rounded,
                    iconColor: const Color(0xFFB78103),
                    title: 'My Wallet',
                    onTap: () => _handleTabNavigation(context, 3),
                  ),

                  // f. Advance Serch
                  _buildSidebarItem(
                    icon: CupertinoIcons.search,
                    iconColor: const Color(0xFF750000),
                    title: 'Advance Serch',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RaniSearchScreen()),
                      );
                    },
                  ),

                  // g. Shortlisted
                  _buildSidebarItem(
                    icon: CupertinoIcons.bookmark_fill,
                    iconColor: const Color(0xFFD81B60),
                    title: 'Shortlisted',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RaniMatchesScreen(
                            initialTab: 'shortlisted',
                            showAppBar: true,
                          ),
                        ),
                      );
                    },
                  ),

                  // h. Aadhaar Verification
                  ValueListenableBuilder<Map<String, dynamic>?>(
                    valueListenable: ApiService.instance.candidateNotifier,
                    builder: (context, candidate, _) {
                      final isVerified = candidate?['aadhaar_verified'] == true ||
                          candidate?['aadhaar_verified'] == 1 ||
                          candidate?['is_verified'] == true ||
                          candidate?['is_verified'] == 1 ||
                          candidate?['verification_status'] == 'verified';

                      return _buildSidebarItem(
                        icon: CupertinoIcons.shield_lefthalf_fill,
                        iconColor: const Color(0xFF2E7D32),
                        title: 'Aadhaar Verification',
                        trailingBadge: isVerified
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E7D32),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Verified',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    const Icon(Icons.check, color: Colors.white, size: 12),
                                  ],
                                ),
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RaniAadhaarVerificationScreen()),
                          );
                        },
                      );
                    },
                  ),

                  // i. Help & Support
                  _buildSidebarItem(
                    icon: CupertinoIcons.question_circle_fill,
                    iconColor: const Color(0xFF455A64),
                    title: 'Help & Support',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RaniHelpSupportScreen()),
                      );
                    },
                  ),

                  // j. Account Settings
                  _buildSidebarItem(
                    icon: CupertinoIcons.gear_alt_fill,
                    iconColor: const Color(0xFF4E342E),
                    title: 'Account Settings',
                    onTap: () => _handleTabNavigation(context, 4),
                  ),

                  // k. Delete My Account
                  _buildSidebarItem(
                    icon: CupertinoIcons.trash_fill,
                    title: 'Delete My Account',
                    isDestructive: true,
                    onTap: () => _showDeleteAccountDialog(context),
                  ),
                ],
              ),
            ),

            // 3. Fixed Bottom Area: Dynamic Wallet Balance & Recharge CTA Button
            _buildFixedWalletBottomBar(context),
          ],
        ),
      ),
    );
  }

  /// 1. Royal Burgundy Header with Logo, Faded Mandala, Candidate Info & Golden Pill
  Widget _buildTopRoyalHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF630008),
            Color(0xFF4A0005),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A0005).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        child: Stack(
          children: [
            // Golden Indian Royal Corner Artwork in Top-Left (Flipped)
            Positioned(
              top: 0,
              left: 0,
              width: 175,
              height: 175,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.50,
                  child: Transform.flip(
                    flipX: true,
                    child: Image.asset(
                      'assets/sidebar-top-right-corner.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.topLeft,
                      errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),

            // Golden Indian Royal Corner Artwork in Top-Right
            Positioned(
              top: 0,
              right: 0,
              width: 175,
              height: 175,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.50,
                  child: Image.asset(
                    'assets/sidebar-top-right-corner.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.topRight,
                    errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),

            // Header Content
            Padding(
              padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Row: Rani Matrimonial with Logo in Middle & Close Button on Right
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Centered Brand Logo & Royal Typography
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/logo.png',
                              height: 38,
                              fit: BoxFit.contain,
                              errorBuilder: (ctx, err, stack) => const Icon(
                                Icons.workspace_premium_rounded,
                                color: Color(0xFFF3C05D),
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Rani',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    fontStyle: FontStyle.italic,
                                    color: const Color(0xFFF3C05D),
                                    letterSpacing: 0.6,
                                    height: 1.0,
                                  ),
                                ),
                                Text(
                                  'MATRIMONIAL',
                                  style: GoogleFonts.outfit(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withValues(alpha: 0.92),
                                    letterSpacing: 2.0,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Close Cross Button Aligned to Right
                      Align(
                        alignment: Alignment.centerRight,
                        child: Material(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  width: 0.9,
                                ),
                              ),
                              child: const Icon(
                                CupertinoIcons.xmark,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Candidate Profile Section
                  ValueListenableBuilder<Map<String, dynamic>?>(
                    valueListenable: ApiService.instance.candidateNotifier,
                    builder: (context, candidate, _) {
                      final firstName = candidate?['first_name'] ?? 'Candidate';
                      final lastName = candidate?['last_name'] ?? '';
                      final fullName = '$firstName $lastName'.trim();
                      final candidateCode = candidate?['candidate_code'] ?? candidate?['profile_id'] ?? 'RM102458';
                      final rawPhoto = candidate?['profile_picture_url'] ?? candidate?['profile_picture'] ?? candidate?['photo'] ?? '';
                      final photoUrl = ApiService.formatImageUrl(rawPhoto);

                      return InkWell(
                        onTap: () => _handleTabNavigation(context, 4),
                        borderRadius: BorderRadius.circular(16),
                        child: Row(
                          children: [
                            // Circular photo with Royal Gold border ring
                            Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFF3C05D),
                                  width: 2.4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: photoUrl.isNotEmpty
                                    ? Image.network(
                                        photoUrl,
                                        width: 62,
                                        height: 62,
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, stack) => _buildAvatarFallback(fullName),
                                      )
                                    : _buildAvatarFallback(fullName),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Candidate Name, ID & Premium Pill
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    fullName.isNotEmpty ? fullName : 'Rani Member',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      fontSize: 17.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'ID: $candidateCode',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFFFFD5D8),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // Golden "👑 Premium Member" pill
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFFCE195), Color(0xFFE5B842)],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFE5B842).withValues(alpha: 0.35),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.workspace_premium_rounded,
                                            size: 13.5,
                                            color: Color(0xFF5A0008),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Premium Member',
                                            style: GoogleFonts.outfit(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF5A0008),
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Chevron forward icon
                            Icon(
                              CupertinoIcons.chevron_forward,
                              size: 18,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 3. Fixed Bottom Area: Dynamic Wallet Balance & "Recharge Wallet" CTA Button
  Widget _buildFixedWalletBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: const Border(
          top: BorderSide(color: Color(0xFFEFE8DE), width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
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
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF750000).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 18,
                        color: Color(0xFF750000),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Available Balance',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF555555),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ValueListenableBuilder<double>(
                valueListenable: ApiService.instance.walletBalanceNotifier,
                builder: (context, balance, _) {
                  return Text(
                    '₹${balance.toStringAsFixed(2)}',
                    maxLines: 1,
                    style: GoogleFonts.outfit(
                      fontSize: 17.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF750000),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF750000),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(context);
                RaniRazorpayService.showRechargeModal(
                  context: context,
                  onPaymentSuccess: (amt) {
                    ApiService.instance.getDashboard();
                  },
                );
              },
              icon: const Icon(
                Icons.add_card_rounded,
                size: 19,
                color: Color(0xFFE5B842),
              ),
              label: Text(
                'Recharge Wallet',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Clean, elegant sidebar item matching luxury Indian matrimonial styling
  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    int? count,
    Widget? trailingBadge,
    bool isDestructive = false,
  }) {
    final primaryColor = isDestructive ? const Color(0xFFD32F2F) : (iconColor ?? const Color(0xFF750000));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Material(
        color: isDestructive
            ? const Color(0xFFD32F2F).withValues(alpha: 0.04)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: primaryColor.withValues(alpha: 0.1),
          highlightColor: primaryColor.withValues(alpha: 0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDestructive
                    ? const Color(0xFFD32F2F).withValues(alpha: 0.2)
                    : const Color(0xFFEFE8DE),
                width: 0.9,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                // Theme colored squircle icon container with soft gradient
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryColor.withValues(alpha: 0.14),
                        primaryColor.withValues(alpha: 0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.22),
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 19,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 13),

                // Title
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 14.5,
                      fontWeight: isDestructive ? FontWeight.w700 : FontWeight.w600,
                      color: isDestructive ? const Color(0xFFD32F2F) : const Color(0xFF1E1E1E),
                      letterSpacing: 0.1,
                    ),
                  ),
                ),

                // Trailing Custom Badge (e.g. Verified) or Count Badge
                if (trailingBadge != null) ...[
                  trailingBadge,
                  const SizedBox(width: 6),
                ] else if (count != null && count > 0) ...[
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
                ],

                // Trailing Chevron
                Icon(
                  CupertinoIcons.chevron_forward,
                  size: 13.5,
                  color: isDestructive
                      ? const Color(0xFFD32F2F).withValues(alpha: 0.45)
                      : const Color(0xFFC7BCAE),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(String fullName) {
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'R';
    return Container(
      color: const Color(0xFF750000),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFE5B842),
        ),
      ),
    );
  }
}
