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

  String get _cleanAadhar => _aadharController.text.replaceAll(RegExp(r'[^0-9]'), '');

  Future<void> _pickDocumentImage({required bool isFront}) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDD2C2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isFront ? 'Upload Aadhaar Front Side' : 'Upload Aadhaar Back Side',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2B0A0D),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isFront
                    ? 'Ensure your photo, full name, and Aadhaar number are clearly visible.'
                    : 'Ensure your complete address and QR code are clearly readable.',
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  color: const Color(0xFF7A6E65),
                ),
              ),
              const SizedBox(height: 18),
              InkWell(
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    final status = await Permission.camera.request();
                    if (status.isGranted) {
                      final picker = ImagePicker();
                      final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                      if (photo != null && mounted) {
                        setState(() {
                          if (isFront) {
                            _frontFile = File(photo.path);
                          } else {
                            _backFile = File(photo.path);
                          }
                        });
                      }
                    } else if (mounted) {
                      RaniAlert.warning(context, 'Camera permission is required to capture document.');
                    }
                  } catch (_) {
                    final picker = ImagePicker();
                    final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                    if (photo != null && mounted) {
                      setState(() {
                        if (isFront) {
                          _frontFile = File(photo.path);
                        } else {
                          _backFile = File(photo.path);
                        }
                      });
                    }
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFEFE8DE)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF750000).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(CupertinoIcons.camera_fill, color: Color(0xFF750000), size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Take Photo with Camera',
                              style: GoogleFonts.outfit(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2B0A0D),
                              ),
                            ),
                            Text(
                              'Snap a quick photo using your phone camera',
                              style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF8C7E72)),
                            ),
                          ],
                        ),
                      ),
                      const Icon(CupertinoIcons.chevron_right, size: 16, color: Color(0xFF8C7E72)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  Navigator.pop(ctx);
                  final picker = ImagePicker();
                  final photo = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                  if (photo != null && mounted) {
                    setState(() {
                      if (isFront) {
                        _frontFile = File(photo.path);
                      } else {
                        _backFile = File(photo.path);
                      }
                    });
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFEFE8DE)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(CupertinoIcons.photo_fill_on_rectangle_fill, color: Color(0xFF0284C7), size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choose from Gallery',
                              style: GoogleFonts.outfit(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2B0A0D),
                              ),
                            ),
                            Text(
                              'Select image from device storage',
                              style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF8C7E72)),
                            ),
                          ],
                        ),
                      ),
                      const Icon(CupertinoIcons.chevron_right, size: 16, color: Color(0xFF8C7E72)),
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

  void _showImagePreviewDialog(File file, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Row(
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
              child: Image.file(
                file,
                fit: BoxFit.contain,
                height: MediaQuery.of(context).size.height * 0.5,
                width: double.infinity,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitVerification() async {
    final cleanAadhar = _cleanAadhar;
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(CupertinoIcons.checkmark_seal_fill, color: Color(0xFF0284C7), size: 38),
                ),
                const SizedBox(height: 14),
                Text(
                  'Verification Submitted!',
                  style: GoogleFonts.playfairDisplay(fontSize: 21, fontWeight: FontWeight.w700, color: const Color(0xFF2B0A0D)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: Text(
              'Your Aadhaar documents have been safely submitted and are currently under review by our security team.\n\nApproval typically takes 24-48 hours. You will receive an SMS and app notification once verified.',
              style: GoogleFonts.outfit(fontSize: 13.5, color: const Color(0xFF555555), height: 1.45),
              textAlign: TextAlign.center,
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF750000),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context, true);
                  },
                  child: Text(
                    'Back to Home',
                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
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
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFAF7F2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEFE8DE)),
              ),
              child: const Icon(CupertinoIcons.back, color: Color(0xFF750000), size: 18),
            ),
          ),
        ),
        title: Text(
          'Aadhaar Verification',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2B0A0D),
          ),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFEFE8DE)),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF750000)))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                // 1. Hero Status Card
                if (isVerified)
                  _buildVerifiedCard()
                else if (isPending)
                  _buildPendingCard()
                else
                  _buildHeroHeaderCard(),

                const SizedBox(height: 16),

                // 2. Step 1: Aadhaar Number Input Card
                _buildAadharNumberCard(isVerified: isVerified, isPending: isPending),

                const SizedBox(height: 16),

                // 3. Step 2: Upload Documents Section
                if (!isVerified && !isPending) ...[
                  _buildDocUploadSection(),

                  const SizedBox(height: 16),

                  // 4. Privacy & Security Trust Banner
                  _buildPrivacySecurityCard(),

                  const SizedBox(height: 24),

                  // 5. Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF750000),
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shadowColor: const Color(0xFF750000).withValues(alpha: 0.35),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _isSubmitting ? null : _submitVerification,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(CupertinoIcons.checkmark_shield_fill, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Submit for Verification',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
    );
  }

  /// Hero Blue Tick Trust Card
  Widget _buildHeroHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0F7FF), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBAE6FD)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(CupertinoIcons.checkmark_seal_fill, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Get Blue Tick Verified',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0C4A6E),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'PRO',
                            style: GoogleFonts.outfit(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Official government ID verification earns 5x more trust & faster responses.',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: const Color(0xFF0369A1),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE0F2FE)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTrustBadge(CupertinoIcons.shield_fill, '100% Privacy'),
              _buildTrustBadge(CupertinoIcons.star_fill, 'Verified Badge'),
              _buildTrustBadge(CupertinoIcons.bolt_fill, '5x Visibility'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadge(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12.5, color: const Color(0xFF0284C7)),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0C4A6E),
          ),
        ),
      ],
    );
  }

  /// Step 1: Aadhaar Card Number Input Card
  Widget _buildAadharNumberCard({required bool isVerified, required bool isPending}) {
    final isValid12 = _cleanAadhar.length == 12;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE4D8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
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
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF750000),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '1',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Aadhaar Card Number',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2B0A0D),
                  ),
                ),
              ),
              if (isValid12)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.checkmark_alt, size: 12, color: Color(0xFF16A34A)),
                      const SizedBox(width: 3),
                      Text(
                        '12 Digits',
                        style: GoogleFonts.outfit(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Enter the 12-digit number as shown on your Aadhaar card',
            style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF7A6E65)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _aadharController,
            enabled: !isVerified && !isPending,
            keyboardType: TextInputType.number,
            maxLength: 14,
            style: GoogleFonts.outfit(
              fontSize: 18,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2B0A0D),
            ),
            decoration: InputDecoration(
              hintText: '6666 6666 6666',
              hintStyle: GoogleFonts.outfit(
                fontSize: 18,
                letterSpacing: 2.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFB0A499),
              ),
              counterText: '',
              prefixIcon: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Icon(Icons.credit_card_rounded, color: Color(0xFF750000), size: 22),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 46, minHeight: 46),
              suffixIcon: isValid12
                  ? const Padding(
                      padding: EdgeInsets.only(right: 14),
                      child: Icon(CupertinoIcons.checkmark_circle_fill, color: Color(0xFF16A34A), size: 22),
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFFAF7F2),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2D6C5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isValid12 ? const Color(0xFF86EFAC) : const Color(0xFFE2D6C5),
                  width: isValid12 ? 1.4 : 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF750000), width: 1.5),
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
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  /// Step 2: Upload Documents Section
  Widget _buildDocUploadSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE4D8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
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
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF750000),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '2',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Upload Aadhaar Card Photos',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2B0A0D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Upload clear, un-cropped photos of the front and back of your card',
            style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF7A6E65)),
          ),
          const SizedBox(height: 16),

          // Two Document Upload Cards (Front & Back)
          Row(
            children: [
              Expanded(
                child: _buildDocUploadCard(
                  title: 'Aadhaar Front',
                  subtitle: 'Photo & Name',
                  file: _frontFile,
                  onTap: () => _pickDocumentImage(isFront: true),
                  onRemove: () => setState(() => _frontFile = null),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDocUploadCard(
                  title: 'Aadhaar Back',
                  subtitle: 'Address & QR',
                  file: _backFile,
                  onTap: () => _pickDocumentImage(isFront: false),
                  onRemove: () => setState(() => _backFile = null),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Helpful Upload Advice Note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEFE8DE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(CupertinoIcons.info_circle_fill, size: 15, color: Color(0xFF8C7E72)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Supported: JPG, PNG • Max size: 5 MB each. Ensure details like full name, DOB, and photo are legible.',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: const Color(0xFF7A6E65),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Single Document Upload Box (Polished Card Shape)
  Widget _buildDocUploadCard({
    required String title,
    required String subtitle,
    required File? file,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    final hasFile = file != null;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasFile ? const Color(0xFF750000) : const Color(0xFFE2D6C5),
          width: hasFile ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Label Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
            child: Row(
              children: [
                Icon(
                  hasFile ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.doc_text,
                  size: 13,
                  color: hasFile ? const Color(0xFF16A34A) : const Color(0xFF750000),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2B0A0D),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Upload Area Box
          InkWell(
            onTap: hasFile ? () => _showImagePreviewDialog(file, title) : onTap,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
            child: Container(
              height: 125,
              margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasFile ? Colors.transparent : const Color(0xFFE5DDD2),
                ),
              ),
              child: hasFile
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.file(
                            file,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        // Dark Gradient for readability
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(11),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.4),
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.6),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                        // Delete Button (Top Right)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: GestureDetector(
                            onTap: onRemove,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 13, color: Colors.white),
                            ),
                          ),
                        ),
                        // Bottom Status Badge
                        Positioned(
                          bottom: 6,
                          left: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(CupertinoIcons.eye_fill, size: 10, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  'Tap to view',
                                  style: GoogleFonts.outfit(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF750000).withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.cloud_upload_fill,
                            color: Color(0xFF750000),
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Upload Photo',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF750000),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tap to choose',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF8C7E72),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Privacy and Bank-Grade Security Card
  Widget _buildPrivacySecurityCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7).withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.lock_shield_fill, color: Color(0xFFD97706), size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '100% Privacy & Data Security',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your Aadhaar details are encrypted and masked. They are strictly used for admin identity verification and are NEVER visible to other members.',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: const Color(0xFF78350F),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Verified State Card
  Widget _buildVerifiedCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0FDF4), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF86EFAC)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A34A).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(CupertinoIcons.checkmark_seal_fill, color: Colors.white, size: 34),
          ),
          const SizedBox(height: 14),
          Text(
            'Your Profile is Blue Tick Verified!',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF14532D),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Congratulations! Your Aadhaar verification has been approved by admin. Your profile displays the official verified badge across all searches and match cards.',
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              color: const Color(0xFF166534),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Return to Dashboard',
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Pending State Card
  Widget _buildPendingCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFBEB), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFDE68A)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD97706).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(CupertinoIcons.clock_fill, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 14),
          Text(
            'Verification Under Review',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF78350F),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Your Aadhaar card documents have been submitted and are under review by our admin team. The verification process takes 24-48 hours.',
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              color: const Color(0xFF92400E),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF750000),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Return to Dashboard',
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
