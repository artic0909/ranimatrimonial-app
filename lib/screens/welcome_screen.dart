import 'package:flutter/material.dart';
import '../theme/rani_colors.dart';
import '../theme/rani_spacing.dart';
import '../theme/rani_typography.dart';
import '../components/rani_buttons.dart';
import 'main_navigation_screen.dart';

/// Screen 2: Welcome / Auth Gate Screen
/// Matches the mockup:
/// - "Welcome to Rani Matrimonial"
/// - "Where trusted families find perfect matches"
/// - 4 Value Proposition points (Verified Profiles, Advanced Search, Trusted & Secure, Personalized Matches)
/// - Smiling bride photo in soft rounded arch
/// - "Create Account" primary button & "Login" outline button
class RaniWelcomeScreen extends StatelessWidget {
  const RaniWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RaniColors.canvas, // Soft cream background #FDFBF7
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: RaniColors.ink, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompactHeight = constraints.maxHeight < 620;
            final isCompactWidth = constraints.maxWidth < 360;
            final brideHeight = isCompactHeight ? 180.0 : 240.0;
            final spacing = isCompactHeight ? RaniSpacing.sm : RaniSpacing.md;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: RaniSpacing.screenPadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: RaniSpacing.xs),

                      // Title & Subtitle
                      Text(
                        'Welcome to',
                        style: RaniTypography.bodyLg(color: RaniColors.textMuted),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rani Matrimonial',
                        style: RaniTypography.headingXl(color: RaniColors.ink).copyWith(
                          fontSize: isCompactWidth ? 26 : 30,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: RaniSpacing.xs),
                      Text(
                        'Where trusted families find perfect matches',
                        style: RaniTypography.bodySm(color: RaniColors.textMuted),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: spacing),

                      // Features & Bride Illustration Showcase
                      Expanded(
                        child: Center(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Left Column: 4 Feature Pillars
                              Expanded(
                                flex: isCompactWidth ? 7 : 6,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const _FeatureRow(
                                      icon: Icons.verified_user_outlined,
                                      title: 'Verified Profiles',
                                    ),
                                    SizedBox(height: spacing),
                                    const _FeatureRow(
                                      icon: Icons.search,
                                      title: 'Advanced Search',
                                    ),
                                    SizedBox(height: spacing),
                                    const _FeatureRow(
                                      icon: Icons.shield_outlined,
                                      title: 'Trusted & Secure',
                                    ),
                                    SizedBox(height: spacing),
                                    const _FeatureRow(
                                      icon: Icons.stars_outlined,
                                      title: 'Personalized Matches',
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: RaniSpacing.sm),

                              // Right Column: Smiling Bride in elegant arched frame
                              Expanded(
                                flex: isCompactWidth ? 5 : 5,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    height: brideHeight,
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(80),
                                        topRight: Radius.circular(80),
                                        bottomLeft: Radius.circular(20),
                                        bottomRight: Radius.circular(20),
                                      ),
                                      border: Border.all(
                                        color: RaniColors.gold,
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: RaniColors.primary.withValues(alpha: 0.12),
                                          blurRadius: 16,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Image.asset(
                                      'assets/bride.png',
                                      fit: BoxFit.cover,
                                      alignment: Alignment.topCenter,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: RaniColors.cream,
                                        child: const Icon(Icons.person, color: RaniColors.gold, size: 64),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: spacing),

                      // Bottom Actions
                      SizedBox(
                        width: double.infinity,
                        child: RaniPrimaryButton(
                          text: 'Create Account',
                          onPressed: () => _enterApp(context),
                        ),
                      ),

                      const SizedBox(height: RaniSpacing.sm),

                      SizedBox(
                        width: double.infinity,
                        child: RaniOutlineButton(
                          text: 'Login',
                          onPressed: () => _enterApp(context),
                        ),
                      ),

                      const SizedBox(height: RaniSpacing.md),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _enterApp(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const RaniMainNavigationScreen(),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;

  const _FeatureRow({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: RaniSpacing.roundedMd,
        border: Border.all(
          color: RaniColors.neutral.withValues(alpha: 0.6),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: RaniColors.gold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: RaniColors.primary, size: 15),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: RaniTypography.labelSm(color: RaniColors.ink).copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
