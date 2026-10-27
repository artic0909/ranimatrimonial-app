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
import '../services/api_service.dart';
import '../components/rani_alert.dart';

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

        // Seamlessly lerp scaffold background between dark royal ink and rich crimson #720301
        final Color scaffoldBg;
        if (page <= 1.0) {
          scaffoldBg = RaniColors.surfaceAlt;
        } else {
          final t = (page - 1.0).clamp(0.0, 1.0);
          scaffoldBg = Color.lerp(RaniColors.surfaceAlt, const Color(0xFF380007), t)!;
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

  /// Slide 2 (Final Slide):
  /// - Full bleed image "assets/slide3.png" (cultural couples collage + central Rani emblem)
  /// - Bottom container with top-left & top-right rounded corners (color: #720301)
  /// - Contains Carousel Dots, "Create Profile" button & "Login" button
  Widget _buildFinalWelcomeSlide() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Full-bleed Artwork: assets/slide3.png
        Positioned.fill(
          child: Image.asset(
            'assets/slide3.png',
            fit: BoxFit.cover,
            alignment: const Alignment(0.0, -0.15),
            errorBuilder: (context, error, stackTrace) => Image.asset(
              'assets/hero.png',
              fit: BoxFit.cover,
            ),
          ),
        ),

        // 2. Subtle status bar vignette at top
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 90,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66000000),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // 3. Bottom container: top-left & top-right rounded shape (Logo Dark Reddish Theme)
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF4D020D), // Logo authentic rich dark reddish wine
                  Color(0xFF280005), // Deep dark wine shade
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              border: Border(
                top: BorderSide(
                  color: RaniColors.gold.withValues(alpha: 0.50),
                  width: 1.5,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.65),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                          width: isActive ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: isActive ? RaniColors.gold : Colors.white.withValues(alpha: 0.35),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: RaniColors.gold.withValues(alpha: 0.60),
                                      blurRadius: 8,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 18),

                  // Primary "Create Profile" Button -> Theme Golden Type Gradient
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: [0.0, 0.35, 0.70, 1.0],
                        colors: [
                          Color(0xFFF3DA89), // Light metallic gold highlight
                          Color(0xFFD4AF37), // Theme core gold (RaniColors.gold)
                          Color(0xFFC59B27), // Theme secondary gold (RaniColors.goldSecondary)
                          Color(0xFFA67B1C), // Deep rich gold
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.30),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                        BoxShadow(
                          color: RaniColors.gold.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _navigateToRegister,
                        child: Center(
                          child: Text(
                            'Create Profile',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF3B0000), // Theme link ink color on gold
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Secondary "Login" Button -> Opens Login Bottom Sheet Modal
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: RaniColors.gold,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.20),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _showLoginBottomSheet(context),
                        child: Center(
                          child: Text(
                            'Login',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF4D020D), // Logo dark reddish color
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),
                ],
              ),
            ),
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
  bool _isLoading = false;
  String? _errorMessage;

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
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    } else {
      setState(() {});
    }
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

  Future<void> _sendOtp() async {
    if (_isLoading) return;
    final mobile = _mobileController.text.trim();

    if (mobile.isEmpty) {
      RaniAlert.warning(
        context,
        'Please enter your 10-digit mobile number.',
        title: 'Mobile Required',
      );
      return;
    }

    if (mobile.length != 10) {
      RaniAlert.warning(
        context,
        'Please enter a valid 10-digit Indian mobile number.',
        title: 'Invalid Mobile Number',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiService.instance.sendOtp(mobile);
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (res['success'] == true) {
        setState(() {
          _otpSent = true;
          _errorMessage = null;
        });
        _startTimer();
        RaniAlert.success(
          context,
          'Verification code sent to +91 $mobile',
          title: 'OTP Sent',
        );
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _otp1Focus.requestFocus();
        });
      } else {
        final msg = res['message'] ?? 'Mobile number not registered.';
        setState(() {
          _errorMessage = msg;
        });
        final isNotRegistered = msg.toLowerCase().contains('not registered') ||
            msg.toLowerCase().contains('not found') ||
            msg.toLowerCase().contains('candidate');
        RaniAlert.error(
          context,
          msg,
          title: 'Login Failed',
          actionLabel: isNotRegistered ? 'Register' : null,
          onAction: isNotRegistered
              ? () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const RaniRegisterScreen(),
                    ),
                  );
                }
              : null,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Connection error: $e';
      });
      RaniAlert.error(
        context,
        'Unable to connect to server. Please check your internet connection.',
        title: 'Network Error',
      );
    }
  }

  Future<void> _verifyAndLogin() async {
    if (_isLoading) return;
    final otp = '${_otp1Controller.text}${_otp2Controller.text}${_otp3Controller.text}${_otp4Controller.text}';
    final mobile = _mobileController.text.trim();

    if (otp.length != 4) {
      RaniAlert.warning(
        context,
        'Please enter the complete 4-digit verification code.',
        title: 'OTP Incomplete',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiService.instance.verifyOtp(mobile, otp);
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (res['success'] == true) {
        RaniAlert.success(
          context,
          'Welcome back to Rani Matrimonial!',
          title: 'Login Successful',
        );
        Navigator.of(context).pop();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const RaniMainNavigationScreen(),
          ),
        );
      } else {
        final msg = res['message'] ?? 'Invalid OTP code. Please try again.';
        setState(() {
          _errorMessage = msg;
        });
        RaniAlert.error(
          context,
          msg,
          title: 'Verification Failed',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Connection error: $e';
      });
      RaniAlert.error(
        context,
        'Connection failed during verification. Please try again.',
        title: 'Network Error',
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
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFFB91C1C)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _errorMessage!,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFB91C1C),
                        ),
                      ),
                      if (_errorMessage!.contains('not registered')) ...[
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: widget.onNavigateToRegister,
                          child: Text(
                            'Tap here to Create Profile',
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF991B1B),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Send OTP Action Button
        GestureDetector(
          onTap: _isLoading ? null : _sendOtp,
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
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Color(0xFF3B0000),
                        strokeWidth: 2.2,
                      ),
                    )
                  : Row(
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
                  onTap: _isLoading ? null : _sendOtp,
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

        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFFB91C1C)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFB91C1C),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Verify & Login Button (Radiant Gold Pill)
        GestureDetector(
          onTap: _isLoading ? null : _verifyAndLogin,
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
