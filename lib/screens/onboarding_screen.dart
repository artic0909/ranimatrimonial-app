import 'package:flutter/material.dart';
import '../theme/rani_colors.dart';
import '../theme/rani_spacing.dart';
import '../theme/rani_typography.dart';
import '../components/rani_buttons.dart';
import 'welcome_screen.dart';

/// Screen 1: Onboarding / Get Started Screen
/// Features royal couple imagery, floral brand crest, elegant typography,
/// carousel indicators, and the signature Gold CTA button.
class RaniOnboardingScreen extends StatefulWidget {
  const RaniOnboardingScreen({super.key});

  @override
  State<RaniOnboardingScreen> createState() => _RaniOnboardingScreenState();
}

class _RaniOnboardingScreenState extends State<RaniOnboardingScreen> {
  int _currentPage = 0;

  final List<Map<String, String>> _slides = const [
    {
      'title': 'Rani',
      'subtitle': 'MATRIMONIAL',
      'tagline': 'Find Your Perfect Life Partner',
      'image': 'assets/indexbanner.jpg',
    },
    {
      'title': 'Rani',
      'subtitle': 'MATRIMONIAL',
      'tagline': 'Where Trusted Families Connect',
      'image': 'assets/hero.png',
    },
    {
      'title': 'Rani',
      'subtitle': 'MATRIMONIAL',
      'tagline': 'Sacred Bonds Across All Traditions',
      'image': 'assets/card_couple_bg.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RaniColors.surfaceAlt,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background photo with slide transition
          PageView.builder(
            itemCount: _slides.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    _slides[index]['image']!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'assets/hero.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Bottom dark gradient overlay for high contrast
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.0, 0.45, 0.75, 1.0],
                        colors: [
                          Colors.transparent,
                          Color(0x331A0000),
                          Color(0xCC1A0000),
                          RaniColors.surfaceAlt, // Solid ink #1A0000 at bottom
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Foreground Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: RaniSpacing.screenPadding,
                vertical: RaniSpacing.lg,
              ),
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  // Brand Crest & Titles
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Lotus / Crown Golden Emblem
                        Image.asset(
                          'assets/logo.png',
                          height: 72,
                          width: 72,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.favorite,
                            color: RaniColors.gold,
                            size: 64,
                          ),
                        ),
                        const SizedBox(height: RaniSpacing.xs),
                        Text(
                          'Rani',
                          style: RaniTypography.headingXl(color: Colors.white).copyWith(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          'MATRIMONIAL',
                          style: RaniTypography.captionUppercase(color: RaniColors.gold).copyWith(
                            letterSpacing: 4.0,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: RaniSpacing.sm),
                        Text(
                          _slides[_currentPage]['tagline']!,
                          style: RaniTypography.bodySm(color: RaniColors.cream),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // 3 Carousel Indicator Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isActive ? RaniColors.gold : Colors.white.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: RaniSpacing.xl),

                  // Signature Gold CTA Button: "Get Started"
                  SizedBox(
                    width: double.infinity,
                    child: RaniGoldCtaButton(
                      text: 'Get Started',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const RaniWelcomeScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: RaniSpacing.sm),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
