import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../screens/home/verify_profile.dart';
import '../screens/others/support.dart';
import '../screens/others/contact.dart';
import '../screens/others/delete_account_request.dart';
import '../screens/search/search_screen.dart';
import '../screens/main_navigation_screen.dart';
import '../services/razorpay_service.dart';

typedef SidebarTabNavigateCallback = void Function(
  int tabIndex, {
  int? connectionTabIndex,
  String? matchesTab,
  String? walletTab,
});

/// Royal Full-Screen Matrimonial Sliding Sidebar Drawer
/// Matches the luxury Indian theme with:
/// 1. Full-screen width
/// 2. Deep Royal Burgundy header with top-right golden corner artwork, centered logo & branding, avatar, candidate ID & "👑 Premium Member" pill
/// 3. Strictly the 11 user-specified navigation items
/// 4. Fixed bottom Available Balance & "Recharge Wallet" CTA button
class RaniSidebarDrawer extends StatelessWidget {
  final SidebarTabNavigateCallback? onNavigateToTab;
  final int interestsCount;
  final int acceptedCount;
  final int sentCount;
  final int matchesCount;
  final String? activeItem;

  const RaniSidebarDrawer({
    super.key,
    this.onNavigateToTab,
    this.interestsCount = 0,
    this.acceptedCount = 0,
    this.sentCount = 0,
    this.matchesCount = 0,
    this.activeItem,
  });

  void _handleTabNavigation(
    BuildContext context,
    int tabIndex, {
    int? connectionTabIndex,
    String? matchesTab,
    String? walletTab,
  }) {
    Navigator.pop(context);
    if (onNavigateToTab != null) {
      onNavigateToTab!(
        tabIndex,
        connectionTabIndex: connectionTabIndex,
        matchesTab: matchesTab,
        walletTab: walletTab,
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => RaniMainNavigationScreen(
            initialIndex: tabIndex,
            initialConnectionTabIndex: connectionTabIndex,
            initialMatchesTab: matchesTab,
            initialWalletTab: walletTab,
          ),
        ),
        (route) => false,
      );
    }
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

