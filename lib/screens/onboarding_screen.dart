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
/// - Single Screen layout with smooth fade-in & fade-out transitions between slides
///   (avoids split-screen sliding of full-screen images)
/// - Slide 0 & 1: Cinematic couple photography slides with gold crest & brand tagline
/// - Slide 2 (FINAL SLIDE): Redesigned royal welcome slide following Rani Matrimonial theme:
///   * Warm royal ivory/cream backdrop with subtle ambient glow
///   * Regal header with gold flourish, "Welcome to", and "Rani Matrimonial" in burgundy
///   * 4 Royal Feature Badges (Verified Profiles, Advanced Search, Safe & Secure, Personalized Matches)
///   * Majestic transparent portrait of the Indian bride using "assets/bride2.png"
///     framed in a royal arch backdrop
///   * 3 Interactive Carousel Indicator Dots
///   * "Create Profile" CTA button in Radiant Theme Gold gradient
///   * "Login" secondary CTA button in theme burgundy outline
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
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, _) {
        double page = _currentPage.toDouble();
        if (_pageController.hasClients && _pageController.position.haveDimensions) {
          page = _pageController.page ?? _currentPage.toDouble();
        }

        // Seamlessly lerp scaffold background between dark royal ink and warm ivory
        final Color scaffoldBg;
        if (page <= 1.0) {
          scaffoldBg = RaniColors.surfaceAlt;
        } else {
          final t = (page - 1.0).clamp(0.0, 1.0);
          scaffoldBg = Color.lerp(RaniColors.surfaceAlt, const Color(0xFFFAF7F2), t)!;
        }

        return Scaffold(
          backgroundColor: scaffoldBg,
          body: PageView.builder(
            controller: _pageController,
            clipBehavior: Clip.none,
            physics: const BouncingScrollPhysics(),
            itemCount: 3,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final double diff = page - index;
              final double opacity = (1.0 - diff.abs()).clamp(0.0, 1.0);

              final Widget slideWidget;
              if (index == 0) {
                slideWidget = _buildCoupleSlide(0);
              } else if (index == 1) {
                slideWidget = _buildCoupleSlide(1);
              } else {
                slideWidget = _buildFinalWelcomeSlide();
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  // Cancel out PageView's horizontal translation so each slide
                  // stays stationary at full screen, achieving a pure fade-in/fade-out transition.
                  final double cancelOffset = diff * constraints.maxWidth;

                  return Transform.translate(
                    offset: Offset(cancelOffset, 0),
                    child: Opacity(
                      opacity: opacity,
                      child: IgnorePointer(
                        ignoring: opacity < 0.5,
                        child: slideWidget,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
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

        // Vignette for depth & text contrast
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
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
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

              // 3 Carousel Indicator Dots (Interactive)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final isActive = i == index;
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 22 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(3.5),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  blurRadius: 4,
                                ),
                              ]
                            : null,
                      ),
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
                              color: RaniColors.cream.withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: RaniColors.gold.withValues(alpha: 0.9),
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

  /// Slide 2 (3rd onboarding section): Redesigned following the Rani Matrimonial theme
  /// - Royal warm ivory canvas with subtle ambient gold glow
  /// - Elegant header with gold flourish & burgundy Playfair Display typography
  /// - 4 Luxury feature pills with gold-rimmed icon badges
  /// - "assets/bride2.png" gracefully positioned with a royal arched backdrop
  /// - 3 Interactive Carousel dots
  /// - "Create Profile" CTA button in Radiant Theme Gold gradient
  /// - "Login" secondary CTA button in theme burgundy outline
  Widget _buildFinalWelcomeSlide() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAF7F2),
        gradient: RadialGradient(
          center: Alignment(0.0, -0.3),
          radius: 1.25,
          colors: [
            Color(0xFFFFFDF9), // luminous ivory center
            Color(0xFFFAF6F0),
            Color(0xFFF5EEE4), // soft warm champagne edge
          ],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isShortScreen = constraints.maxHeight < 620;

            final content = Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Top Right Skip Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: _navigateToLogin,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: RaniColors.primary.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: RaniColors.primary.withValues(alpha: 0.22),
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          'Skip',
                          style: GoogleFonts.outfit(
                            color: RaniColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 2),

                  // 2. Royal Brand Header
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: 1,
                        color: RaniColors.gold.withValues(alpha: 0.6),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.favorite,
                          size: 13,
                          color: RaniColors.gold,
                        ),
                      ),
                      Container(
                        width: 20,
                        height: 1,
                        color: RaniColors.gold.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Welcome to',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: RaniColors.ink,
                      letterSpacing: 0.2,
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
                  // Left: 4 Luxury Feature Pills
                  // Right: Smiling Bride using assets/bride2.png with Royal Arch Backdrop
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
                                    _buildFeaturePill(Icons.verified_user_rounded, 'Verified Profiles'),
                                    _buildFeaturePill(Icons.search_rounded, 'Advanced Search'),
                                    _buildFeaturePill(Icons.security_rounded, 'Safe & Secure'),
                                    _buildFeaturePill(Icons.auto_awesome_rounded, 'Personalized Matches'),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 5,
                                child: _buildBrideShowcase(),
                              ),
                            ],
                          ),
                        )
                      : Expanded(
                          child: Row(
                            children: [
                              // Left: 4 Feature Badges
                              Expanded(
                                flex: 6,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildFeaturePill(Icons.verified_user_rounded, 'Verified Profiles'),
                                    _buildFeaturePill(Icons.search_rounded, 'Advanced Search'),
                                    _buildFeaturePill(Icons.security_rounded, 'Safe & Secure'),
                                    _buildFeaturePill(Icons.auto_awesome_rounded, 'Personalized Matches'),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Right: Smiling Bride using assets/bride2.png
                              Expanded(
                                flex: 5,
                                child: _buildBrideShowcase(),
                              ),
                            ],
                          ),
                        ),

                  const SizedBox(height: 12),

                  // 4. Three Carousel Dots (Interactive)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final isActive = i == 2;
                      return GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            i,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: isActive ? RaniColors.primary : const Color(0xFFE2C9BD),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: RaniColors.primary.withValues(alpha: 0.35),
                                      blurRadius: 6,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 14),

                  // 5. Golden "Create Profile" Button in Radiant Theme Gold
                  Container(
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
                      borderRadius: BorderRadius.circular(14),
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
                        borderRadius: BorderRadius.circular(14),
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

                  // 6. Themed "Login" Button (Rani Theme Burgundy Outline)
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: RaniColors.primary,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: RaniColors.primary.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
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

                  const SizedBox(height: 14),
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

  /// Bride Showcase with assets/bride2.png framed in a royal arch backdrop
  Widget _buildBrideShowcase() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.bottomRight,
          children: [
            // 1. Royal Mughal / Jharokha Arch Backdrop
            Positioned(
              right: 0,
              bottom: 0,
              top: 8,
              left: 4,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFF7E8D8).withValues(alpha: 0.85),
                      const Color(0xFFFBF1E6).withValues(alpha: 0.45),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(85),
                    topRight: Radius.circular(85),
                  ),
                  border: Border.all(
                    color: RaniColors.gold.withValues(alpha: 0.35),
                    width: 1.0,
                  ),
                ),
              ),
            ),

            // 2. Warm golden ambient aura
            Positioned(
              right: 12,
              top: 16,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: RaniColors.gold.withValues(alpha: 0.22),
                      blurRadius: 36,
                      spreadRadius: 8,
                    ),
                  ],
                ),
              ),
            ),

            // 3. Indian Bride Image using assets/bride2.png
            Align(
              alignment: Alignment.bottomRight,
              child: Image.asset(
                'assets/bride2.png',
                fit: BoxFit.contain,
                alignment: Alignment.bottomRight,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  'assets/bride.png',
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomRight,
                ),
              ),
            ),

            // 4. Soft subtle feather at the bottom so bride blends gracefully
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 24,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFFAF7F2).withValues(alpha: 0.0),
                      const Color(0xFFFAF7F2).withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Feature Pill following Rani Matrimonial design:
  /// Rounded capsule with soft warm peach background, gold-bordered icon badge, and dark label
  Widget _buildFeaturePill(IconData icon, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF4ED),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: RaniColors.gold.withValues(alpha: 0.35),
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: RaniColors.primary.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF9ECE1),
                  Color(0xFFF1D8C4),
                ],
              ),
              border: Border.all(
                color: RaniColors.gold.withValues(alpha: 0.5),
                width: 0.7,
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
