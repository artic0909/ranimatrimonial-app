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
/// - Slide 2 (FINAL SLIDE):
///   * Content rows have NO outer background or border (clean icon + text)
///   * Bride image (assets/bride2.png) is rendered BIG from right-bottom expanding upwards & towards top-left
///   * Centered royal header: "Welcome to Rani Matrimonial" & "Where trusted families find perfect matches"
///   * 3 Interactive Carousel dots
///   * "Create Profile" button in Radiant Theme Gold gradient
///   * "Login" button in theme burgundy outline
///   * NO Skip buttons anywhere
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
      'image': 'assets/couple1.jpg',
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

  /// Slide 0 & 1: Cinematic couple photography slides with elegant gold crest (NO Skip button)
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
              const Spacer(flex: 8),

              // Brand Crest & Titles
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: RaniColors.gold.withValues(alpha: 0.4),
                            blurRadius: 18,
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
                    const SizedBox(height: 8),
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

  /// Slide 2 (3rd Onboarding Section):
  /// 1. Content items have NO outer background & NO border (clean icon + text)
  /// 2. Bride image (assets/bride2.png) is rendered BIG from right-bottom expanding upwards & towards top-left
  /// - Centered royal header: "Welcome to Rani Matrimonial"
  /// - 3 Interactive Carousel dots
  /// - Radiant Gold "Create Profile" button & Burgundy outline "Login" button
  /// - NO Skip buttons anywhere
  Widget _buildFinalWelcomeSlide() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAF7F2),
        gradient: RadialGradient(
          center: Alignment(0.3, -0.1),
          radius: 1.35,
          colors: [
            Color(0xFFFFFDF8), // bright warm ivory
            Color(0xFFFAF5EE),
            Color(0xFFF5EEE3), // warm champagne edge
          ],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isShortScreen = constraints.maxHeight < 640;
            final contentMaxWidth = constraints.maxWidth;

            return Stack(
              children: [
                // 1. Warm ambient golden halo aura behind the bride
                Positioned(
                  bottom: isShortScreen ? 140 : 180,
                  right: -20,
                  child: IgnorePointer(
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: RaniColors.gold.withValues(alpha: 0.30),
                            blurRadius: 70,
                            spreadRadius: 25,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. BIG Bride Image (assets/bride2.png):
                // Anchored at right-bottom, expanding upwards and toward top-left in BIG size!
                Positioned(
                  bottom: isShortScreen ? 115 : 130,
                  right: -25,
                  top: isShortScreen ? 70 : 85,
                  width: contentMaxWidth * 0.78, // BIG in size!
                  child: IgnorePointer(
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        return const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          stops: [0.0, 0.32, 0.88, 1.0],
                          colors: [
                            Colors.transparent, // Soft feather fade on the left
                            Colors.black,
                            Colors.black,
                            Colors.transparent, // Soft feather fade at the right edge
                          ],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: ShaderMask(
                        shaderCallback: (bounds) {
                          return const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [0.0, 0.78, 1.0],
                            colors: [
                              Colors.black,
                              Colors.black,
                              Colors.transparent, // Soft feather fade at the bottom
                            ],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.dstIn,
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
                    ),
                  ),
                ),

                // 3. Foreground Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: isShortScreen ? 6 : 14),

                      // Centered Royal Header
                      Text(
                        'Welcome to',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: isShortScreen ? 20 : 22,
                          fontWeight: FontWeight.w700,
                          color: RaniColors.ink,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rani Matrimonial',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: isShortScreen ? 27 : 32,
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
                          fontSize: isShortScreen ? 12.5 : 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF7A6258),
                          height: 1.35,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 12),

                      // Middle: 4 Content Items on the Left - NO BG, NO BORDER!
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCleanFeatureRow(Icons.verified_user_outlined, 'Verified Profiles'),
                              SizedBox(height: isShortScreen ? 14 : 20),
                              _buildCleanFeatureRow(Icons.search_rounded, 'Advanced Search'),
                              SizedBox(height: isShortScreen ? 14 : 20),
                              _buildCleanFeatureRow(Icons.shield_outlined, 'Safe & Secure'),
                              SizedBox(height: isShortScreen ? 14 : 20),
                              _buildCleanFeatureRow(Icons.stars_outlined, 'Personalized Matches'),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Carousel Dots (Interactive)
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

                      const SizedBox(height: 16),

                      // Primary "Create Profile" Button in Radiant Theme Gold
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
                                  color: const Color(0xFF3B0000),
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

                      // Secondary "Login" Button (Rani Theme Burgundy Outline)
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
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Clean feature row with NO container background and NO outer border:
  /// Simply a circular icon on the left, and crisp dark text on the right
  Widget _buildCleanFeatureRow(IconData icon, String title) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF3DFD1),
            border: Border.all(
              color: const Color(0xFFDCBEA8),
              width: 0.8,
            ),
          ),
          child: Icon(icon, color: RaniColors.primary, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.outfit(
            color: const Color(0xFF2C1810),
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
