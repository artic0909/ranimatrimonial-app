import 'package:flutter/material.dart';
import '../theme/rani_colors.dart';
import '../theme/rani_elevation.dart';
import '../theme/rani_spacing.dart';
import '../theme/rani_typography.dart';
import '../components/rani_buttons.dart';
import '../components/rani_widgets.dart';

/// Screen 4: Profile Detail Screen
/// Exactly matching the design reference:
/// - Full-height profile photography
/// - Floating rounded card with 16px radius
/// - "Priyanka, 26" with green "✓ Verified" badge
/// - 4 Quick Stat Pills (Height, Religion, Community, Profession)
/// - "About" bio section
/// - Side-by-side action buttons: "Send Interest" (Burgundy) & "Chat" (Outline)
class RaniProfileDetailScreen extends StatefulWidget {
  final Map<String, dynamic> profile;

  const RaniProfileDetailScreen({
    super.key,
    required this.profile,
  });

  @override
  State<RaniProfileDetailScreen> createState() => _RaniProfileDetailScreenState();
}

class _RaniProfileDetailScreenState extends State<RaniProfileDetailScreen> {
  bool _isLiked = false;

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final name = profile['name'] ?? 'Priyanka, 26';
    final profession = profile['profession'] ?? 'Doctor';
    final location = profile['location'] ?? 'Kolkata, West Bengal';
    final image = profile['image'] ?? 'assets/bride.png';
    final isVerified = profile['isVerified'] ?? true;
    final height = profile['height'] ?? '5\'4"';
    final religion = profile['religion'] ?? 'Hindu';
    final community = profile['community'] ?? 'Bengali';
    final about = profile['about'] ??
        'I am a kind, family-oriented and ambitious person. Looking for a genuine life partner who values family, respect and mutual growth.';

    return Scaffold(
      backgroundColor: RaniColors.canvas,
      body: Stack(
        children: [
          // 1. Full height profile photo
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.54,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  image,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: RaniColors.surfaceAlt,
                    child: const Icon(Icons.person, color: RaniColors.gold, size: 80),
                  ),
                ),
                // Top gradient for app bar icons visibility
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 100,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Top bar buttons (Back & Heart)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.35),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.35),
                    child: IconButton(
                      icon: Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked ? Colors.redAccent : Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _isLiked = !_isLiked;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_isLiked
                                ? 'Added $name to your favorites'
                                : 'Removed from favorites'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Floating Detail Card with 16px radius
          Positioned(
            top: MediaQuery.of(context).size.height * 0.44,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                border: Border.all(
                  color: RaniColors.gold.withValues(alpha: 0.4),
                  width: 1.0,
                ),
                boxShadow: RaniElevation.lg,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name & Verified Badge
                    Row(
                      children: [
                        Text(
                          name,
                          style: RaniTypography.headingLg(color: RaniColors.ink).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF2E7D32),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF2E7D32),
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Verified',
                                  style: RaniTypography.caption(
                                    color: const Color(0xFF2E7D32),
                                  ).copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$profession\n$location',
                      style: RaniTypography.bodySm(color: RaniColors.textMuted),
                    ),

                    const SizedBox(height: RaniSpacing.md),
                    const RaniGoldDivider(),
                    const SizedBox(height: RaniSpacing.md),

                    // 4 Quick Stat Pills in responsive horizontal layout
                    Row(
                      children: [
                        _buildStatPill(Icons.straighten, height, 'Height'),
                        const SizedBox(width: 6),
                        _buildStatPill(Icons.temple_hindu_outlined, religion, 'Religion'),
                        const SizedBox(width: 6),
                        _buildStatPill(Icons.diversity_1_outlined, community, 'Community'),
                        const SizedBox(width: 6),
                        _buildStatPill(Icons.medical_services_outlined, profession, 'Profession'),
                      ],
                    ),

                    const SizedBox(height: RaniSpacing.lg),

                    // About section
                    Text(
                      'About',
                      style: RaniTypography.headingSm(color: RaniColors.ink),
                    ),
                    const SizedBox(height: RaniSpacing.xs),
                    Text(
                      about,
                      style: RaniTypography.bodySm(color: RaniColors.ink.withValues(alpha: 0.85))
                          .copyWith(height: 1.5),
                    ),

                    const SizedBox(height: RaniSpacing.xxl),

                    // Side-by-Side Action Buttons: "Send Interest" (Burgundy) & "Chat" (Outline)
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: RaniPrimaryButton(
                            text: 'Send Interest',
                            icon: const Icon(Icons.favorite, size: 16, color: Colors.white),
                            onPressed: () {
                              showRaniDialog(
                                context: context,
                                title: 'Send Interest?',
                                content: 'Are you sure you want to send an interest to $name?',
                                confirmText: 'Send Interest',
                                cancelText: 'Cancel',
                                onConfirm: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Interest sent successfully!'),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: RaniSpacing.sm),
                        Expanded(
                          flex: 2,
                          child: RaniOutlineButton(
                            text: 'Chat',
                            icon: const Icon(Icons.chat_bubble_outline, size: 16, color: RaniColors.ink),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Connecting chat with $name...'),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        decoration: BoxDecoration(
          color: RaniColors.canvas,
          borderRadius: RaniSpacing.roundedMd,
          border: Border.all(
            color: RaniColors.gold.withValues(alpha: 0.4),
            width: 0.8,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: RaniColors.primary, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: RaniTypography.caption(color: RaniColors.ink).copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: RaniTypography.caption(color: RaniColors.textMuted).copyWith(
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
