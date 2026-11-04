import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../components/rani_alert.dart';
import '../../components/rani_matrimonial_loader.dart';
import '../splash_screen.dart';

/// Screen: Delete Account Request
/// Allows candidate to submit an account deletion request with reason.
/// Saved in database and reviewed by administrators.
class RaniDeleteAccountRequestScreen extends StatefulWidget {
  final bool showAppBar;
  const RaniDeleteAccountRequestScreen({super.key, this.showAppBar = true});

  @override
  State<RaniDeleteAccountRequestScreen> createState() => _RaniDeleteAccountRequestScreenState();
}

class _RaniDeleteAccountRequestScreenState extends State<RaniDeleteAccountRequestScreen> {
  final _reasonCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSubmitting = false;

  Map<String, dynamic>? _existingRequest;

  final List<String> _suggestedReasons = [
    'Found my partner on Rani Matrimonial',
    'Engaged or Married elsewhere',
    'Taking a temporary break',
    'Privacy or personal reasons',
    'Not satisfied with matches',
    'Other reason',
  ];

  String? _selectedSuggestion;

  @override
  void initState() {
    super.initState();
    _checkExistingRequest();
  }

  Future<void> _checkExistingRequest() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.instance.getDeleteAccountRequest();
      if (!mounted) return;

      if (res['success'] == true && res['has_request'] == true) {
        setState(() {
          _existingRequest = res['request'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmAndSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final reason = _reasonCtrl.text.trim();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFD32F2F).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(CupertinoIcons.trash_fill, color: Color(0xFFD32F2F), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Confirm Deletion',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: const Color(0xFF1E1E1E),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to request account deletion?\n\nYour profile will immediately be deactivated and hidden from searches while the administrator reviews your request.',
          style: GoogleFonts.outfit(
            fontSize: 13.5,
            color: const Color(0xFF555555),
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF6B6B6B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF750000),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(
                    'Yes, Submit',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (!mounted || confirm != true) return;

    RaniMatrimonialLoader.show(context, message: 'Submitting deletion request...');
    setState(() => _isSubmitting = true);

    try {
      final res = await ApiService.instance.submitDeleteAccountRequest(reason);
      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);
      setState(() => _isSubmitting = false);

      if (res['success'] == true) {
        if (!mounted) return;
        final navigator = Navigator.of(context);
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 24),
                const SizedBox(width: 10),
                Text(
                  'Request Submitted',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18),
                ),
              ],
            ),
            content: Text(
              res['message'] ?? 'Your account deletion request has been submitted successfully and your profile is now deactivated.',
              style: GoogleFonts.outfit(fontSize: 13.5, color: const Color(0xFF444444), height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await ApiService.instance.logout();
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const RaniSplashScreen()),
                    (route) => false,
                  );
                },
                child: Text(
                  'Log Out',
                  style: GoogleFonts.outfit(color: const Color(0xFF750000), fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      } else {
        RaniAlert.error(context, res['message'] ?? 'Failed to submit deletion request.');
      }
    } catch (e) {
      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);
      setState(() => _isSubmitting = false);
      RaniAlert.error(context, 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: const Color(0xFF630008),
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(CupertinoIcons.back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Delete My Account',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            )
          : null,
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator(radius: 14))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Existing Active Request Card
                  if (_existingRequest != null) ...[
                    _buildExistingRequestCard(),
                    const SizedBox(height: 20),
                  ],

                  // Notice & Warning Card
                  _buildWarningCard(),
                  const SizedBox(height: 20),

                  // Reason Input Form
                  _buildReasonForm(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildExistingRequestCard() {
    final status = (_existingRequest?['status'] ?? 'pending').toString().toLowerCase();
    final date = _existingRequest?['created_at']?.toString() ?? 'Recently';
    final reason = _existingRequest?['reason']?.toString() ?? '';

    Color statusColor = const Color(0xFFE65100);
    String statusTitle = 'Pending Admin Review';
    if (status == 'approved') {
      statusColor = const Color(0xFFD32F2F);
      statusTitle = 'Approved for Deletion';
    } else if (status == 'rejected') {
      statusColor = const Color(0xFF757575);
      statusTitle = 'Request Rejected';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(CupertinoIcons.clock_fill, color: statusColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    statusTitle,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'You previously requested account deletion. Your profile is currently hidden from matchmaking search.',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: const Color(0xFF555555),
              height: 1.35,
            ),
          ),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F6F0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEFE8DE)),
              ),
              child: Text(
                'Reason: "$reason"',
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF444444),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Submitted on $date',
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: const Color(0xFF999999),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.exclamationmark_triangle_fill,
                  color: Color(0xFFD32F2F),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'What happens when you request deletion?',
                  style: GoogleFonts.outfit(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF8B0000),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBulletPoint('Your profile will be hidden immediately from all candidate search and recommendation feeds.'),
          _buildBulletPoint('Pending connection requests and chats will no longer be accessible.'),
          _buildBulletPoint('Your account deletion request will be permanently recorded in database and verified by admin.'),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFFD32F2F), fontSize: 16, height: 1.2)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: const Color(0xFF555555),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFE8DE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please tell us why you are leaving',
              style: GoogleFonts.playfairDisplay(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your honest feedback helps us improve Rani Matrimonial for everyone.',
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                color: const Color(0xFF777777),
              ),
            ),
            const SizedBox(height: 16),

            // Quick suggestion chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _suggestedReasons.map((sug) {
                final isSel = _selectedSuggestion == sug;
                return ChoiceChip(
                  label: Text(sug),
                  labelStyle: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                    color: isSel ? const Color(0xFF750000) : const Color(0xFF444444),
                  ),
                  selected: isSel,
                  selectedColor: const Color(0xFF750000).withValues(alpha: 0.12),
                  backgroundColor: const Color(0xFFF7F5F0),
                  side: BorderSide(
                    color: isSel ? const Color(0xFF750000) : const Color(0xFFE4DAD0),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedSuggestion = sug;
                        _reasonCtrl.text = sug;
                      } else {
                        _selectedSuggestion = null;
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Detailed Reason Input Field
            Text(
              'Reason / Feedback *',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _reasonCtrl,
              maxLines: 4,
              style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF222222)),
              decoration: InputDecoration(
                hintText: 'Please describe the reason for deleting your account...',
                hintStyle: GoogleFonts.outfit(fontSize: 13.5, color: const Color(0xFFAAAAAA)),
                filled: true,
                fillColor: const Color(0xFFFDFBF7),
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE4DAD0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE4DAD0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF750000), width: 1.4),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().length < 5) {
                  return 'Please enter at least 5 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 22),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF750000),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: _isSubmitting ? null : _confirmAndSubmit,
                icon: const Icon(CupertinoIcons.paperplane_fill, size: 17, color: Color(0xFFF3C05D)),
                label: Text(
                  'Submit Deletion Request',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
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
