import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

/// WhatsApp / Facebook style Profile Picture & Album Cropper Modal (Royal Rani Theme)
/// Responsive, pre-decoded memory rendering to guarantee no layout assertions or black screen.
class RaniImageCropperModal extends StatefulWidget {
  final File imageFile;
  final String title;
  final bool isCircle;

  const RaniImageCropperModal({
    super.key,
    required this.imageFile,
    this.title = 'Adjust Photo',
    this.isCircle = true,
  });

  /// Static helper to show modal dialog and return cropped File
  static Future<File?> show(
    BuildContext context, {
    required File imageFile,
    String title = 'Adjust Photo',
    bool isCircle = true,
  }) {
    return showDialog<File>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (ctx) => RaniImageCropperModal(
        imageFile: imageFile,
        title: title,
        isCircle: isCircle,
      ),
    );
  }

  @override
  State<RaniImageCropperModal> createState() => _RaniImageCropperModalState();
}

class _RaniImageCropperModalState extends State<RaniImageCropperModal> {
  final GlobalKey _cropAreaKey = GlobalKey();
  final TransformationController _transformController = TransformationController();
  int _rotationQuarterTurns = 0;
  bool _isProcessing = false;
  Uint8List? _imageBytes;
  bool _hasLoadError = false;

  @override
  void initState() {
    super.initState();
    _loadImageBytes();
  }

  Future<void> _loadImageBytes() async {
    try {
      final bytes = await widget.imageFile.readAsBytes();
      if (mounted) {
        setState(() {
          _imageBytes = bytes;
          _hasLoadError = false;
        });
      }
    } catch (e) {
      debugPrint('[RaniImageCropper] Error reading image bytes: $e');
      if (mounted) {
        setState(() {
          _hasLoadError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _rotateLeft() {
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns - 1) % 4;
    });
  }

  void _rotateRight() {
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
    });
  }

  void _resetTransform() {
    setState(() {
      _rotationQuarterTurns = 0;
      _transformController.value = Matrix4.identity();
    });
  }

  void _zoomIn() {
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    if (currentScale < 4.0) {
      final newScale = (currentScale + 0.35).clamp(1.0, 4.5);
      final factor = newScale / currentScale;
      _transformController.value = _transformController.value.clone()
        ..multiply(Matrix4.diagonal3Values(factor, factor, 1.0));
      setState(() {});
    }
  }

  void _zoomOut() {
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    if (currentScale > 0.8) {
      final newScale = (currentScale - 0.35).clamp(0.6, 4.5);
      final factor = newScale / currentScale;
      _transformController.value = _transformController.value.clone()
        ..multiply(Matrix4.diagonal3Values(factor, factor, 1.0));
      setState(() {});
    }
  }

