import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum RaniAlertType {
  success,
  error,
  warning,
  info,
}

/// Royal Animated Custom Alert Component for Rani Matrimonial
/// - Uses OverlayEntry so it appears on top of EVERYTHING (including Modal Bottom Sheets!)
/// - Smooth spring slide-down & fade entrance animation
/// - Auto dismisses after duration or swipe up
class RaniAlert {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  /// Show custom floating top alert banner
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    RaniAlertType type = RaniAlertType.info,
    Duration duration = const Duration(milliseconds: 3800),
    VoidCallback? onTap,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _dismissTimer?.cancel();
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.of(context, rootOverlay: true);

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _RaniAlertBannerWidget(
        message: message,
        title: title,
        type: type,
        duration: duration,
        onTap: onTap,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismiss: () {
          _dismiss();
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    _dismissTimer = Timer(duration, () {
      _dismiss();
    });
  }

  static void _dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }

  /// Shorthand helpers
  static void success(BuildContext context, String message, {String? title, Duration? duration}) {
    show(
      context,
      message: message,
      title: title ?? 'Success',
      type: RaniAlertType.success,
      duration: duration ?? const Duration(milliseconds: 3500),
    );
  }

  static void error(BuildContext context, String message, {String? title, Duration? duration, String? actionLabel, VoidCallback? onAction}) {
    show(
      context,
      message: message,
      title: title ?? 'Action Failed',
      type: RaniAlertType.error,
      duration: duration ?? const Duration(milliseconds: 4500),
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void warning(BuildContext context, String message, {String? title, Duration? duration}) {
    show(
      context,
      message: message,
      title: title ?? 'Notice',
      type: RaniAlertType.warning,
      duration: duration ?? const Duration(milliseconds: 3800),
    );
  }

  static void info(BuildContext context, String message, {String? title, Duration? duration}) {
    show(
      context,
      message: message,
      title: title ?? 'Information',
      type: RaniAlertType.info,
      duration: duration ?? const Duration(milliseconds: 3500),
    );
  }

  /// Show Animated Custom Royal Alert Dialog (Modal popup with backdrop blur)
  static Future<bool?> showCustomDialog(
    BuildContext context, {
    required String title,
    required String message,
    RaniAlertType type = RaniAlertType.info,
    String confirmText = 'OK',
    String? cancelText,
    VoidCallback? onConfirm,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'RaniDialog',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(curve),
          child: FadeTransition(
            opacity: anim1,
            child: _RaniCustomDialogContent(
              title: title,
              message: message,
              type: type,
              confirmText: confirmText,
              cancelText: cancelText,
              onConfirm: onConfirm,
            ),
          ),
        );
      },
    );
  }
}

class _RaniAlertBannerWidget extends StatefulWidget {
  final String message;
  final String? title;
  final RaniAlertType type;
  final Duration duration;
  final VoidCallback? onTap;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;

  const _RaniAlertBannerWidget({
    required this.message,
    this.title,
    required this.type,
    required this.duration,
    this.onTap,
    this.actionLabel,
    this.onAction,
    required this.onDismiss,
  });

  @override
  State<_RaniAlertBannerWidget> createState() => _RaniAlertBannerWidgetState();
}

