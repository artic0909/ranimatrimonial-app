import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/rani_colors.dart';
import '../theme/rani_elevation.dart';
import '../theme/rani_spacing.dart';
import '../theme/rani_typography.dart';
import 'register_screen.dart';
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
///   * "Create Profile" button in Radiant Theme Gold gradient -> navigates to RaniRegisterScreen
///   * "Login" button in theme burgundy outline -> opens Login bottom sheet modal
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

  void _navigateToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RaniRegisterScreen(),
      ),
    );
  }

  void _showLoginBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RaniLoginBottomSheetModal(
        onNavigateToRegister: () {
          Navigator.of(context).pop();
          _navigateToRegister();
        },
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
  /// - "Create Profile" button -> Navigates to RaniRegisterScreen
  /// - "Login" button -> Opens Login Bottom Sheet Modal
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

                      // Primary "Create Profile" Button -> Navigates to RaniRegisterScreen
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
                            onTap: _navigateToRegister,
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

                      // Secondary "Login" Button -> Opens Login Bottom Sheet Modal
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
                            onTap: () => _showLoginBottomSheet(context),
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

/// Modal: Eye-Catchy Login Bottom Sheet with Mobile OTP & Email/ID options
class _RaniLoginBottomSheetModal extends StatefulWidget {
  final VoidCallback onNavigateToRegister;

  const _RaniLoginBottomSheetModal({
    required this.onNavigateToRegister,
  });

  @override
  State<_RaniLoginBottomSheetModal> createState() => _RaniLoginBottomSheetModalState();
}

class _RaniLoginBottomSheetModalState extends State<_RaniLoginBottomSheetModal> {
  bool _otpSent = false;

  // Mobile & OTP
  final TextEditingController _mobileController = TextEditingController();
  final FocusNode _mobileFocus = FocusNode();

  final TextEditingController _otp1Controller = TextEditingController();
  final TextEditingController _otp2Controller = TextEditingController();
  final TextEditingController _otp3Controller = TextEditingController();
  final TextEditingController _otp4Controller = TextEditingController();

  final FocusNode _otp1Focus = FocusNode();
  final FocusNode _otp2Focus = FocusNode();
  final FocusNode _otp3Focus = FocusNode();
  final FocusNode _otp4Focus = FocusNode();

  Timer? _timer;
  int _resendSeconds = 25;

  @override
  void initState() {
    super.initState();
    _mobileController.addListener(_onStateChanged);
    _otp1Controller.addListener(_onStateChanged);
    _otp2Controller.addListener(_onStateChanged);
    _otp3Controller.addListener(_onStateChanged);
    _otp4Controller.addListener(_onStateChanged);

    _mobileFocus.addListener(_onStateChanged);
    _otp1Focus.addListener(_onStateChanged);
    _otp2Focus.addListener(_onStateChanged);
    _otp3Focus.addListener(_onStateChanged);
    _otp4Focus.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    setState(() {});
  }

  void _startTimer() {
    _timer?.cancel();
    _resendSeconds = 25;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendSeconds > 0) {
        setState(() {
          _resendSeconds--;
        });
      } else {
        t.cancel();
      }
    });
  }

  void _sendOtp() {
    if (_mobileController.text.trim().length == 10) {
      setState(() {
        _otpSent = true;
      });
      _startTimer();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _otp1Focus.requestFocus();
      });
    }
  }

  void _verifyAndLogin() {
    final otp = '${_otp1Controller.text}${_otp2Controller.text}${_otp3Controller.text}${_otp4Controller.text}';
    if (otp.length == 4) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login verified! Welcome to Rani Matrimonial.'),
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const RaniMainNavigationScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mobileController.dispose();
    _mobileFocus.dispose();
    _otp1Controller.dispose();
    _otp2Controller.dispose();
    _otp3Controller.dispose();
    _otp4Controller.dispose();
    _otp1Focus.dispose();
    _otp2Focus.dispose();
    _otp3Focus.dispose();
    _otp4Focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Explicitly reset global inputDecorationTheme so NO unwanted borders or fills leak in!
    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: const InputDecorationTheme(),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: RaniElevation.lg,
        ),
        padding: EdgeInsets.fromLTRB(
          22,
          16,
          22,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _otpSent ? _buildEyeCatchyOtpView() : _buildLoginEntryView(),
          ),
        ),
      ),
    );
  }

  /// Step 1: Login Credentials View - Mobile Number ONLY (No Tabs)
  Widget _buildLoginEntryView() {
    final isMobileValid = _mobileController.text.trim().length == 10;

    return Column(
      key: const ValueKey(1),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD5CCC4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Brand Emblem Icon
        Center(
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFBF5EB),
              border: Border.all(color: const Color(0xFFE5B842), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE5B842).withValues(alpha: 0.28),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.phone_iphone_rounded,
              color: Color(0xFFD4A034),
              size: 26,
            ),
          ),
        ),
        const SizedBox(height: 12),

        Text(
          'Welcome Back',
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFF2C140E),
            fontWeight: FontWeight.w800,
            fontSize: 24,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Enter your mobile number to receive a 4-digit OTP',
          style: GoogleFonts.outfit(
            color: const Color(0xFF7A6860),
            fontSize: 13.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Clean Mobile Number Input Matching Registration Screen
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            'Mobile Number',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2C140E),
            ),
          ),
        ),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: isMobileValid ? const Color(0xFFFAF7F2) : const Color(0xFFF3ECE4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _mobileFocus.hasFocus
                  ? const Color(0xFFE5B842)
                  : (isMobileValid ? const Color(0xFFD4A034) : const Color(0xFFC7BBAE)),
              width: _mobileFocus.hasFocus ? 1.8 : 1.0,
            ),
            boxShadow: _mobileFocus.hasFocus
                ? [
                    BoxShadow(
                      color: const Color(0xFFE5B842).withValues(alpha: 0.35),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  '+91',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3B0000),
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 24,
                color: const Color(0xFFC7BBAE),
              ),
              Expanded(
                child: TextField(
                  controller: _mobileController,
                  focusNode: _mobileFocus,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  maxLength: 10,
                  cursorColor: const Color(0xFF881337),
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2C140E),
                    letterSpacing: 0.8,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    hintText: '10-digit mobile number',
                    hintStyle: GoogleFonts.outfit(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF8C7972),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // Send OTP Action Button
        GestureDetector(
          onTap: isMobileValid ? _sendOtp : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 48,
            decoration: BoxDecoration(
              gradient: isMobileValid
                  ? const LinearGradient(
                      colors: [Color(0xFFE5B842), Color(0xFFC79224)],
                    )
                  : null,
              color: isMobileValid ? null : const Color(0xFFDDD5CC),
              borderRadius: BorderRadius.circular(24),
              boxShadow: isMobileValid
                  ? [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.45),
                        blurRadius: 14,
                        spreadRadius: 1,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Send OTP',
                    style: GoogleFonts.outfit(
                      color: isMobileValid ? const Color(0xFF3B0000) : const Color(0xFF8C7972),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (isMobileValid) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 18, color: Color(0xFF3B0000)),
                  ],
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 22),

        // Create Profile Link
        Center(
          child: GestureDetector(
            onTap: widget.onNavigateToRegister,
            child: RichText(
              text: TextSpan(
                text: "Don't have an account? ",
                style: GoogleFonts.outfit(
                  color: RaniColors.textMuted,
                  fontSize: 13.5,
                ),
                children: [
                  TextSpan(
                    text: 'Create Profile',
                    style: GoogleFonts.outfit(
                      color: RaniColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Step 2: Ultra Eye-Catchy 4-Digit OTP View
  Widget _buildEyeCatchyOtpView() {
    final otp = '${_otp1Controller.text}${_otp2Controller.text}${_otp3Controller.text}${_otp4Controller.text}';
    final isOtpValid = otp.length == 4;

    return Column(
      key: const ValueKey(2),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD5CCC4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Radiant Golden Shield / Padlock Badge
        Center(
          child: Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFBF4E6),
                  Color(0xFFF7E8CA),
                ],
              ),
              border: Border.all(color: const Color(0xFFE5B842), width: 1.8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE5B842).withValues(alpha: 0.40),
                  blurRadius: 18,
                  spreadRadius: 2,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: Color(0xFFD4A034),
              size: 30,
            ),
          ),
        ),

        const SizedBox(height: 12),

        Text(
          'Verify Mobile OTP',
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFF2C140E),
            fontWeight: FontWeight.w800,
            fontSize: 23,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),

        // Sent Phone Number Badge with Edit link
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF6F0),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD4A034), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.phone_android_rounded, size: 15, color: Color(0xFFD4A034)),
                const SizedBox(width: 6),
                Text(
                  '+91 ${_mobileController.text}',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C140E),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _otpSent = false;
                      _otp1Controller.clear();
                      _otp2Controller.clear();
                      _otp3Controller.clear();
                      _otp4Controller.clear();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF881337).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_rounded, size: 12, color: Color(0xFF881337)),
                        const SizedBox(width: 3),
                        Text(
                          'Edit',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF881337),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // 4 Large Eye-Catchy OTP Digit Cards (58x64)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildEyeCatchyDigitCard(controller: _otp1Controller, focusNode: _otp1Focus, nextFocus: _otp2Focus),
            const SizedBox(width: 12),
            _buildEyeCatchyDigitCard(controller: _otp2Controller, focusNode: _otp2Focus, nextFocus: _otp3Focus, prevFocus: _otp1Focus),
            const SizedBox(width: 12),
            _buildEyeCatchyDigitCard(controller: _otp3Controller, focusNode: _otp3Focus, nextFocus: _otp4Focus, prevFocus: _otp2Focus),
            const SizedBox(width: 12),
            _buildEyeCatchyDigitCard(controller: _otp4Controller, focusNode: _otp4Focus, prevFocus: _otp3Focus),
          ],
        ),

        const SizedBox(height: 20),

        // Resend Timer with Pill design
        Center(
          child: _resendSeconds > 0
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3ECE4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined, size: 15, color: Color(0xFF7A6860)),
                      const SizedBox(width: 6),
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: const Color(0xFF7A6860),
                          ),
                          children: [
                            const TextSpan(text: 'Resend code in '),
                            TextSpan(
                              text: '$_resendSeconds',
                              style: const TextStyle(
                                color: Color(0xFF881337),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const TextSpan(text: ' seconds'),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : GestureDetector(
                  onTap: _startTimer,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.replay_rounded, size: 16, color: Color(0xFFD4A034)),
                      const SizedBox(width: 6),
                      Text(
                        'Resend Code via SMS',
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFD4A034),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
        ),

        const SizedBox(height: 22),

        // Verify & Login Button (Radiant Gold Pill)
        GestureDetector(
          onTap: isOtpValid ? _verifyAndLogin : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 50,
            decoration: BoxDecoration(
              gradient: isOtpValid
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFE5B842),
                        Color(0xFFFBE491),
                        Color(0xFFC79224),
                      ],
                    )
                  : null,
              color: isOtpValid ? null : const Color(0xFFDDD5CC),
              borderRadius: BorderRadius.circular(25),
              boxShadow: isOtpValid
                  ? [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.50),
                        blurRadius: 16,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Verify & Login',
                    style: GoogleFonts.outfit(
                      color: isOtpValid ? const Color(0xFF3B0000) : const Color(0xFF8C7972),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (isOtpValid) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: Color(0xFF3B0000),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Safe & Secure footnote
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline_rounded, size: 13, color: Color(0xFF8C7972)),
            const SizedBox(width: 5),
            Text(
              '100% Safe & Secure Matrimonial Login',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF8C7972),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),
      ],
    );
  }

  /// Eye-Catchy Single Digit Card:
  /// Smooth rounded square (58x64) with glowing gold border when active!
  Widget _buildEyeCatchyDigitCard({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    FocusNode? prevFocus,
  }) {
    final isFocused = focusNode.hasFocus;
    final hasValue = controller.text.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 58,
      height: 64,
      decoration: BoxDecoration(
        color: isFocused
            ? Colors.white
            : (hasValue ? const Color(0xFFFAF7F2) : const Color(0xFFF3ECE4)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFocused
              ? const Color(0xFFE5B842)
              : (hasValue ? const Color(0xFFD4A034) : const Color(0xFFC7BBAE)),
          width: isFocused ? 2.4 : 1.2,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: const Color(0xFFE5B842).withValues(alpha: 0.45),
                  blurRadius: 14,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ]
            : (hasValue
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(1),
          ],
          maxLength: 1,
          textAlign: TextAlign.center,
          cursorColor: const Color(0xFF881337),
          cursorWidth: 2.0,
          cursorHeight: 26.0,
          style: GoogleFonts.outfit(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF3B0000),
          ),
          decoration: const InputDecoration(
            counterText: '',
            isDense: true,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (val) {
            if (val.isNotEmpty && nextFocus != null) {
              nextFocus.requestFocus();
            } else if (val.isEmpty && prevFocus != null) {
              prevFocus.requestFocus();
            }
          },
        ),
      ),
    );
  }
}
