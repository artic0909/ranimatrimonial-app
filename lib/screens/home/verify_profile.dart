import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/api_service.dart';
import '../../components/rani_alert.dart';
import '../../components/rani_matrimonial_loader.dart';

/// Screen: Government Document / Aadhaar Verification (Blue Tick)
class RaniVerifyProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? initialBluetick;

  const RaniVerifyProfileScreen({
    super.key,
    this.initialBluetick,
  });

  @override
  State<RaniVerifyProfileScreen> createState() => _RaniVerifyProfileScreenState();
}

class _RaniVerifyProfileScreenState extends State<RaniVerifyProfileScreen> {
  final TextEditingController _aadharController = TextEditingController();
  File? _frontFile;
  File? _backFile;
  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _bluetickData;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final candidate = ApiService.instance.candidate;
    if (candidate != null && candidate['aadhar_number'] != null) {
      _aadharController.text = _formatAadhar(candidate['aadhar_number'].toString());
    }

    try {
      final res = await ApiService.instance.showBlueTickVerification();
      if (mounted && res['success'] == true) {
        setState(() {
          _bluetickData = res['bluetick'];
          if (res['candidate']?['aadhar_number'] != null) {
            _aadharController.text = _formatAadhar(res['candidate']['aadhar_number'].toString());
          }
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isFront ? 'Upload Aadhaar Front Side' : 'Upload Aadhaar Back Side',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(CupertinoIcons.camera_fill, color: Color(0xFF750000)),
                title: Text('Take Photo with Camera', style: GoogleFonts.outfit(fontSize: 14)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final status = await Permission.camera.request();
                  if (status.isGranted) {
                    final picker = ImagePicker();
                    final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                    if (photo != null) {
                      setState(() {
                        if (isFront) {
                          _frontFile = File(photo.path);
                        } else {
                          _backFile = File(photo.path);
                        }
                      });
                    }
                  } else {
                    if (mounted) {
                      RaniAlert.warning(context, 'Camera permission is required to take photo.');
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.photo_fill, color: Color(0xFF750000)),
                title: Text('Choose from Gallery', style: GoogleFonts.outfit(fontSize: 14)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picker = ImagePicker();
                  final photo = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                  if (photo != null) {
                    setState(() {
                      if (isFront) {
                        _frontFile = File(photo.path);
                      } else {
                        _backFile = File(photo.path);
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

  Future<void> _submitVerification() async {
    final cleanAadhar = _aadharController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanAadhar.length != 12) {
      RaniAlert.warning(context, 'Please enter a valid 12-digit Aadhaar number.');
      return;
    }

    if (_frontFile == null || _backFile == null) {
      RaniAlert.warning(context, 'Please upload both Front and Back photos of your Aadhaar card.');
      return;
    }

    setState(() => _isSubmitting = true);
    RaniMatrimonialLoader.show(context, message: 'Submitting verification documents...');

    try {
      final res = await ApiService.instance.submitBlueTickVerification(
        aadharNumber: cleanAadhar,
        frontFile: _frontFile!,
        backFile: _backFile!,
      );

      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);
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
              'Your Aadhaar documents are now under review. You will receive an SMS and in-app notification once approved by admin.\n\nReturning to Home...',
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
                    Navigator.pop(context, true); // Pop back to Home with true to trigger refresh!
                  },
                  child: const Text('Back to Home'),
                ),
              ),
            ],
          ),
        );
      } else {
        RaniAlert.error(context, res['message'] ?? 'Failed to submit verification.');
      }
    } catch (e) {
      RaniMatrimonialLoader.hide(context);
      setState(() => _isSubmitting = false);
      if (mounted) {
        RaniAlert.error(context, 'Error submitting documents: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _bluetickData?['status'] ??
        (_bluetickData != null
            ? ((_bluetickData!['is_accept'] == 1 || _bluetickData!['is_accept'] == '1')
                ? 'verified'
                : 'pending')
            : 'not_submitted');

    final isVerified = status == 'verified' || ApiService.instance.candidate?['verified'] == true;
    final isPending = status == 'pending';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Color(0xFF750000)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Aadhaar Verification',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E1E1E)),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF750000)))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Status Banner
                if (isVerified)
                  _buildStatusBanner(
                    color: const Color(0xFF2E7D32),
                    icon: CupertinoIcons.checkmark_seal_fill,
                    title: 'Your Account is Verified!',
                    description: 'Congratulations! Your Blue Tick verification has been approved by admin.',
                  )
                else if (isPending)
                  _buildStatusBanner(
                    color: const Color(0xFFD97706),
                    icon: CupertinoIcons.clock_fill,
                    title: 'Verification Under Review',
                    description: 'Your Aadhaar documents have been submitted and are waiting for admin approval.',
                  )
                else
                  _buildHeaderCard(),

                const SizedBox(height: 20),

                // Aadhaar Number Input
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEFE8DE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aadhaar Card Number',
                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF333333)),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _aadharController,
                        enabled: !isVerified && !isPending,
                        keyboardType: TextInputType.number,
                        maxLength: 14,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E1E1E),
                        ),
                        decoration: InputDecoration(
                          hintText: 'XXXX XXXX XXXX',
                          counterText: '',
                          prefixIcon: const Icon(Icons.credit_card_rounded, color: Color(0xFF750000)),
                          filled: true,
                          fillColor: const Color(0xFFFAF7F2),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE8DFD5)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE8DFD5)),
                          ),
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
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Upload Documents Section
                if (!isVerified && !isPending) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _buildDocUploadBox(
                          label: 'Aadhaar Front',
                          file: _frontFile,
                          onTap: () => _pickDocumentImage(isFront: true),
                          onRemove: () => setState(() => _frontFile = null),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildDocUploadBox(
                          label: 'Aadhaar Back',
                          file: _backFile,
                          onTap: () => _pickDocumentImage(isFront: false),
                          onRemove: () => setState(() => _backFile = null),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF750000),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _isSubmitting ? null : _submitVerification,
                      child: Text(
                        'Submit for Verification',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEFE8DE)),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          isVerified ? CupertinoIcons.checkmark_seal_fill : CupertinoIcons.hourglass,
                          size: 44,
                          color: isVerified ? const Color(0xFF2E7D32) : const Color(0xFFD97706),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isVerified ? 'Verification Active' : 'Waiting for Admin Approval',
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isVerified
                              ? 'Your profile carries the verified Blue Tick badge.'
                              : 'Admin will review your uploaded Aadhaar card shortly.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(fontSize: 12.5, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildStatusBanner({
    required Color color,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
                const SizedBox(height: 3),
                Text(description, style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF4A4A4A))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFE8DE)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF750000).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.checkmark_seal_fill, color: Color(0xFF750000), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Get Blue Tick Verified',
                  style: GoogleFonts.outfit(fontSize: 15.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  '100% verified profiles receive 5x more trust and quick responses.',
                  style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6E6E6E)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocUploadBox({
    required String label,
    required File? file,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: file != null ? const Color(0xFF750000) : const Color(0xFFE0D8CE),
                width: file != null ? 1.5 : 1.0,
              ),
            ),
            child: file != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(file, width: double.infinity, height: double.infinity, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: onRemove,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.cloud_upload, color: Color(0xFF750000), size: 28),
                      const SizedBox(height: 6),
                      Text(
                        'Upload Photo',
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF750000)),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
