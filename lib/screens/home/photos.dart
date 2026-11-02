import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/api_service.dart';
import '../../components/rani_alert.dart';
import '../../components/rani_matrimonial_loader.dart';

/// Screen: Candidate Gallery Photos & Profile Picture Management
/// Matches website's my_photos.blade.php (Full CRUD: Create, Read, Update, Delete & Settings)
class RaniPhotosScreen extends StatefulWidget {
  const RaniPhotosScreen({super.key});

  @override
  State<RaniPhotosScreen> createState() => _RaniPhotosScreenState();
}

class _RaniPhotosScreenState extends State<RaniPhotosScreen> {
  // Tab: 'photo' or 'settings'
  String _activeTab = 'photo';

  bool _isLoading = false;
  bool _isSavingSettings = false;
  List<dynamic> _photos = [];

  // Privacy Settings matching website's my_photos.blade.php
  String _photoPrivacy = 'Visible to all Members (Recommended)';
  String _albumPrivacy = 'Visible to all Members';

  final List<String> _photoPrivacyOptions = [
    'Visible to all Members (Recommended)',
    'Visible to Members I like and to all Premium Members',
    'Visible only to Members I like',
  ];

  final List<String> _albumPrivacyOptions = [
    'Visible to all Members',
    'Visible to all with request',
    'Blur until request accepted',
  ];

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
        if (cand['photo_privacy'] != null && cand['photo_privacy'].toString().isNotEmpty) {
          _photoPrivacy = cand['photo_privacy'].toString();
        }
        if (cand['album_privacy'] != null && cand['album_privacy'].toString().isNotEmpty) {
          _albumPrivacy = cand['album_privacy'].toString();
        }

        final cached = cand['photos'];
        if (cached is List && cached.isNotEmpty) {
          _photos = List.from(cached);
        } else if (cached is String && cached.trim().isNotEmpty) {
          try {
            final parsed = jsonDecode(cached);
            if (parsed is List && parsed.isNotEmpty) {
              _photos = List.from(parsed);
            }
          } catch (_) {}
        }

