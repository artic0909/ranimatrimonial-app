import 'package:flutter/material.dart';
import '../theme/rani_colors.dart';
import '../theme/rani_elevation.dart';
import '../theme/rani_spacing.dart';
import '../theme/rani_typography.dart';
import '../components/rani_buttons.dart';
import 'main_navigation_screen.dart';

/// Screen: Opulent Login Screen
/// Features:
/// - Royal brand header with crest
/// - Email/Phone/ID and Password inputs
/// - Primary Login button
/// - Prominently & beautifully presented "Create Profile" section at the bottom
class RaniLoginScreen extends StatefulWidget {
  const RaniLoginScreen({super.key});

  @override
  State<RaniLoginScreen> createState() => _RaniLoginScreenState();
}

class _RaniLoginScreenState extends State<RaniLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logging in to your matrimonial account...'),
          duration: Duration(seconds: 1),
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const RaniMainNavigationScreen(),
        ),
      );
    }
  }

  void _navigateToCreateProfile() {
    _showCreateProfileSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: RaniSpacing.xs),

                      // Brand Crest & Header
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: RaniColors.gold.withValues(alpha: 0.3),
                                    blurRadius: 16,
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
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: RaniSpacing.sm),
                            Text(
                              'Welcome Back',
                              style: RaniTypography.headingLg(color: RaniColors.ink).copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Login to connect with genuine brides & grooms',
                              style: RaniTypography.bodySm(color: RaniColors.textMuted),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: RaniSpacing.xl),

                      // Identifier Input (Email / Phone / Matrimony ID)
                      Text(
                        'Email, Phone or Matrimony ID',
                        style: RaniTypography.labelMd(color: RaniColors.ink).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: RaniSpacing.xs),
                      TextFormField(
                        controller: _identifierController,
                        style: RaniTypography.bodyMd(color: RaniColors.ink),
                        decoration: InputDecoration(
                          hintText: 'Enter your registered email or phone',
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            color: RaniColors.textMuted,
                            size: 20,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email, phone or ID';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: RaniSpacing.md),

                      // Password Input
                      Text(
                        'Password',
                        style: RaniTypography.labelMd(color: RaniColors.ink).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: RaniSpacing.xs),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: RaniTypography.bodyMd(color: RaniColors.ink),
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: RaniColors.textMuted,
                            size: 20,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: RaniColors.textMuted,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: RaniSpacing.xs),

                      // Remember Me & Forgot Password
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _rememberMe,
                                  activeColor: RaniColors.primary,
                                  onChanged: (val) {
                                    setState(() {
                                      _rememberMe = val ?? true;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Remember me',
                                style: RaniTypography.bodySm(color: RaniColors.textMuted),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Password reset instructions sent to your phone/email.'),
                                ),
                              );
                            },
                            child: Text(
                              'Forgot Password?',
                              style: RaniTypography.labelSm(color: RaniColors.primary).copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: RaniSpacing.lg),

                      // Login Button
                      RaniPrimaryButton(
                        text: 'Login',
                        onPressed: _handleLogin,
                      ),

                      const SizedBox(height: RaniSpacing.md),

                      // Quick OTP Login option
                      Center(
                        child: TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('OTP sent to your registered mobile number.'),
                              ),
                            );
                          },
                          child: Text(
                            'Login via OTP on Mobile',
                            style: RaniTypography.button(color: RaniColors.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // BOTTOM PROMINENT & BEAUTIFUL "CREATE PROFILE" CARD SECTION
            _buildBottomCreateProfileSection(),
          ],
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
              height: 44,
              decoration: BoxDecoration(
                border: Border.all(
                  color: RaniColors.gold,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: RaniElevation.sm,
              ),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: RaniColors.surfaceLight,
                  foregroundColor: RaniColors.primary,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _navigateToCreateProfile,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.person_add_alt_1_outlined,
                      color: RaniColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Create Profile — Free Registration',
                      style: RaniTypography.button(color: RaniColors.primary).copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Create Profile Bottom Sheet dialog
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
}
