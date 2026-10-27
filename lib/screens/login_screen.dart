import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/rani_colors.dart';
import '../theme/rani_spacing.dart';
import '../theme/rani_typography.dart';
import 'register_screen.dart';
import 'main_navigation_screen.dart';
import '../services/api_service.dart';
import '../components/rani_alert.dart';

/// Screen: Opulent Mobile + 4-Digit OTP Login Screen
/// Features:
/// - Brand crest & header
/// - Mode Switcher: Mobile OTP vs Email/Profile ID
/// - Single-layer Oyster/Beige mobile input with +91 country badge
/// - Smooth transition to 4-Digit OTP entry upon sending code
/// - Eye-catchy 4-digit OTP cards with glowing gold borders and zero theme leakage
/// - Resend OTP timer
/// - "Create Profile" link navigating directly to RaniRegisterScreen
class RaniLoginScreen extends StatefulWidget {
  const RaniLoginScreen({super.key});

  @override
  State<RaniLoginScreen> createState() => _RaniLoginScreenState();
}

class _RaniLoginScreenState extends State<RaniLoginScreen> {
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
          onAction: isNotRegistered ? () => _navigateToCreateProfile() : null,
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

  void _navigateToCreateProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RaniRegisterScreen(),
      ),
    );
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
    // Insulate against global inputDecorationTheme so no unwanted inner borders appear!
    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: const InputDecorationTheme(),
      ),
      child: Scaffold(
        backgroundColor: RaniColors.canvas,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: RaniColors.ink, size: 18),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: RaniSpacing.screenPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: RaniSpacing.xs),

                      // Brand Crest & Header
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: RaniColors.gold.withValues(alpha: 0.35),
                                    blurRadius: 18,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/logo.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: RaniColors.primary,
                                    child: const Icon(
                                      Icons.favorite,
                                      color: RaniColors.gold,
                                      size: 34,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: RaniSpacing.sm),
                            Text(
                              _otpSent ? 'Verify OTP' : 'Welcome Back',
                              style: RaniTypography.headingLg(color: RaniColors.ink).copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 24,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _otpSent
                                  ? 'Enter 4-digit code sent to +91 ${_mobileController.text}'
                                  : 'Enter your mobile number to receive a 4-digit OTP',
                              style: RaniTypography.bodySm(color: RaniColors.textMuted),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: RaniSpacing.xl),

                      // Animated View: Mobile Number vs 4-Digit OTP
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _otpSent ? _buildOtpSection() : _buildMobileSection(),
                      ),
                    ],
                  ),
                ),
              ),

              // Prominent "Create Profile" Bottom Section
              _buildBottomCreateProfileSection(),
            ],
          ),
        ),
      ),
    );
  }

  /// Step 1: Mobile Number Input ONLY (No Tabs)
  Widget _buildMobileSection() {
    final isMobileValid = _mobileController.text.trim().length == 10;

    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            'Mobile Number',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: RaniColors.ink,
            ),
          ),
        ),

        // Single Clean Unified Mobile Input with +91 Badge Matching Registration Style
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
                          onTap: _navigateToCreateProfile,
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

        // Send OTP Button
        GestureDetector(
          onTap: _isLoading ? null : _sendOtp,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 50,
            decoration: BoxDecoration(
              gradient: isMobileValid
                  ? const LinearGradient(
                      colors: [Color(0xFFE5B842), Color(0xFFC79224)],
                    )
                  : null,
              color: isMobileValid ? null : const Color(0xFFDDD5CC),
              borderRadius: BorderRadius.circular(26),
              boxShadow: isMobileValid
                  ? [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.45),
                        blurRadius: 14,
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
                    'Send OTP',
                    style: GoogleFonts.outfit(
                      color: isMobileValid
                          ? const Color(0xFF3B0000)
                          : const Color(0xFF8C7972),
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
      ],
    );
  }

  /// Step 2: Ultra Eye-Catchy 4-Digit OTP View
  Widget _buildOtpSection() {
    final otp = '${_otp1Controller.text}${_otp2Controller.text}${_otp3Controller.text}${_otp4Controller.text}';
    final isOtpValid = otp.length == 4;

    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sent Number badge with Edit link
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
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2C140E),
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
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF881337),
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
            _buildOtpDigitBox(controller: _otp1Controller, focusNode: _otp1Focus, nextFocus: _otp2Focus),
            const SizedBox(width: 12),
            _buildOtpDigitBox(controller: _otp2Controller, focusNode: _otp2Focus, nextFocus: _otp3Focus, prevFocus: _otp1Focus),
            const SizedBox(width: 12),
            _buildOtpDigitBox(controller: _otp3Controller, focusNode: _otp3Focus, nextFocus: _otp4Focus, prevFocus: _otp2Focus),
            const SizedBox(width: 12),
            _buildOtpDigitBox(controller: _otp4Controller, focusNode: _otp4Focus, prevFocus: _otp3Focus),
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

        const SizedBox(height: 24),

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
              borderRadius: BorderRadius.circular(26),
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
                      color: isOtpValid
                          ? const Color(0xFF3B0000)
                          : const Color(0xFF8C7972),
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
      ],
    );
  }

  /// Single Digit Card matching the eye-catchy styling
  Widget _buildOtpDigitBox({
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

  /// Prominently and attractively designed "Create Profile" bottom section
  Widget _buildBottomCreateProfileSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border(
          top: BorderSide(
            color: RaniColors.gold.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: RaniColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.stars,
                    color: RaniColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New to Rani Matrimonial?',
                        style: RaniTypography.caption(color: RaniColors.textMuted).copyWith(
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Find your soulmate today',
                        style: RaniTypography.labelMd(color: RaniColors.ink).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE5B842), Color(0xFFC79224)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _navigateToCreateProfile,
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.person_add_alt_1_outlined,
                          color: Color(0xFF3B0000),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Create Profile — Free Registration',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF3B0000),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
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
}
