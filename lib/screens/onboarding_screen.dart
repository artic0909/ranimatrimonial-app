import 'package:flutter/material.dart';
import '../theme/rani_colors.dart';
import '../theme/rani_spacing.dart';
import '../theme/rani_typography.dart';
import 'login_screen.dart';

/// Screen 1: Onboarding Screen
/// - Auto-scroll is turned OFF (manual swipe)
/// - Visuals match the royal wedding couple design reference
/// - Button only appears on the final slide
/// - Button text crafted to maximize mutual interest for both genders ("Find Your Soulmate")
/// - Navigates directly to RaniLoginScreen with prominent "Create Profile" section
class RaniOnboardingScreen extends StatefulWidget {
  const RaniOnboardingScreen({super.key});

  @override
  State<RaniOnboardingScreen> createState() => _RaniOnboardingScreenState();
}

class _RaniOnboardingScreenState extends State<RaniOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _slides = const [
    {
      'title': 'Rani',
      'subtitle': 'MATRIMONIAL',
      'tagline': 'Find Your Perfect Life Partner',
      'description': 'Where genuine hearts & noble families meet with mutual respect',
      'image': 'assets/indexbanner.jpg',
    },
    {
      'title': 'Rani',
      'subtitle': 'MATRIMONIAL',
      'tagline': 'Verified Brides & Grooms',
      'description': '100% genuine profiles verified through government ID & family background',
      'image': 'assets/hero.png',
    },
    {
      'title': 'Rani',
      'subtitle': 'MATRIMONIAL',
      'tagline': 'Your Sacred Story Begins Here',
      'description': 'Thousands of blessed couples united across all cultures & traditions',
      'image': 'assets/card_couple_bg.jpg',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RaniLoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLastSlide = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: RaniColors.surfaceAlt,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Full-screen couple photography PageView (Manual swipe, NO auto-scroll)
          PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            physics: const BouncingScrollPhysics(),
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
                    alignment: const Alignment(0.0, -0.2),
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'assets/hero.png',
                      fit: BoxFit.cover,
                    ),
                  ),

                  // Multi-stop vignette ensuring photography & bottom typography are both radiant
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.0, 0.40, 0.65, 0.85, 1.0],
                        colors: [
                          Color(0x55000000), // Top status bar contrast
                          Colors.transparent,
                          Color(0x661A0000),
                          Color(0xDD3B0000), // Deep burgundy gradient
                          Color(0xFF200006), // Solid deep royal wine at bottom
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // 2. Bottom Content Anchored (Matches user reference screenshot)
          SafeArea(
            child: Column(
              children: [

                const Spacer(flex: 7),

                // 3. Lower Section: Floral Lotus/Crown Crest, Rani MATRIMONIAL & Tagline
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Lotus / Crown Golden Emblem
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: RaniColors.gold.withValues(alpha: 0.4),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.favorite,
                              color: RaniColors.gold,
                              size: 44,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // "Rani" in bold white serif Playfair Display
                      Text(
                        _slides[_currentPage]['title']!,
                        style: RaniTypography.headingXl(color: Colors.white).copyWith(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),

                      // "MATRIMONIAL" in gold tracked caps
                      Text(
                        _slides[_currentPage]['subtitle']!,
                        style: RaniTypography.captionUppercase(color: RaniColors.gold).copyWith(
                          fontSize: 12,
                          letterSpacing: 4.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Tagline
                      Text(
                        _slides[_currentPage]['tagline']!,
                        style: RaniTypography.bodySm(color: Colors.white).copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),

                      // Emotional mutual interest description for both genders
                      Text(
                        _slides[_currentPage]['description']!,
                        style: RaniTypography.caption(color: RaniColors.cream.withValues(alpha: 0.85)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 1),

                // 4. Carousel Indicator Dots
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
                        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  blurRadius: 6,
                                ),
                              ]
                            : null,
                      ),
                    );
                  }),
                ),

                const SizedBox(height: RaniSpacing.lg),

                // 5. Button Area:
                // Slides 0 & 1: No Get Started button (subtle swipe hint)
                // Final Slide: Eye-catching "Find Your Soulmate" button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: AnimatedCrossFade(
                    duration: const Duration(milliseconds: 300),
                    crossFadeState: isLastSlide
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    // FIRST: The Final Slide Button ("Find Your Soulmate")
                    firstChild: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFE5B842), // Rich Radiant Gold
                            Color(0xFFFBE491), // Highlight Gold
                            Color(0xFFC59424), // Deep Burnished Gold
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.55),
                            blurRadius: 18,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: _navigateToLogin,
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.favorite,
                                  color: Color(0xFF3B0000),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Find Your Soulmate',
                                  style: RaniTypography.buttonLarge(
                                    color: const Color(0xFF3B0000),
                                  ).copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Color(0xFF3B0000),
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // SECOND: Swipe guidance for earlier slides
                    secondChild: SizedBox(
                      height: 50,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Swipe to explore',
                                style: RaniTypography.caption(
                                  color: RaniColors.cream.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 12,
                                color: RaniColors.gold.withValues(alpha: 0.8),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: RaniSpacing.md),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
