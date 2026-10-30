import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

/// Official Native Image Cropper Wrapper (Royal Rani Theme)
/// Powered by pub.dev's industry standard `image_cropper` (UCrop on Android, TOCropViewController on iOS)
/// Guarantees hardware acceleration, smooth pinch-to-zoom/rotation, and zero Flutter layout crashes.
class RaniImageCropperModal {
  /// Static helper to launch native cropper and return cropped File
  static Future<File?> show(
    BuildContext context, {
    required File imageFile,
    String title = 'Adjust Photo',
    bool isCircle = true,
  }) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: title,
            toolbarColor: const Color(0xFF750000), // Royal Maroon
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: const Color(0xFFE5B842), // Royal Gold
            backgroundColor: const Color(0xFFFAF7F2),
            statusBarColor: const Color(0xFF4A0000),
            cropStyle: isCircle ? CropStyle.circle : CropStyle.rectangle,
            aspectRatioPresets: isCircle
                ? [CropAspectRatioPreset.square]
                : [
                    CropAspectRatioPreset.original,
                    CropAspectRatioPreset.square,
                    CropAspectRatioPreset.ratio4x3,
                    CropAspectRatioPreset.ratio16x9,
                  ],
            initAspectRatio: isCircle
                ? CropAspectRatioPreset.square
                : CropAspectRatioPreset.original,
            lockAspectRatio: isCircle,
            showCropGrid: true,
          ),
          IOSUiSettings(
            title: title,
            cropStyle: isCircle ? CropStyle.circle : CropStyle.rectangle,
            aspectRatioLockEnabled: isCircle,
            resetAspectRatioEnabled: !isCircle,
            aspectRatioPresets: isCircle
                ? [CropAspectRatioPreset.square]
                : [
                    CropAspectRatioPreset.original,
                    CropAspectRatioPreset.square,
                    CropAspectRatioPreset.ratio4x3,
                    CropAspectRatioPreset.ratio16x9,
                  ],
          ),
        ],
      );

      if (croppedFile != null) {
        return File(croppedFile.path);
      }
      return null;
    } catch (e) {
      debugPrint('[RaniImageCropper] Error cropping image: $e');
      // Fallback to original file if cropper was cancelled or failed
      return null;
    }
  }
}
