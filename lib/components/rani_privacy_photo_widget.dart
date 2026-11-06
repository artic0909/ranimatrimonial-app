import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class RaniPhotoPrivacyHelper {
  /// Check if the primary profile photo should be blurred
  static bool shouldBlurProfilePhoto(Map<String, dynamic>? candidate) {
    if (candidate == null) return false;

    // If viewing own profile, never blur
    final currentCandidate = ApiService.instance.candidate;
    if (currentCandidate != null) {
      final currentCode = currentCandidate['candidate_code'] ?? currentCandidate['profile_id'];
      final candidateCode = candidate['candidate_code'] ?? candidate['profile_id'] ?? candidate['id'];
      if (currentCode != null && candidateCode != null && currentCode.toString() == candidateCode.toString()) {
        return false;
      }
    }

    final privacy = candidate['photo_privacy']?.toString() ?? 'Visible to all Members (Recommended)';
    if (privacy == 'Visible to all Members (Recommended)') {
      return false;
    }

    final isAccepted = candidate['is_accepted'] == true || candidate['request_type'] == 'accepted';
    final isReceived = candidate['is_interest_received'] == true ||
        candidate['is_received_by_me'] == true ||
        candidate['request_type'] == 'received';

    if (privacy == 'Visible only to Members I like') {
      // Only visible if this member liked the current user (sent interest) or mutual connection is accepted
      return !isAccepted && !isReceived;
    }

    if (privacy == 'Visible to Members I like and to all Premium Members') {
      if (isAccepted || isReceived) return false;
      final isPremium = currentCandidate?['is_bluetick_verified'] == true ||
          currentCandidate?['selfie_verified'] == true;
      return !isPremium;
    }

    return false;
  }

  /// Check if a gallery album photo (photoIndex > 0) should be blurred
  static bool shouldBlurGalleryPhoto({
    required Map<String, dynamic>? candidate,
    required int photoIndex,
  }) {
    if (candidate == null) return false;

    if (photoIndex == 0) {
      return shouldBlurProfilePhoto(candidate);
    }

    // If viewing own gallery, never blur
    final currentCandidate = ApiService.instance.candidate;
    if (currentCandidate != null) {
      final currentCode = currentCandidate['candidate_code'] ?? currentCandidate['profile_id'];
      final candidateCode = candidate['candidate_code'] ?? candidate['profile_id'] ?? candidate['id'];
      if (currentCode != null && candidateCode != null && currentCode.toString() == candidateCode.toString()) {
        return false;
      }
    }

    final privacy = candidate['album_privacy']?.toString() ?? 'Visible to all Members';
    if (privacy == 'Visible to all Members') {
      return false;
    }

    final isAccepted = candidate['is_accepted'] == true || candidate['request_type'] == 'accepted';

    if (privacy == 'Blur until request accepted' || privacy == 'Visible to all with request') {
      return !isAccepted;
    }

    if (privacy == 'Only visible to members I like') {
      final isReceived = candidate['is_interest_received'] == true ||
          candidate['is_received_by_me'] == true ||
          candidate['request_type'] == 'received';
      return !isAccepted && !isReceived;
    }

    return false;
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
    if (photoIndex != null && photoIndex! > 0) {
      return RaniPhotoPrivacyHelper.shouldBlurGalleryPhoto(
        candidate: candidate,
        photoIndex: photoIndex!,
      );
    }
    return RaniPhotoPrivacyHelper.shouldBlurProfilePhoto(candidate);
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
        errorBuilder: (_, __, ___) => Container(
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
        errorBuilder: (_, __, ___) => Container(
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
                          lockText ?? 'Photo Private',
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
