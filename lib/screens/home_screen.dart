import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../components/rani_alert.dart';
import '../components/rani_matrimonial_loader.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

/// Temporary Home Screen with a clean, functional Logout button
/// Allows the user to verify login/registration sessions and safely log out.
class RaniHomeScreen extends StatefulWidget {
  const RaniHomeScreen({super.key});

  @override
  State<RaniHomeScreen> createState() => _RaniHomeScreenState();
}

class _RaniHomeScreenState extends State<RaniHomeScreen> {
  bool _isLoggingOut = false;

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF26121B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFD4A034), width: 1.2),
        ),
        title: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFE5B842), Color(0xFFC59424)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE5B842).withValues(alpha: 0.35),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: const Icon(
                Icons.logout_rounded,
                size: 28,
                color: Color(0xFF3B0000),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Confirm Logout',
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to log out of your Rani Matrimonial account?',
          style: GoogleFonts.outfit(
            color: Colors.white.withValues(alpha: 0.88),
            fontSize: 14,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.outfit(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5B842),
                    foregroundColor: const Color(0xFF3B0000),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(
                    'Logout',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;
    if (!mounted) return;

    setState(() => _isLoggingOut = true);
    RaniMatrimonialLoader.show(context, message: 'Logging out safely...');

    try {
      await ApiService.instance.logout();
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      if (mounted) {
        RaniMatrimonialLoader.hide(context);
        setState(() => _isLoggingOut = false);

        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const RaniLoginScreen()),
          (route) => false,
        );

        RaniAlert.success(
          context,
          'You have been logged out successfully.',
          title: 'Logged Out',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final candidate = ApiService.instance.candidate;
    final String candidateName = candidate?['first_name']?.toString() ??
        candidate?['full_name']?.toString() ??
        'Royal Member';
    final String candidateCode = candidate?['candidate_code']?.toString() ??
        candidate?['profile_id']?.toString() ??
        '';

    return Scaffold(
      backgroundColor: const Color(0xFF2A0202),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E0101),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Rani Matrimonial',
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFFE5B842),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout_rounded,
              color: Color(0xFFE5B842),
              size: 22,
            ),
            tooltip: 'Logout',
            onPressed: _isLoggingOut ? null : _handleLogout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Custom Matrimonial Interlocking Rings Loader / Animation
                const RaniMatrimonialLoader(size: 96),
                const SizedBox(height: 28),

                // Welcome Greeting Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                  decoration: BoxDecoration(
                    color: const Color(0x384E342E),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFD4A034).withValues(alpha: 0.45),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Welcome, $candidateName',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (candidateCode.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5B842).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE5B842).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            'ID: $candidateCode',
                            style: GoogleFonts.sourceCodePro(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFE5B842),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Text(
                        'Your account is active and verified.\nFull home feed & matching screens will be designed soon.',
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.75),
                          height: 1.45,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // Prominent Logout Button
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE5B842), Color(0xFFC79224)],
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.45),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(26),
                      onTap: _isLoggingOut ? null : _handleLogout,
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.logout_rounded,
                              color: Color(0xFF3B0000),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Logout',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF3B0000),
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
        ),
      ),
    );
  }
}
