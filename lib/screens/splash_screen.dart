import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/rani_colors.dart';
import '../theme/rani_spacing.dart';
import '../theme/rani_typography.dart';
import 'onboarding_screen.dart';

/// Cinematic Couple Photography Splash Screen
/// Matches Screen 1 of the Rani Matrimonial design reference:
/// - Full-screen royal bride & groom couple photography with a subtle slow zoom
/// - Multi-layer rich burgundy gradient vignette for cinematic depth
/// - The Rani Matrimonial logo displayed large, crisp, and in its full authentic color
/// - Elegant gold flourish divider and "Find Your Perfect Life Partner" tagline
/// - "MODERN • TRADITIONAL • TRUSTED" hallmark
class RaniSplashScreen extends StatefulWidget {
  const RaniSplashScreen({super.key});

  @override
  State<RaniSplashScreen> createState() => _RaniSplashScreenState();
}

class _RaniSplashScreenState extends State<RaniSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _zoomController;
  late final AnimationController _fadeController;
  late final AnimationController _pulseController;

  late final Animation<double> _scaleAnimation;
  late final Animation<double> _logoFadeAnimation;
  late final Animation<double> _textFadeAnimation;

  Timer? _navTimer;

  @override
  void initState() {
    super.initState();

    // 1. Cinematic slow Ken Burns zoom on the couple photo (1.0 -> 1.08)
    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _zoomController, curve: Curves.easeInOut),
    );
    _zoomController.forward();

    // 2. Entrance fade for the logo and typography
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _logoFadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.15, 0.70, curve: Curves.easeOut),
    );

    _textFadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.45, 1.0, curve: Curves.easeIn),
    );

    // 3. Subtle breathing halo pulse for the logo
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _fadeController.forward();

    // Automatically navigate after 4.0 seconds
    _navTimer = Timer(const Duration(milliseconds: 4000), () {
      if (mounted) {
        _navigateToNext();
      }
    });
  }

  void _navigateToNext() {
    _navTimer?.cancel();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RaniOnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _zoomController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RaniColors.surfaceAlt,
      body: GestureDetector(
        onTap: _navigateToNext, // Allow instant tap-to-continue
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Cinematic Background: Couple Photography with slow zoom
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Image.asset(
                    'assets/indexbanner.jpg',
                    fit: BoxFit.cover,
                    alignment: const Alignment(0.0, -0.2),
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'assets/hero.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),

            // 2. Cinematic Multi-Layer Burgundy Vignette
            // Top shadow for status bar & skip button
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 140,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.75),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Central radial dark burgundy glow so the logo pops with high contrast
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.95,
                  colors: [
                    const Color(0xCC3B0000), // Rich burgundy backing
                    const Color(0x991A0000),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),

            // Bottom dark gradient anchoring the screen
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 260,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.5, 1.0],
                    colors: [
                      Colors.transparent,
                      Color(0xCC1A0000),
                      RaniColors.surfaceAlt, // Solid ink #1A0000 at very bottom
                    ],
                  ),
                ),
              ),
            ),

            // 3. Top Skip Button
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0, right: 16.0),
                  child: TextButton(
                    onPressed: _navigateToNext,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.black.withValues(alpha: 0.35),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      shape: const StadiumBorder(
                        side: BorderSide(
                          color: RaniColors.gold,
                          width: 0.8,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Skip',
                          style: RaniTypography.caption(color: Colors.white),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 10,
                          color: RaniColors.gold,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 4. Central Showcase: Large, Crisp Authentic Logo & Tagline
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The Authentic Rani Matrimonial Logo: Sharp, Large & Vibrant
                    FadeTransition(
                      opacity: _logoFadeAnimation,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final glowAlpha =
                              0.30 + (_pulseController.value * 0.25);
                          final glowBlur =
                              24.0 + (_pulseController.value * 16.0);

                          return Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                // Warm golden backlight halo
                                BoxShadow(
                                  color: RaniColors.gold
                                      .withValues(alpha: glowAlpha),
                                  blurRadius: glowBlur,
                                  spreadRadius: 2,
                                ),
                                // Deep burgundy ambient glow
                                BoxShadow(
                                  color: RaniColors.primary
                                      .withValues(alpha: 0.5),
                                  blurRadius: 40,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/logo.png',
                              width: 190,
                              height: 190,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                width: 160,
                                height: 160,
                                decoration: const BoxDecoration(
                                  color: RaniColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.favorite,
                                    color: RaniColors.gold,
                                    size: 64,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: RaniSpacing.xl),

                    // Elegant Golden Filigree Divider
                    FadeTransition(
                      opacity: _textFadeAnimation,
                      child: Column(
                        children: [
                          _buildFiligreeDivider(),
                          const SizedBox(height: RaniSpacing.md),

                          // Tagline: "Find Your Perfect Life Partner"
                          Text(
                            'Find Your Perfect Life Partner',
                            style: RaniTypography.headingMd(
                              color: Colors.white,
                            ).copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.8),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: RaniSpacing.xs),
                          Text(
                            'Where trusted families find perfect matches',
                            style: RaniTypography.bodySm(
                              color: RaniColors.cream.withValues(alpha: 0.9),
                            ).copyWith(
                              letterSpacing: 0.3,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.8),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 5. Hallmark Footer: "MODERN • TRADITIONAL • TRUSTED"
            Positioned(
              bottom: 34,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _textFadeAnimation,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: RaniSpacing.roundedFull,
                      border: Border.all(
                        color: RaniColors.gold.withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      'MODERN  •  TRADITIONAL  •  TRUSTED',
                      style: RaniTypography.captionUppercase(
                        color: RaniColors.gold,
                      ).copyWith(
                        letterSpacing: 2.8,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Delicate Golden Filigree Divider with 45-degree diamond center
  Widget _buildFiligreeDivider() {
    return SizedBox(
      width: 220,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 0.8,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    RaniColors.gold.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: RaniColors.gold,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 0.8,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    RaniColors.gold.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