class _RaniAlertBannerWidgetState extends State<_RaniAlertBannerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();
  }

  Future<void> _handleDismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top + 10;

    final config = _getAlertConfig(widget.type);

    return Positioned(
      top: topPadding,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta != null && details.primaryDelta! < -4) {
                  _handleDismiss();
                }
              },
              onTap: widget.onTap,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      config.bgColor,
                      config.bgColorAlt,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: config.borderColor,
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: config.shadowColor.withValues(alpha: 0.35),
                      blurRadius: 20,
                      spreadRadius: 1,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Badge Icon
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            config.iconBg,
                            config.iconBg.withValues(alpha: 0.8),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: config.iconColor.withValues(alpha: 0.4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        config.icon,
                        color: config.iconColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Content
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.title != null) ...[
                            Text(
                              widget.title!,
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            widget.message,
                            style: GoogleFonts.outfit(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.95),
                              height: 1.35,
                            ),
                          ),
                          if (widget.actionLabel != null && widget.onAction != null) ...[
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () {
                                _handleDismiss();
                                widget.onAction!();
                              },
                              child: Text(
                                widget.actionLabel!,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFE5B842),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Close Button
                    GestureDetector(
                      onTap: _handleDismiss,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _AlertStyleConfig _getAlertConfig(RaniAlertType type) {
    switch (type) {
      case RaniAlertType.success:
        return _AlertStyleConfig(
          bgColor: const Color(0xFF143823),
          bgColorAlt: const Color(0xFF0D2517),
          borderColor: const Color(0xFF22C55E),
          shadowColor: const Color(0xFF15803D),
          iconBg: const Color(0xFF22C55E),
          iconColor: Colors.white,
          icon: Icons.check_circle_rounded,
        );
      case RaniAlertType.error:
        return _AlertStyleConfig(
          bgColor: const Color(0xFF4A0E17),
          bgColorAlt: const Color(0xFF2E050B),
          borderColor: const Color(0xFFEF4444),
          shadowColor: const Color(0xFFB91C1C),
          iconBg: const Color(0xFFEF4444),
          iconColor: Colors.white,
          icon: Icons.error_rounded,
        );
      case RaniAlertType.warning:
        return _AlertStyleConfig(
          bgColor: const Color(0xFF452B05),
          bgColorAlt: const Color(0xFF2D1B03),
          borderColor: const Color(0xFFF59E0B),
          shadowColor: const Color(0xFFD97706),
          iconBg: const Color(0xFFF59E0B),
          iconColor: const Color(0xFF2A1502),
          icon: Icons.warning_amber_rounded,
        );
      case RaniAlertType.info:
        return _AlertStyleConfig(
          bgColor: const Color(0xFF2A0808),
          bgColorAlt: const Color(0xFF1A0000),
          borderColor: const Color(0xFFE5B842),
          shadowColor: const Color(0xFFE5B842),
          iconBg: const Color(0xFFE5B842),
          iconColor: const Color(0xFF3B0000),
          icon: Icons.info_rounded,
        );
    }
  }
}

class _AlertStyleConfig {
  final Color bgColor;
  final Color bgColorAlt;
  final Color borderColor;
  final Color shadowColor;
  final Color iconBg;
  final Color iconColor;
  final IconData icon;

  _AlertStyleConfig({
    required this.bgColor,
    required this.bgColorAlt,
    required this.borderColor,
    required this.shadowColor,
    required this.iconBg,
    required this.iconColor,
    required this.icon,
  });
}

class _RaniCustomDialogContent extends StatelessWidget {
  final String title;
  final String message;
  final RaniAlertType type;
  final String confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;

  const _RaniCustomDialogContent({
    required this.title,
    required this.message,
    required this.type,
    required this.confirmText,
    this.cancelText,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    IconData iconData = Icons.info_rounded;
    Color iconColor = const Color(0xFFE5B842);
    Color glowColor = const Color(0xFFE5B842);

    if (type == RaniAlertType.success) {
      iconData = Icons.check_circle_rounded;
      iconColor = const Color(0xFF22C55E);
      glowColor = const Color(0xFF22C55E);
    } else if (type == RaniAlertType.error) {
      iconData = Icons.cancel_rounded;
      iconColor = const Color(0xFFEF4444);
      glowColor = const Color(0xFFEF4444);
    } else if (type == RaniAlertType.warning) {
      iconData = Icons.warning_rounded;
      iconColor = const Color(0xFFF59E0B);
      glowColor = const Color(0xFFF59E0B);
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: const Color(0xFF26121B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFE5B842).withValues(alpha: 0.6),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 30,
              spreadRadius: 4,
            ),
            BoxShadow(
              color: glowColor.withValues(alpha: 0.25),
              blurRadius: 24,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Pulsing Halo Icon
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                  border: Border.all(color: iconColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withValues(alpha: 0.45),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: Icon(iconData, size: 36, color: iconColor),
              ),

              const SizedBox(height: 18),

              Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              Text(
                message,
                style: GoogleFonts.outfit(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  if (cancelText != null) ...[
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                        child: Text(
                          cancelText!,
                          style: GoogleFonts.outfit(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop(true);
                        if (onConfirm != null) onConfirm!();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE5B842), Color(0xFFC59424)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE5B842).withValues(alpha: 0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Text(
                          confirmText,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF3B0000),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
