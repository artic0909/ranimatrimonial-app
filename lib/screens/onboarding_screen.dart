import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/rani_colors.dart';
import '../theme/rani_elevation.dart';
import '../theme/rani_spacing.dart';
import '../theme/rani_typography.dart';
import '../components/rani_buttons.dart';
import 'login_screen.dart';
import 'main_navigation_screen.dart';

/// Screen 1: Onboarding Screen
/// - Slide 0 & 1: Cinematic couple photography slides with gold crest & tagline
/// - Slide 2 (FINAL SLIDE): Exactly matches the provided design screenshot:
///   * Warm ivory/cream background
///   * Top-right "Skip" button in burgundy
///   * "Welcome to" & "Rani Matrimonial" in burgundy
///   * "Where trusted families find perfect matches"
///   * 4 Feature Pills on the left:
///       1. Verified Profiles (shield-check)
///       2. Advanced Search (magnifying glass)
///       3. Safe & Secure (shield-check)
///       4. Personalized Matches (star-shield)
///   * Large smiling Indian bride naturally positioned on the right
///   * 3 Carousel Dots with dot 2 active in burgundy
///   * "Create Profile" primary button (Radiant Theme Gold) -> opens 60s registration
///   * "Login" secondary button (Rani Theme Burgundy) -> opens Login screen
class RaniOnboardingScreen extends StatefulWidget {
  const RaniOnboardingScreen({super.key});

  @override
  State<RaniOnboardingScreen> createState() => _RaniOnboardingScreenState();
}

