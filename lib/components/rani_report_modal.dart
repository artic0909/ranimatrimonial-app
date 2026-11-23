import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'rani_alert.dart';
import 'rani_matrimonial_loader.dart';

/// In-App Report Profile & Child Safety Feedback Modal
/// Meets Google Play Child Safety Standards Policy requirements:
/// "Provide an in-app mechanism for user feedback and reporting without leaving the app"
class RaniReportModal {
  static void show(
    BuildContext context, {
    required String candidateId,
    required String candidateCode,
    required String candidateName,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ReportModalContent(
        candidateId: candidateId,
        candidateCode: candidateCode,
        candidateName: candidateName,
      ),
    );
  }
}

class _ReportModalContent extends StatefulWidget {
  final String candidateId;
  final String candidateCode;
  final String candidateName;

  const _ReportModalContent({
    required this.candidateId,
    required this.candidateCode,
    required this.candidateName,
  });

  @override
  State<_ReportModalContent> createState() => _ReportModalContentState();
}

class _ReportModalContentState extends State<_ReportModalContent> {
  final TextEditingController _detailsCtrl = TextEditingController();

  final List<Map<String, dynamic>> _reasons = [
    {
      'title': 'Child Safety / Underage Account (CSAE)',
      'subtitle': 'Zero-tolerance prohibition of minors and CSAE/CSAM',
      'icon': CupertinoIcons.shield_slash_fill,
      'is_urgent': true,
    },
    {
      'title': 'Inappropriate Photos or Content',
      'subtitle': 'Nudity, vulgarity, or obscene media',
      'icon': CupertinoIcons.photo_fill_on_rectangle_fill,
      'is_urgent': false,
    },
    {
      'title': 'Harassment or Abusive Behavior',
      'subtitle': 'Offensive language, stalking, or threats',
      'icon': CupertinoIcons.exclamationmark_bubble_fill,
      'is_urgent': false,
    },
    {
      'title': 'Fake Profile or Impersonation',
      'subtitle': 'Stolen photos, false identity, or fraudulent details',
      'icon': CupertinoIcons.person_badge_minus_fill,
      'is_urgent': false,
    },
    {
      'title': 'Commercial Scam or Dating Misuse',
      'subtitle': 'Money requests, business promotions, or non-matrimonial use',
      'icon': CupertinoIcons.money_dollar_circle_fill,
      'is_urgent': false,
    },
    {
      'title': 'Other Concern / In-App Feedback',
      'subtitle': 'Other safety issues or concerns to flag for admin',
      'icon': CupertinoIcons.flag_fill,
      'is_urgent': false,
    },
  ];

  int _selectedReasonIndex = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _detailsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    final selectedReason = _reasons[_selectedReasonIndex]['title'] as String;
    final details = _detailsCtrl.text.trim();

    setState(() => _isSubmitting = true);
    RaniMatrimonialLoader.show(context, message: 'Submitting safety report...');

    try {
      final res = await ApiService.instance.reportCandidate(
        candidateId: widget.candidateId,
        reason: selectedReason,
        details: details.isNotEmpty ? details : null,
      );

      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);
      setState(() => _isSubmitting = false);

      if (res['success'] == true) {
        Navigator.pop(context); // Close bottom sheet
        RaniAlert.success(
          context,
          'Your report has been received by our Trust & Safety Team. We review all reports within 24 hours.',
          title: 'Report Received',
        );
      } else {
        RaniAlert.error(context, res['message'] ?? 'Failed to submit report.');
      }
    } catch (e) {
      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);
      setState(() => _isSubmitting = false);
      RaniAlert.error(context, 'Network error. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF7F2),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFD6CBC0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC62828).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      CupertinoIcons.shield_fill,
                      color: Color(0xFFC62828),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Report Profile / Feedback',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF262626),
                          ),
                        ),
                        Text(
                          'Reporting ${widget.candidateName} (${widget.candidateCode})',
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            color: const Color(0xFF750000),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(CupertinoIcons.xmark_circle_fill, color: Colors.black38),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 0.8, color: Color(0xFFEADCCF)),

            // Policy Notice Banner
            Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFEEBA)),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.info_circle_fill, color: Color(0xFF856404), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Rani Matrimonial strictly enforces zero-tolerance for Child Sexual Abuse and Exploitation (CSAE) and minors.',
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        color: const Color(0xFF856404),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Options List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  Text(
                    'Select a reason for this report:',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4A4A4A),
                    ),
                  ),
                  const SizedBox(height: 8),

                  ...List.generate(_reasons.length, (i) {
                    final item = _reasons[i];
                    final isSelected = _selectedReasonIndex == i;
                    final isUrgent = item['is_urgent'] == true;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedReasonIndex = i),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isUrgent
                                  ? const Color(0xFFFFEBEE)
                                  : const Color(0xFFFFF8E1))
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? (isUrgent ? const Color(0xFFD32F2F) : const Color(0xFFD4AF37))
                                : const Color(0xFFE8DFD5),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item['icon'] as IconData,
                              size: 20,
                              color: isSelected
                                  ? (isUrgent ? const Color(0xFFD32F2F) : const Color(0xFF8D6E63))
                                  : Colors.black45,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title'] as String,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13.5,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                      color: isSelected
                                          ? (isUrgent ? const Color(0xFFB71C1C) : const Color(0xFF424242))
                                          : const Color(0xFF333333),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item['subtitle'] as String,
                                    style: GoogleFonts.outfit(
                                      fontSize: 11.5,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              isSelected
                                  ? CupertinoIcons.check_mark_circled_solid
                                  : CupertinoIcons.circle,
                              color: isSelected
                                  ? (isUrgent ? const Color(0xFFD32F2F) : const Color(0xFFD4AF37))
                                  : Colors.black26,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 8),
                  Text(
                    'Additional Details (Optional):',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4A4A4A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _detailsCtrl,
                    maxLines: 3,
                    style: GoogleFonts.outfit(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Describe what happened or why you are reporting this profile...',
                      hintStyle: GoogleFonts.outfit(fontSize: 12.5, color: Colors.black38),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE8DFD5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE8DFD5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF750000), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Submit Button
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEADCCF), width: 0.8)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF750000),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  icon: const Icon(CupertinoIcons.flag_fill, size: 18),
                  label: Text(
                    'Submit Safety Report',
                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
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