  Future<void> _cropAndSave() async {
    if (_imageBytes == null) return;
    setState(() => _isProcessing = true);

    try {
      final boundary = _cropAreaKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        if (mounted) Navigator.pop(context, widget.imageFile);
        return;
      }

      final image = await boundary.toImage(pixelRatio: 2.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        if (mounted) Navigator.pop(context, widget.imageFile);
        return;
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.png';
      final croppedFile = File(targetPath);
      await croppedFile.writeAsBytes(pngBytes);

      if (mounted) {
        Navigator.pop(context, croppedFile);
      }
    } catch (e) {
      debugPrint('[RaniImageCropper] Crop error: $e');
      if (mounted) {
        Navigator.pop(context, widget.imageFile);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const cropSize = 250.0;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFC49A45), width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Royal Gold / Maroon Accent Line
              Container(
                height: 4,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFC49A45), Color(0xFF750000), Color(0xFFC49A45)],
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF750000).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFC49A45).withValues(alpha: 0.5)),
                      ),
                      child: const Icon(CupertinoIcons.camera_fill, color: Color(0xFF750000), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E1E1E),
                            ),
                          ),
                          Text(
                            'Pinch to zoom, drag to position',
                            style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF7E726B)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.xmark, color: Colors.black54, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(color: Color(0xFFEFE8DE), height: 1),

              const SizedBox(height: 14),

              // Crop Viewport with Live circular / square mask
              Center(
                child: _hasLoadError
                    ? Container(
                        width: cropSize,
                        height: cropSize,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF7F2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          'Failed to load image',
                          style: GoogleFonts.outfit(color: Colors.red, fontSize: 13),
                        ),
                      )
                    : _imageBytes == null
                        ? Container(
                            width: cropSize,
                            height: cropSize,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF7F2),
                              borderRadius: BorderRadius.circular(widget.isCircle ? cropSize / 2 : 16),
                              border: Border.all(color: const Color(0xFFC49A45), width: 2.0),
                            ),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: Color(0xFF750000), strokeWidth: 2.5),
                                SizedBox(height: 10),
                                Text(
                                  'Loading picture...',
                                  style: TextStyle(color: Color(0xFF7E726B), fontSize: 12),
                                ),
                              ],
                            ),
                          )
                        : RepaintBoundary(
                            key: _cropAreaKey,
                            child: Container(
                              width: cropSize,
                              height: cropSize,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAF7F2),
                                borderRadius: BorderRadius.circular(widget.isCircle ? cropSize / 2 : 16),
                                border: Border.all(color: const Color(0xFFC49A45), width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF750000).withValues(alpha: 0.12),
                                    blurRadius: 14,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(widget.isCircle ? cropSize / 2 : 14),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    InteractiveViewer(
                                      transformationController: _transformController,
                                      minScale: 0.6,
                                      maxScale: 4.5,
                                      boundaryMargin: const EdgeInsets.all(100),
                                      child: SizedBox(
                                        width: cropSize,
                                        height: cropSize,
                                        child: RotatedBox(
                                          quarterTurns: _rotationQuarterTurns,
                                          child: Image.memory(
                                            _imageBytes!,
                                            width: cropSize,
                                            height: cropSize,
                                            fit: BoxFit.cover,
                                            gaplessPlayback: true,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Subtle Grid overlay
                                    Positioned.fill(
                                      child: IgnorePointer(
                                        child: CustomPaint(
                                          painter: _CropperGridPainter(isCircle: widget.isCircle),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
              ),

              const SizedBox(height: 14),

              // Controls Toolbar (Rotate, Zoom, Reset)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF7F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEFE8DE)),
                ),
                child: Row(
                  children: [
                    _buildToolButton(
                      icon: CupertinoIcons.rotate_left,
                      label: 'Rotate L',
                      onTap: _rotateLeft,
                    ),
                    _buildToolButton(
                      icon: CupertinoIcons.rotate_right,
                      label: 'Rotate R',
                      onTap: _rotateRight,
                    ),
                    _buildToolButton(
                      icon: CupertinoIcons.minus_circle,
                      label: 'Zoom Out',
                      onTap: _zoomOut,
                    ),
                    _buildToolButton(
                      icon: CupertinoIcons.plus_circle,
                      label: 'Zoom In',
                      onTap: _zoomIn,
                    ),
                    _buildToolButton(
                      icon: CupertinoIcons.arrow_counterclockwise,
                      label: 'Reset',
                      onTap: _resetTransform,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Footer Action Buttons
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFBF9F6),
                  border: Border(top: BorderSide(color: Color(0xFFEFE8DE))),
                ),
                child: Row(
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6E6E6E),
                        side: const BorderSide(color: Color(0xFFD6CBC3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF750000),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                        onPressed: (_isProcessing || _imageBytes == null) ? null : _cropAndSave,
                        child: _isProcessing
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(CupertinoIcons.checkmark_alt, size: 16, color: Color(0xFFE5B842)),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Save & Set Photo',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: const Color(0xFF750000), size: 18),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF4A4A4A), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CropperGridPainter extends CustomPainter {
  final bool isCircle;

  _CropperGridPainter({required this.isCircle});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC49A45).withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Rule of thirds lines
    final oneThirdW = size.width / 3;
    final twoThirdW = size.width * 2 / 3;
    final oneThirdH = size.height / 3;
    final twoThirdH = size.height * 2 / 3;

    canvas.drawLine(Offset(oneThirdW, 0), Offset(oneThirdW, size.height), paint);
    canvas.drawLine(Offset(twoThirdW, 0), Offset(twoThirdW, size.height), paint);
    canvas.drawLine(Offset(0, oneThirdH), Offset(size.width, oneThirdH), paint);
    canvas.drawLine(Offset(0, twoThirdH), Offset(size.width, twoThirdH), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