class _RaniOnboardingScreenState extends State<RaniOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _coupleSlides = const [
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

  void _showCreateProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: RaniElevation.lg,
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: RaniColors.neutral,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: RaniSpacing.md),
              Text(
                'Create Your Profile',
                style: RaniTypography.headingMd(color: RaniColors.ink).copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Register in 60 seconds to connect with verified matches',
                style: RaniTypography.bodySm(color: RaniColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: RaniSpacing.lg),
              Text(
                'This profile is for',
                style: RaniTypography.labelMd(color: RaniColors.ink).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Myself', 'My Son', 'My Daughter', 'My Brother', 'My Sister', 'My Friend'].map((type) {
                  final isSelected = type == 'Myself';
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? RaniColors.primary : Colors.white,
                      borderRadius: RaniSpacing.roundedFull,
                      border: Border.all(
                        color: isSelected ? RaniColors.primary : RaniColors.neutral,
                      ),
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        color: isSelected ? Colors.white : RaniColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: RaniSpacing.md),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: RaniSpacing.sm),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: 'Mobile Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: RaniSpacing.sm),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: RaniSpacing.lg),
              RaniPrimaryButton(
                text: 'Register Free & View Matches',
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile created! Welcome to Rani Matrimonial.'),
                    ),
                  );
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const RaniMainNavigationScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _currentPage == 2 ? const Color(0xFFFAF7F2) : RaniColors.surfaceAlt,
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        children: [
          // Slide 0: Cinematic Couple Photography
          _buildCoupleSlide(0),

          // Slide 1: Cinematic Couple Photography
          _buildCoupleSlide(1),

          // Slide 2: EXACT WELCOME SLIDE FROM THE PROVIDED SCREENSHOT
          _buildFinalWelcomeSlide(),
        ],
      ),
    );
  }

  /// Slide 0 & 1: Cinematic couple photography slides with elegant gold crest
  Widget _buildCoupleSlide(int index) {
    final slide = _coupleSlides[index];

    return Stack(
      fit: StackFit.expand,
      children: [
        // Full screen photography
        Image.asset(
          slide['image']!,
          fit: BoxFit.cover,
          alignment: const Alignment(0.0, -0.2),
          errorBuilder: (context, error, stackTrace) => Image.asset(
            'assets/hero.png',
            fit: BoxFit.cover,
          ),
        ),

        // Vignette
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.40, 0.65, 0.85, 1.0],
              colors: [
                Color(0x55000000),
                Colors.transparent,
                Color(0x661A0000),
                Color(0xDD3B0000),
                Color(0xFF200006),
              ],
            ),
          ),
        ),

        // Content
        SafeArea(
          child: Column(
            children: [
              // Top Skip button
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 20, top: 8),
                  child: GestureDetector(
                    onTap: _navigateToLogin,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        'Skip',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 7),

              // Brand Crest & Titles
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                    Text(
                      slide['title']!,
                      style: RaniTypography.headingXl(color: Colors.white).copyWith(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      slide['subtitle']!,
                      style: RaniTypography.captionUppercase(color: RaniColors.gold).copyWith(
                        fontSize: 12,
                        letterSpacing: 4.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      slide['tagline']!,
                      style: RaniTypography.bodySm(color: Colors.white).copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      slide['description']!,
                      style: RaniTypography.caption(
                        color: RaniColors.cream.withValues(alpha: 0.85),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 1),

              // 3 Carousel Indicator Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final isActive = i == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),

              const SizedBox(height: RaniSpacing.lg),

              // Swipe Guidance Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: SizedBox(
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

              const SizedBox(height: RaniSpacing.md),
            ],
          ),
        ),
      ],
    );
  }

  /// Slide 2: Exactly matches the provided design screenshot:
  /// - Full balanced layout filling the screen without cutting buttons off
  /// - Large, natural bride portrait filling the right side
  /// - 4 Feature Pills on the left
  /// - 3 indicator dots
  /// - "Create Profile" button in Radiant Theme Gold
  /// - "Login" button in Rani Theme Burgundy
  Widget _buildFinalWelcomeSlide() {
    return Container(
      color: const Color(0xFFFAF7F2),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isShortScreen = constraints.maxHeight < 620;

            final content = Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Top Right Skip Button (Matching screenshot)
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: _navigateToLogin,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 4),
                        child: Text(
                          'Skip',
                          style: GoogleFonts.outfit(
                            color: RaniColors.primary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 2),

                  // 2. Title & Subtitle (Playfair Display & Outfit matching screenshot)
                  Text(
                    'Welcome to',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: RaniColors.ink,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Rani Matrimonial',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: RaniColors.primary,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Where trusted families\nfind perfect matches',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF7A6258),
                      height: 1.35,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 10),

                  // 3. Middle Section:
                  // Left side: 4 Feature Pills
                  // Right side: The Bride (Large & naturally placed)
                  isShortScreen
                      ? SizedBox(
                          height: 250,
                          child: Row(
                            children: [
                              Expanded(
                                flex: 6,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildFeaturePill(Icons.shield_outlined, 'Verified Profiles'),
                                    _buildFeaturePill(Icons.search_rounded, 'Advanced Search'),
                                    _buildFeaturePill(Icons.shield_outlined, 'Safe & Secure'),
                                    _buildFeaturePill(Icons.stars_outlined, 'Personalized Matches'),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 5,
                                child: Align(
                                  alignment: Alignment.bottomRight,
                                  child: Image.asset(
                                    'assets/bride.png',
                                    fit: BoxFit.contain,
                                    alignment: Alignment.bottomRight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Expanded(
                          child: Row(
                            children: [
                              // Left: 4 Feature Badges exactly as in screenshot
                              Expanded(
                                flex: 6,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildFeaturePill(Icons.shield_outlined, 'Verified Profiles'),
                                    _buildFeaturePill(Icons.search_rounded, 'Advanced Search'),
                                    _buildFeaturePill(Icons.shield_outlined, 'Safe & Secure'),
                                    _buildFeaturePill(Icons.stars_outlined, 'Personalized Matches'),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 6),

                              // Right: Smiling Indian Bride naturally filling the height
                              Expanded(
                                flex: 5,
                                child: Align(
                                  alignment: Alignment.bottomRight,
                                  child: Image.asset(
                                    'assets/bride.png',
                                    fit: BoxFit.contain,
                                    alignment: Alignment.bottomRight,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: const Color(0xFFF3DFCF),
                                      child: const Icon(
                                        Icons.person,
                                        color: RaniColors.primary,
                                        size: 64,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                  const SizedBox(height: 12),

                  // 4. Three Carousel Dots directly above buttons (as in screenshot)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final isActive = i == 2;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? RaniColors.primary
                              : const Color(0xFFE2C9BD),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 14),

                  // 5. Golden "Create Profile" Button (Requested by user in theme gold)
                  Container(
                    width: double.infinity,
                    height: 48,
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
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.45),
                          blurRadius: 14,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showCreateProfileSheet(context),
                        child: Center(
                          child: Text(
                            'Create Profile',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF3B0000), // Deep wine text on gold
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 6. Themed "Login" Button (Rani Theme Burgundy)
                  Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: RaniColors.primary,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _navigateToLogin,
                        child: Center(
                          child: Text(
                            'Login',
                            style: GoogleFonts.outfit(
                              color: RaniColors.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            );

            if (isShortScreen) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: content,
              );
            }

            return content;
          },
        ),
      ),
    );
  }

  /// Feature Pill exactly as in screenshot:
  /// Rounded pill with soft peach background, circular icon container, and dark label
  Widget _buildFeaturePill(IconData icon, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF4ED),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFEBD8C9),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF3DFD1),
              border: Border.all(
                color: const Color(0xFFDCBEA8),
                width: 0.5,
              ),
            ),
            child: Icon(icon, color: RaniColors.primary, size: 15),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.outfit(
                color: const Color(0xFF2C1810),
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
