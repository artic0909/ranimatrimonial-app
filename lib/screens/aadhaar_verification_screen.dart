import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../components/rani_alert.dart';
import 'main_navigation_screen.dart';

/// Screen: Government Document / Aadhaar Verification (Matching website bluetick_verification.blade.php)
/// Allows candidate to verify their identity with Aadhaar front & back photos to earn the Blue Tick badge.
class RaniAadhaarVerificationScreen extends StatefulWidget {
  final String? prefilledAadhar;

  const RaniAadhaarVerificationScreen({
    super.key,
    this.prefilledAadhar,
  });

  @override
  State<RaniAadhaarVerificationScreen> createState() => _RaniAadhaarVerificationScreenState();
}

class _RaniAadhaarVerificationScreenState extends State<RaniAadhaarVerificationScreen> {
  final TextEditingController _aadharController = TextEditingController();
  File? _frontFile;
  File? _backFile;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledAadhar != null && widget.prefilledAadhar!.isNotEmpty) {
      _aadharController.text = _formatAadhar(widget.prefilledAadhar!);
    } else if (ApiService.instance.candidate?['aadhar_number'] != null) {
      _aadharController.text = _formatAadhar(ApiService.instance.candidate!['aadhar_number'].toString());
    }
  }

  @override
  void dispose() {
    _aadharController.dispose();
    super.dispose();
  }

  String _formatAadhar(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 12; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  Future<void> _pickDocumentImage({required bool isFront}) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isFront ? 'Upload Aadhaar Front Side' : 'Upload Aadhaar Back Side',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(CupertinoIcons.camera, color: Color(0xFF750000)),
                title: Text('Take Photo with Camera', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picker = ImagePicker();
                  try {
                    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                    if (picked != null) {
                      setState(() {
                        if (isFront) {
                          _frontFile = File(picked.path);
                        } else {
                          _backFile = File(picked.path);
                        }
                      });
                    }
                  } catch (_) {
                    // Fallback to gallery if camera is unavailable
                    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                    if (picked != null) {
                      setState(() {
                        if (isFront) {
                          _frontFile = File(picked.path);
                        } else {
                          _backFile = File(picked.path);
                        }
                      });
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.photo, color: Color(0xFF750000)),
                title: Text('Choose from Gallery', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                  if (picked != null) {
                    setState(() {
                      if (isFront) {
                        _frontFile = File(picked.path);
                      } else {
                        _backFile = File(picked.path);
                      }
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _proceedToMatches() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const RaniMainNavigationScreen(initialIndex: 1), // Index 1 is Matches!
      ),
      (route) => false,
    );
  }

  Future<void> _submitVerification() async {
    final cleanAadhar = _aadharController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanAadhar.length != 12) {
      RaniAlert.warning(
        context,
        'Please enter a valid 12-digit Aadhaar card number.',
        title: 'Aadhaar Required',
      );
      return;
    }

    if (_frontFile == null || _backFile == null) {
      RaniAlert.warning(
        context,
        'Please upload both Front and Back photos of your Aadhaar card.',
        title: 'Documents Required',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final res = await ApiService.instance.submitBlueTickVerification(
        aadharNumber: cleanAadhar,
        frontFile: _frontFile!,
        backFile: _backFile!,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (res['success'] == true) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E88E5).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(CupertinoIcons.checkmark_seal_fill, color: Color(0xFF1E88E5), size: 34),
                ),
                const SizedBox(height: 12),
                Text(
                  'Verification Submitted!',
                  style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: Text(
              'Your Aadhaar documents are now under review. You will receive an SMS and WhatsApp notification once approved.\n\nNow exploring your best matrimonial matches!',
              style: GoogleFonts.outfit(fontSize: 13.5, color: const Color(0xFF555555), height: 1.4),
              textAlign: TextAlign.center,
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF750000),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _proceedToMatches();
                  },
                  child: const Text('View Matches'),
                ),
              ),
            ],
          ),
        );
      } else {
        RaniAlert.error(
          context,
          res['message'] ?? 'Failed to submit verification. Please try again.',
          title: 'Verification Failed',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      RaniAlert.error(context, 'Error submitting documents: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF7F2),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Document Verification',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2B0A0D),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _proceedToMatches,
            child: Text(
              'Skip for Now',
              style: GoogleFonts.outfit(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF750000),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Blue Tick Hero Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8F1FC), Color(0xFFF0F6FD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFBBDEFB)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1976D2),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1976D2).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(CupertinoIcons.checkmark_seal_fill, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Earn Your Blue Tick Badge',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0D47A1),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Verify with your Government Aadhaar card to establish 100% trust and receive up to 2x more connection responses.',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: const Color(0xFF1565C0),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Step 1: Aadhaar Number Field
              _buildStepCard(
                stepNumber: '1',
                title: 'Confirm 12-Digit Aadhaar Number',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBF8F4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDED5C9)),
                      ),
                      child: TextField(
                        controller: _aadharController,
                        keyboardType: TextInputType.number,
                        maxLength: 14,
                        style: GoogleFonts.robotoMono(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.0,
                          color: const Color(0xFF1E1E1E),
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: 'XXXX XXXX XXXX',
                          hintStyle: GoogleFonts.robotoMono(
                            fontSize: 15,
                            letterSpacing: 2.0,
                            color: const Color(0xFFAAAAAA),
                          ),
                          prefixIcon: const Icon(CupertinoIcons.creditcard, color: Color(0xFF750000), size: 18),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        onChanged: (val) {
                          final formatted = _formatAadhar(val);
                          if (formatted != val) {
                            _aadharController.value = TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(offset: formatted.length),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Step 2: Front Side Photo Upload
              _buildStepCard(
                stepNumber: '2',
                title: 'Upload Front Side of Aadhaar Card',
                child: _buildUploadBox(
                  file: _frontFile,
                  label: 'Front Side Photo',
                  onTap: () => _pickDocumentImage(isFront: true),
                  onRemove: () => setState(() => _frontFile = null),
                ),
              ),

              const SizedBox(height: 16),

              // Step 3: Back Side Photo Upload
              _buildStepCard(
                stepNumber: '3',
                title: 'Upload Back Side of Aadhaar Card',
                child: _buildUploadBox(
                  file: _backFile,
                  label: 'Back Side Photo',
                  onTap: () => _pickDocumentImage(isFront: false),
                  onRemove: () => setState(() => _backFile = null),
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF750000),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _submitVerification,
                  child: _isSubmitting
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(CupertinoIcons.shield_lefthalf_fill, size: 18),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Submit Aadhaar for Verification',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
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
    );
  }

  Widget _buildStepCard({
    required String stepNumber,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DFD5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Color(0xFF750000),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  stepNumber,
                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1E1E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildUploadBox({
    required File? file,
    required String label,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    if (file != null) {
      return Stack(
        children: [
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: FileImage(file),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black87,
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.clear, size: 14, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(CupertinoIcons.checkmark_circle_fill, color: Color(0xFF4CAF50), size: 12),
                  const SizedBox(width: 4),
                  Text(
                    'Photo Attached',
                    style: GoogleFonts.outfit(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFAF7F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDED5C9), style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.arrow_up_doc_fill, size: 28, color: Color(0xFF750000)),
            const SizedBox(height: 6),
            Text(
              'Tap to upload $label',
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF750000),
              ),
            ),
            Text(
              'Camera or Gallery (JPG, PNG)',
              style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF888888)),
            ),
          ],
        ),
      ),
    );
  }
}
