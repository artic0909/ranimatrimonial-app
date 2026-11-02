import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/api_service.dart';
import '../../components/rani_alert.dart';
import '../../components/rani_matrimonial_loader.dart';
import '../../components/rani_image_cropper_modal.dart';

/// Screen: Candidate Gallery Photos & Profile Picture Management
/// Matches website's my_photos.blade.php
class RaniPhotosScreen extends StatefulWidget {
  const RaniPhotosScreen({super.key});

  @override
  State<RaniPhotosScreen> createState() => _RaniPhotosScreenState();
}

class _RaniPhotosScreenState extends State<RaniPhotosScreen> {
  bool _isLoading = false;
  List<dynamic> _photos = [];

  String _formatPhotoUrl(dynamic raw) {
    if (raw == null) return '';
    final urlStr = raw.toString().trim();
    if (urlStr.isEmpty) return '';
    if (urlStr.startsWith('http://') || urlStr.startsWith('https://')) return urlStr;
    final serverBase = ApiService.baseUrl.replaceAll('/api', '');
    return '$serverBase/storage/${urlStr.replaceFirst(RegExp(r'^/?(storage/)?'), '')}';
  }

  @override
  void initState() {
    super.initState();
    _initPhotosFromCache();
    _loadPhotos();
  }

  void _initPhotosFromCache() {
    try {
      final cand = ApiService.instance.candidate;
      if (cand != null) {
        final cached = cand['photos'];
        if (cached is List && cached.isNotEmpty) {
          _photos = List.from(cached);
        } else if (cand['profile_picture'] != null &&
            cand['profile_picture'].toString().isNotEmpty) {
          _photos = [
            {
              'id': 'profile_main',
              'url': cand['profile_picture'],
              'is_profile': true,
            }
          ];
        }
      }
    } catch (e) {
      debugPrint('[PhotosScreen] Cache init error: $e');
    }
  }