        // If gallery is still empty, fallback to active profile picture
        if (_photos.isEmpty) {
          final profilePic = cand['profile_picture_url'] ?? cand['profile_picture'] ?? cand['photo'];
          if (profilePic != null && profilePic.toString().trim().isNotEmpty) {
            _photos = [
              {
                'id': 'profile_main',
                'url': profilePic.toString(),
                'is_profile': true,
              }
            ];
          }
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

      // Extract privacy settings
      final dataObj = res['data'] is Map ? res['data'] : null;
      if (dataObj != null) {
        if (dataObj['photo_privacy'] != null) {
          _photoPrivacy = dataObj['photo_privacy'].toString();
        }
        if (dataObj['album_privacy'] != null) {
          _albumPrivacy = dataObj['album_privacy'].toString();
        }
      }

      dynamic rawList = res['data']?['photos'] ?? res['photos'];
      if (rawList == null && res['data'] is List) {
        rawList = res['data'];
      }
      if (rawList is Map && rawList['data'] is List) {
        rawList = rawList['data'];
      }

      List<dynamic>? list;
      if (rawList is List) {
        list = rawList;
      } else if (rawList is String) {
        try {
          final parsed = jsonDecode(rawList);
          if (parsed is List) list = parsed;
        } catch (_) {}
      }

      if (list != null && list.isNotEmpty) {
        setState(() {
          _photos = List.from(list!);
          _isLoading = false;
        });
      } else {
        // Fallback to active profile picture if gallery is empty
        final cand = ApiService.instance.candidate;
        final profilePic = res['data']?['profile_picture_url'] ??
            res['data']?['profile_picture'] ??
            res['profile_picture_url'] ??
            res['profile_picture'] ??
            cand?['profile_picture_url'] ??
            cand?['profile_picture'] ??
            cand?['photo'];

        if (profilePic != null && profilePic.toString().trim().isNotEmpty) {
          setState(() {
            _photos = [
              {
                'id': 'profile_main',
                'url': profilePic.toString(),
                'is_profile': true,
              }
            ];
            _isLoading = false;
          });
        } else {
          setState(() {
            _photos = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('[PhotosScreen] Load photos error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// [C - CREATE]: Directly upload photos without cropping (supports single or multi-select)
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
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    Navigator.pop(ctx);
                    final perm = await Permission.camera.request();
                    if (perm.isGranted) {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                      if (picked != null) {
                        _uploadPhotosDirectly([File(picked.path)]);
                      }
                    } else {
                      if (mounted) {
                        RaniAlert.warning(context, 'Camera permission is required.');
                      }
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.camera_fill, color: Color(0xFF750000)),
                        const SizedBox(width: 14),
                        Text('Take Photo with Camera', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    Navigator.pop(ctx);
                    final picker = ImagePicker();
                    try {
                      final pickedList = await picker.pickMultiImage(imageQuality: 85);
                      if (pickedList.isNotEmpty) {
                        _uploadPhotosDirectly(pickedList.map((x) => File(x.path)).toList());
                        return;
                      }
                    } catch (_) {}
                    final single = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                    if (single != null) {
                      _uploadPhotosDirectly([File(single.path)]);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.photo_fill, color: Color(0xFF750000)),
                        const SizedBox(width: 14),
                        Text('Choose from Gallery', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Direct upload to backend API (No photo cropping needed)
  Future<void> _uploadPhotosDirectly(List<File> files) async {
    if (files.isEmpty) return;
    if (!mounted) return;

    RaniMatrimonialLoader.show(
      context,
      message: files.length > 1 ? 'Uploading ${files.length} photos...' : 'Uploading photo...',
    );

    try {
      final res = await ApiService.instance.uploadGalleryPhotos(files);
      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);

      if (res['success'] == true) {
        RaniAlert.success(context, res['message'] ?? 'Photo(s) added to gallery successfully!');
        _loadPhotos();
      } else {
        RaniAlert.error(context, res['message'] ?? 'Failed to upload photo(s).');
      }
    } catch (e) {
      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);
      RaniAlert.error(context, 'Upload error: $e');
    }
  }

  /// [U - UPDATE]: Set a gallery photo as the primary profile picture
  Future<void> _setAsProfile(dynamic photoId) async {
    if (photoId == null || photoId == 'profile_main') return;
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

  /// [D - DELETE]: Delete a gallery photo
  Future<void> _deletePhoto(dynamic photoId) async {
    if (photoId == null) return;
    if (photoId == 'profile_main') {
      RaniAlert.warning(
        context,
        'This is your primary profile photo. To change it, upload a new photo and tap "Set as Profile".',
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Photo', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to delete this photo from your gallery? This action cannot be undone.',
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

  /// [U - UPDATE SETTINGS]: Save photo & album privacy settings
  Future<void> _savePrivacySettings() async {
    setState(() => _isSavingSettings = true);
    RaniMatrimonialLoader.show(context, message: 'Saving privacy settings...');

    try {
      final res = await ApiService.instance.updatePhotoSettings(
        photoPrivacy: _photoPrivacy,
        albumPrivacy: _albumPrivacy,
      );
      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);
      setState(() => _isSavingSettings = false);

      if (res['success'] == true) {
        RaniAlert.success(context, 'Photo privacy settings updated successfully!');
      } else {
        RaniAlert.error(context, res['message'] ?? 'Failed to update privacy settings.');
      }
    } catch (e) {
      if (!mounted) return;
      RaniMatrimonialLoader.hide(context);
      setState(() => _isSavingSettings = false);
      RaniAlert.error(context, 'Error: $e');
    }
  }

  Widget _buildSubTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFE8DE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 'photo'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _activeTab == 'photo' ? const Color(0xFF750000) : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: _activeTab == 'photo'
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.photo_on_rectangle,
                          size: 16,
                          color: _activeTab == 'photo' ? Colors.white : const Color(0xFF6E6E6E),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Photos',
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: _activeTab == 'photo' ? Colors.white : const Color(0xFF4A4A4A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 'settings'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _activeTab == 'settings' ? const Color(0xFF750000) : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: _activeTab == 'settings'
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.lock_shield,
                          size: 16,
                          color: _activeTab == 'settings' ? Colors.white : const Color(0xFF6E6E6E),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Privacy Settings',
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: _activeTab == 'settings' ? Colors.white : const Color(0xFF4A4A4A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add Photos to Profile',
                  style: GoogleFonts.outfit(fontSize: 15.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Get more responses by uploading up to 20 photos on your profile.',
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
              minimumSize: const Size(0, 36),
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

  Widget _buildPhotoCard(dynamic item, int index) {
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

    return AspectRatio(
      aspectRatio: 0.78,
      child: Container(
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
              if (url.isNotEmpty)
                Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFFF5EFEB),
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey, size: 32),
                    ),
                  ),
                )
              else
                Container(
                  color: const Color(0xFFF5EFEB),
                  child: const Center(
                    child: Icon(Icons.photo_outlined, color: Colors.grey, size: 32),
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
              if (photoId != 'profile_main')
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
                      minimumSize: const Size(0, 30),
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

  /// Settings Tab Content (Matches website's Privacy Settings tab)
  Widget _buildSettingsTab() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Photo Privacy Settings',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Control who can see your photos on Rani Matrimonial',
                style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6E6E6E)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Section 1: Profile Photo Privacy
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
              Row(
                children: [
                  const Icon(CupertinoIcons.person_crop_circle, color: Color(0xFF750000), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Profile Photo Visibility',
                    style: GoogleFonts.outfit(fontSize: 14.5, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._photoPrivacyOptions.map((opt) {
                final isSelected = _photoPrivacy == opt;
                return InkWell(
                  onTap: () => setState(() => _photoPrivacy = opt),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: isSelected ? const Color(0xFF750000) : const Color(0xFFB5A8A0),
                          size: 19,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            opt,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected ? const Color(0xFF1E1E1E) : const Color(0xFF5A4E46),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Section 2: Gallery / Album Privacy
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
              Row(
                children: [
                  const Icon(CupertinoIcons.photo_on_rectangle, color: Color(0xFF750000), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Gallery Album Visibility',
                    style: GoogleFonts.outfit(fontSize: 14.5, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._albumPrivacyOptions.map((opt) {
                final isSelected = _albumPrivacy == opt;
                return InkWell(
                  onTap: () => setState(() => _albumPrivacy = opt),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: isSelected ? const Color(0xFF750000) : const Color(0xFFB5A8A0),
                          size: 19,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            opt,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected ? const Color(0xFF1E1E1E) : const Color(0xFF5A4E46),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // Save Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF750000),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            onPressed: _isSavingSettings ? null : _savePrivacySettings,
            child: _isSavingSettings
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'Save Settings',
                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    );
  }

  /// Photo Tab Content
  Widget _buildPhotoTab() {
    // Group photos into pairs for 2-column layout in ListView
    final photoRows = <List<dynamic>>[];
    for (var i = 0; i < _photos.length; i += 2) {
      photoRows.add(_photos.sublist(i, (i + 2 > _photos.length) ? _photos.length : i + 2));
    }

    return RefreshIndicator(
      color: const Color(0xFF750000),
      onRefresh: _loadPhotos,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // 1. Add Photo Banner
          _buildAddPhotoBanner(),
          const SizedBox(height: 20),

          // 2. Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'My Photos (${_photos.length} / 20)',
                  style: GoogleFonts.outfit(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1E1E),
                  ),
                  overflow: TextOverflow.ellipsis,
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

          // 3. Photo Content or Empty State / Loading State
          if (_isLoading && _photos.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              alignment: Alignment.center,
              child: const Column(
                children: [
                  CircularProgressIndicator(color: Color(0xFF750000)),
                  SizedBox(height: 12),
                  Text('Loading gallery photos...', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            )
          else if (_photos.isEmpty)
            _buildEmptyState()
          else
            ...photoRows.asMap().entries.map((entry) {
              final rowIndex = entry.key;
              final rowItems = entry.value;
              final item1 = rowItems[0];
              final item2 = rowItems.length > 1 ? rowItems[1] : null;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(child: _buildPhotoCard(item1, rowIndex * 2)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: item2 != null
                          ? _buildPhotoCard(item2, rowIndex * 2 + 1)
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 14),

          // 4. Photo Tips Box
          _buildPhotoTipsBox(),
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
      body: Column(
        children: [
          // Sub-tabs: Photos & Privacy Settings (matching website)
          _buildSubTabs(),

          // Body Content (Always renders immediately - never leaves blank space)
          Expanded(
            child: _activeTab == 'photo' ? _buildPhotoTab() : _buildSettingsTab(),
          ),
        ],
      ),
    );
  }
}
