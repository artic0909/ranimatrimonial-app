import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class RaniPhotoPrivacyHelper {
  /// Check if candidate photo should be blurred based on photo_privacy and album_privacy
  static bool shouldBlurCandidatePhoto(
    Map<String, dynamic>? candidate, {
    String? photoUrl,
    int photoIndex = 0,
  }) {
    if (candidate == null) return false;

    // 1. If viewing own profile, never blur
    final currentCandidate = ApiService.instance.candidate;
    if (currentCandidate != null) {
      final myIds = [
        currentCandidate['candidate_code']?.toString().trim().toLowerCase(),
        currentCandidate['profile_id']?.toString().trim().toLowerCase(),
        currentCandidate['id']?.toString().trim().toLowerCase(),
        currentCandidate['numeric_id']?.toString().trim().toLowerCase(),
      ].where((e) => e != null && e.isNotEmpty).toSet();

      final theirIds = [
        candidate['candidate_code']?.toString().trim().toLowerCase(),
        candidate['profile_id']?.toString().trim().toLowerCase(),
        candidate['id']?.toString().trim().toLowerCase(),
        candidate['numeric_id']?.toString().trim().toLowerCase(),
      ].where((e) => e != null && e.isNotEmpty).toSet();

      if (myIds.isNotEmpty && theirIds.isNotEmpty && myIds.any((id) => theirIds.contains(id))) {
        return false;
      }
    }

    // 2. Check connection acceptance status
    final isAccepted = candidate['is_accepted'] == true ||
        candidate['is_accepted'] == 1 ||
        candidate['is_accepted'] == '1' ||
        candidate['is_accepted'] == 'true' ||
        (candidate['request_type'] ?? '').toString().toLowerCase() == 'accepted' ||
        (candidate['status'] ?? '').toString().toLowerCase() == 'accepted';

    if (isAccepted) {
      return false; // Mutual connection accepted -> fully visible
    }

    // 3. Check interest received status
    final isReceived = candidate['is_interest_received'] == true ||
        candidate['is_received_by_me'] == true ||
        (candidate['request_type'] ?? '').toString().toLowerCase() == 'received';

    // 4. Check premium / bluetick verified status of current viewer
    final isViewerPremium = currentCandidate?['is_bluetick_verified'] == true ||
        currentCandidate?['selfie_verified'] == true ||
        (currentCandidate?['bluetick'] is Map && currentCandidate?['bluetick']?['is_accept'] == 1);

    final rawPhotoPrivacy = (candidate['photo_privacy'] ?? '').toString().trim().toLowerCase();
    final rawAlbumPrivacy = (candidate['album_privacy'] ?? '').toString().trim().toLowerCase();

    // 5. If this is a gallery photo or index > 0, check album privacy
    final isGalleryPhoto = photoIndex > 0 ||
        (photoUrl != null && (photoUrl.contains('/gallery/') || photoUrl.contains('gallery_'))) ||
        (candidate['profile_picture'] == null || candidate['profile_picture'].toString().trim().isEmpty);

    if (photoIndex > 0 || isGalleryPhoto) {
      if (rawAlbumPrivacy.contains('blur') || rawAlbumPrivacy.contains('request')) {
        return true;
      }
      if (rawAlbumPrivacy.contains('members i like')) {
        if (rawAlbumPrivacy.contains('premium')) {
          if (!isReceived && !isViewerPremium) return true;
        } else {
          if (!isReceived) return true;
        }
      }
    }

    // 6. Check profile photo privacy
    if (rawPhotoPrivacy.isEmpty ||
        rawPhotoPrivacy.contains('visible to all members (recommended)') ||
        rawPhotoPrivacy == 'visible to all members') {
      // Photo is public, but if it is a gallery photo with strict album privacy, album privacy wins
      if (isGalleryPhoto && (rawAlbumPrivacy.contains('blur') || rawAlbumPrivacy.contains('request'))) {
        return true;
      }
      return false;
    }

    if (rawPhotoPrivacy.contains('members i like')) {
      if (rawPhotoPrivacy.contains('premium')) {
        if (isReceived || isViewerPremium) return false;
        return true;
      } else {
        // "Visible only to Members I like" or "Only visible to members I like"
        if (isReceived) return false;
        return true;
      }
    }

    if (rawPhotoPrivacy.contains('blur') || rawPhotoPrivacy.contains('private')) {
      return true;
    }

    return false;
  }

  /// Check if the primary profile photo should be blurred
  static bool shouldBlurProfilePhoto(Map<String, dynamic>? candidate, {String? photoUrl}) {
    return shouldBlurCandidatePhoto(candidate, photoUrl: photoUrl, photoIndex: 0);
  }

  /// Check if a gallery album photo (photoIndex > 0) should be blurred
  static bool shouldBlurGalleryPhoto({
    required Map<String, dynamic>? candidate,
    required int photoIndex,
    String? photoUrl,
  }) {
    return shouldBlurCandidatePhoto(candidate, photoUrl: photoUrl, photoIndex: photoIndex);
  }
}

class RaniPrivacyPhotoWidget extends StatelessWidget {
  final String imageUrl;
  final bool? isBlurred;
  final Map<String, dynamic>? candidate;
  final int? photoIndex;
  final BoxFit fit;
  final Alignment alignment;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool showLockBadge;
  final String? lockText;

  const RaniPrivacyPhotoWidget({
    super.key,
    required this.imageUrl,
    this.isBlurred,
    this.candidate,
    this.photoIndex,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.width,
    this.height,
    this.borderRadius,
    this.showLockBadge = true,
    this.lockText,
  });

  bool get _effectiveIsBlurred {
    if (isBlurred != null) return isBlurred!;
    return RaniPhotoPrivacyHelper.shouldBlurCandidatePhoto(
      candidate,
      photoUrl: imageUrl,
      photoIndex: photoIndex ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final blurred = _effectiveIsBlurred;

    Widget imageWidget;
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      imageWidget = Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        errorBuilder: (_, _, _) => Container(
          width: width,
          height: height,
          color: const Color(0xFF381212),
          child: const Icon(Icons.person, size: 36, color: Color(0xFFD4A034)),
        ),
      );
    } else {
      imageWidget = Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        errorBuilder: (_, _, _) => Container(
          width: width,
          height: height,
          color: const Color(0xFF381212),
          child: const Icon(Icons.person, size: 36, color: Color(0xFFD4A034)),
        ),
      );
    }

    if (blurred) {
      imageWidget = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: imageWidget,
      );
    }

    Widget content = Stack(
      fit: StackFit.passthrough,
      alignment: Alignment.center,
      children: [
        imageWidget,
        if (blurred && showLockBadge)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.28),
              padding: const EdgeInsets.all(8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5B842).withValues(alpha: 0.7)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_rounded, size: 13, color: Color(0xFFE5B842)),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          lockText ?? 'Photo Protected',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: content);
    }
    return content;
  }
}