  Future<void> _loadPhotos() async {
    if (_photos.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      final res = await ApiService.instance.getMyPhotos();
      if (!mounted) return;

      final list = res['data']?['photos'] ?? res['photos'];
      if (list is List) {
        setState(() {
          _photos = List.from(list);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('[PhotosScreen] Load photos error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadPhoto() async {
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
                'Add Photo to Gallery',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(CupertinoIcons.camera_fill, color: Color(0xFF750000)),
                title: Text('Take Photo with Camera', style: GoogleFonts.outfit(fontSize: 14)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final perm = await Permission.camera.request();
                  if (perm.isGranted) {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 90);
                    if (picked != null) {
                      _processNewPhoto(File(picked.path));
                    }
                  } else {
                    if (mounted) {
                      RaniAlert.warning(context, 'Camera permission is required.');
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
                  final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
                  if (picked != null) {
                    _processNewPhoto(File(picked.path));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processNewPhoto(File file) async {
    final cropped = await RaniImageCropperModal.show(
      context,
      imageFile: file,
      title: 'Adjust Gallery Photo',
      isCircle: false,
    );

    if (cropped == null) return;
    if (!mounted) return;

    RaniMatrimonialLoader.show(context, message: 'Uploading photo...');

    try {
      final res = await ApiService.instance.uploadGalleryPhotos([cropped]);
      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);

      if (res['success'] == true) {
        RaniAlert.success(context, 'Photo added to gallery successfully!');
        _loadPhotos();
      } else {
        RaniAlert.error(context, res['message'] ?? 'Failed to upload photo.');
      }
    } catch (e) {
      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);
      RaniAlert.error(context, 'Upload error: $e');
    }
  }

  Future<void> _setAsProfile(dynamic photoId) async {
    RaniMatrimonialLoader.show(context, message: 'Updating profile picture...');
    try {
      final res = await ApiService.instance.setProfilePhoto(photoId);
      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);

      if (res['success'] == true) {
        RaniAlert.success(context, 'Profile picture updated successfully!');
        _loadPhotos();
      } else {
        RaniAlert.error(context, res['message'] ?? 'Failed to set profile picture.');
      }
    } catch (e) {
      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);
      RaniAlert.error(context, 'Error: $e');
    }
  }

  Future<void> _deletePhoto(dynamic photoId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Photo', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to delete this photo from your gallery?',
          style: GoogleFonts.outfit(fontSize: 13.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    RaniMatrimonialLoader.show(context, message: 'Deleting photo...');

    try {
      final res = await ApiService.instance.deletePhoto(photoId);
      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);

      if (res['success'] == true) {
        RaniAlert.success(context, 'Photo deleted.');
        _loadPhotos();
      } else {
        RaniAlert.error(context, res['message'] ?? 'Failed to delete photo.');
      }
    } catch (e) {
      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);
      RaniAlert.error(context, 'Error: $e');
    }
  }

  Widget _buildAddPhotoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFE8DE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF750000).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.photo_on_rectangle,
                color: Color(0xFF750000), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Photos to Profile',
                  style: GoogleFonts.outfit(fontSize: 15.5, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Profiles with 3+ photos get 80% more interest and matches.',
                  style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6E6E6E)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF750000),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            ),
            onPressed: _pickAndUploadPhoto,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_a_photo_rounded, size: 14),
                SizedBox(width: 5),
                Text('Upload', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFE8DE)),
      ),
      child: Column(
        children: [
          const Icon(CupertinoIcons.photo, size: 44, color: Color(0xFFB5A8A0)),
          const SizedBox(height: 12),
          Text(
            'No photos uploaded yet',
            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Upload recent clear pictures to showcase your lifestyle.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 12.5, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF750000),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: _pickAndUploadPhoto,
            icon: const Icon(Icons.add_a_photo, size: 16),
            label: const Text('Upload Photo Now', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(int index) {
    final item = _photos[index];
    dynamic photoId;
    bool isProfile = false;
    String rawUrl = '';

    if (item is Map) {
      photoId = item['id'];
      isProfile = item['is_profile_picture'] == true || item['is_profile'] == true;
      rawUrl = item['url']?.toString() ?? item['photo_path']?.toString() ?? '';
    } else if (item is String) {
      photoId = index;
      rawUrl = item;
      isProfile = (index == 0);
    } else {
      photoId = index;
      rawUrl = item?.toString() ?? '';
    }

    final url = _formatPhotoUrl(rawUrl);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isProfile ? const Color(0xFFE5B842) : const Color(0xFFEFE8DE),
          width: isProfile ? 2.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFFF5EFEB),
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey, size: 32),
                ),
              ),
            ),

            // Profile Badge
            if (isProfile)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF750000),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 12, color: Color(0xFFE5B842)),
                      const SizedBox(width: 4),
                      Text(
                        'Profile',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Delete Button
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _deletePhoto(photoId),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(CupertinoIcons.trash, size: 14, color: Colors.white),
                ),
              ),
            ),

            // Bottom "Set as Profile" Button
            if (!isProfile)
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.95),
                    foregroundColor: const Color(0xFF750000),
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _setAsProfile(photoId),
                  child: Text(
                    'Set as Profile',
                    style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoTipsBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF750000).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF750000).withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: Color(0xFF750000), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Photo Guidelines: Upload bright, clear portrait pictures with good natural lighting. Avoid heavy filters, group photos, or side faces.',
              style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF5A4E46), height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Color(0xFF750000)),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Text(
          'Photo Gallery',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1E1E),
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: const Color(0xFF750000),
        onRefresh: _loadPhotos,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Add Photo Banner
                    _buildAddPhotoBanner(),
                    const SizedBox(height: 22),
                    // 2. Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'My Photos (${_photos.length})',
                          style: GoogleFonts.outfit(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E1E1E),
                          ),
                        ),
                        if (_photos.isNotEmpty)
                          TextButton.icon(
                            onPressed: _pickAndUploadPhoto,
                            icon: const Icon(Icons.add, size: 16, color: Color(0xFF750000)),
                            label: Text(
                              'Add More',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF750000),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isLoading && _photos.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(color: Color(0xFF750000)),
                      )
                    else if (_photos.isEmpty)
                      _buildEmptyState(),
                  ],
                ),
              ),
            ),
            if (_photos.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.78,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildPhotoCard(index),
                    childCount: _photos.length,
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: _buildPhotoTipsBox(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