            // 2. Middle Scrollable Nav Items with Dynamic Counts
            Expanded(
              child: ValueListenableBuilder<Map<String, int>>(
                valueListenable: ApiService.instance.sidebarCountsNotifier,
                builder: (context, dynCounts, _) {
                  final liveMatches = (dynCounts['matches'] != null && dynCounts['matches']! > 0)
                      ? dynCounts['matches']!
                      : (matchesCount > 0 ? matchesCount : 0);
                  final liveAccepted = (dynCounts['accepted'] != null)
                      ? dynCounts['accepted']!
                      : (acceptedCount > 0 ? acceptedCount : 0);
                  final liveReceived = (dynCounts['received'] != null)
                      ? dynCounts['received']!
                      : (interestsCount > 0 ? interestsCount : 0);
                  final liveSent = (dynCounts['sent'] != null)
                      ? dynCounts['sent']!
                      : (sentCount > 0 ? sentCount : 0);
                  final liveShortlisted = (dynCounts['shortlisted'] ?? 0);

                  return ScrollConfiguration(
                    behavior: const ScrollBehavior().copyWith(overscroll: false),
                    child: ListView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                      // a. My Matches (Highlighted when active)
                      _buildSidebarItem(
                        icon: CupertinoIcons.sparkles,
                        title: 'My Matches',
                        isHighlighted: activeItem == 'matches',
                        count: liveMatches > 0 ? liveMatches : null,
                        onTap: () => _handleTabNavigation(context, 1, matchesTab: 'new'),
                      ),

                      // b. Accepted Connections
                      _buildSidebarItem(
                        icon: CupertinoIcons.checkmark_seal,
                        title: 'Accepted Connections',
                        isHighlighted: activeItem == 'accepted_connections',
                        count: liveAccepted > 0 ? liveAccepted : null,
                        onTap: () => _handleTabNavigation(context, 2, connectionTabIndex: 2),
                      ),

                      // c. Received Connections
                      _buildSidebarItem(
                        icon: CupertinoIcons.arrow_down_left_circle,
                        title: 'Received Connections',
                        isHighlighted: activeItem == 'received_connections',
                        count: liveReceived > 0 ? liveReceived : null,
                        onTap: () => _handleTabNavigation(context, 2, connectionTabIndex: 0),
                      ),

                      // d. Send Requests
                      _buildSidebarItem(
                        icon: CupertinoIcons.paperplane,
                        title: 'Send Requests',
                        isHighlighted: activeItem == 'sent_requests',
                        count: liveSent > 0 ? liveSent : null,
                        onTap: () => _handleTabNavigation(context, 2, connectionTabIndex: 1),
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        child: Divider(height: 1, thickness: 0.6, color: Color(0xFFECE3D7)),
                      ),

                      // e. My Wallet
                      _buildSidebarItem(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'My Wallet',
                        isHighlighted: activeItem == 'wallet',
                        onTap: () => _handleTabNavigation(context, 3, walletTab: 'wallet'),
                      ),

                      // All Transactions
                      _buildSidebarItem(
                        icon: Icons.receipt_long_rounded,
                        title: 'All Transactions',
                        isHighlighted: activeItem == 'transactions',
                        onTap: () => _handleTabNavigation(context, 3, walletTab: 'transactions'),
                      ),

                      // f. Advance Serch
                      _buildSidebarItem(
                        icon: CupertinoIcons.search,
                        title: 'Advance Search',
                        isHighlighted: activeItem == 'search',
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
                        icon: CupertinoIcons.bookmark,
                        title: 'Shortlisted',
                        isHighlighted: activeItem == 'shortlisted',
                        count: liveShortlisted > 0 ? liveShortlisted : null,
                        onTap: () => _handleTabNavigation(context, 1, matchesTab: 'shortlisted'),
                      ),

                      // h. Aadhaar Verification
                      ValueListenableBuilder<Map<String, dynamic>?>(
                        valueListenable: ApiService.instance.candidateNotifier,
                        builder: (context, candidate, _) {
                          final isVerified = candidate?['is_bluetick_verified'] == true ||
                              candidate?['is_bluetick_verified'] == 1 ||
                              candidate?['verified'] == true ||
                              candidate?['verified'] == 1 ||
                              candidate?['aadhaar_verified'] == true ||
                              candidate?['aadhaar_verified'] == 1 ||
                              candidate?['is_verified'] == true ||
                              candidate?['is_verified'] == 1 ||
                              candidate?['verification_status'] == 'verified';

                          final isPending = !isVerified && (
                              candidate?['verification_status'] == 'pending' ||
                              candidate?['is_accept'] == 0 ||
                              candidate?['bluetick_status'] == 'pending'
                          );

                          return _buildSidebarItem(
                            icon: CupertinoIcons.shield,
                            title: 'Aadhaar Verification',
                            isHighlighted: activeItem == 'aadhaar',
                            trailingBadge: isVerified
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 12),
                                        const SizedBox(width: 3.5),
                                        Text(
                                          'Verified',
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFF2E7D32),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : (isPending
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(CupertinoIcons.clock_fill, color: Color(0xFFD97706), size: 11),
                                            const SizedBox(width: 3.5),
                                            Text(
                                              'Under Review',
                                              style: GoogleFonts.outfit(
                                                color: const Color(0xFFD97706),
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : null),
                            onTap: () {
                              Navigator.pop(context);
                              if (isPending) {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                    title: Row(
                                      children: [
                                        const Icon(CupertinoIcons.clock_fill, color: Color(0xFFD97706), size: 22),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Under Review',
                                          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 17),
                                        ),
                                      ],
                                    ),
                                    content: Text(
                                      'Your Aadhaar verification documents have been submitted and are under review by our admin team. The verification process takes 24-48 hours.',
                                      style: GoogleFonts.outfit(fontSize: 13.5, color: const Color(0xFF4A4A4A), height: 1.4),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: Text('Close', style: GoogleFonts.outfit(color: Colors.grey)),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF750000),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const RaniVerifyProfileScreen(),
                                            ),
                                          );
                                        },
                                        child: Text('View Details', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RaniVerifyProfileScreen(),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        child: Divider(height: 1, thickness: 0.6, color: Color(0xFFECE3D7)),
                      ),

                      // i. Help & Support
                      _buildSidebarItem(
                        icon: CupertinoIcons.headphones,
                        title: 'Help & Support',
                        isHighlighted: activeItem == 'support',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RaniSupportScreen(showAppBar: true)),
                          );
                        },
                      ),

                      // j. Contact Us
                      _buildSidebarItem(
                        icon: CupertinoIcons.phone,
                        title: 'Contact Us',
                        isHighlighted: activeItem == 'contact',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RaniContactUsScreen(showAppBar: true)),
                          );
                        },
                      ),

                      // k. Account Settings
                      _buildSidebarItem(
                        icon: CupertinoIcons.gear_alt,
                        title: 'Account Settings',
                        isHighlighted: activeItem == 'account_settings' || activeItem == 'profile',
                        onTap: () => _handleTabNavigation(context, 4),
                      ),

                      // l. Delete My Account
                      _buildSidebarItem(
                        icon: CupertinoIcons.trash,
                        title: 'Delete My Account',
                        isDestructive: true,
                        isHighlighted: activeItem == 'delete_account',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RaniDeleteAccountRequestScreen(showAppBar: true),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
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
    bool isHighlighted = false,
  }) {
    final primaryColor = isDestructive
        ? const Color(0xFFD32F2F)
        : (iconColor ?? const Color(0xFF750000));

    final textColor = isDestructive
        ? const Color(0xFFD32F2F)
        : (isHighlighted ? const Color(0xFF6B000B) : const Color(0xFF222222));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Material(
        color: isHighlighted
            ? const Color(0xFFFBECE6)
            : (isDestructive
                ? const Color(0xFFD32F2F).withValues(alpha: 0.05)
                : Colors.transparent),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: primaryColor.withValues(alpha: 0.12),
          highlightColor: primaryColor.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Clean elegant icon directly inline (no bulky squircle card)
                Icon(
                  icon,
                  size: 22,
                  color: primaryColor,
                ),
                const SizedBox(width: 15),

                // Title
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: (isHighlighted || isDestructive)
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: textColor,
                      letterSpacing: 0.15,
                    ),
                  ),
                ),

                // Trailing Custom Badge (e.g. Verified) or Count Badge
                if (trailingBadge != null) ...[
                  trailingBadge,
                  const SizedBox(width: 8),
                ] else if (count != null && count > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.5, vertical: 2.5),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF750000),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$count',
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],

                // Trailing Chevron
                Icon(
                  CupertinoIcons.chevron_forward,
                  size: 14,
                  color: isDestructive
                      ? const Color(0xFFD32F2F).withValues(alpha: 0.45)
                      : (isHighlighted
                          ? const Color(0xFF750000).withValues(alpha: 0.75)
                          : const Color(0xFFB5ABA0)),
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
