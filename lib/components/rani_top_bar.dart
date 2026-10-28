import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable TopBar widget customizable per screen
/// Features:
/// - Hamburger menu leading button or custom back/action leading
/// - Dynamic center title / custom titleWidget
/// - Bell notification icon with real-time count badge
/// - Optional extra actions (search, filter, logout)
/// - Completely borderless, clean ivory-theme presentation
class RaniTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final bool showLeading;
  final Widget? leading;
  final VoidCallback? onMenuPressed;
  final int notificationCount;
  final VoidCallback? onNotificationPressed;
  final List<Widget>? actions;
  final Color backgroundColor;
  final PreferredSizeWidget? bottom;

  const RaniTopBar({
    super.key,
    this.title,
    this.titleWidget,
    this.showLeading = true,
    this.leading,
    this.onMenuPressed,
    this.notificationCount = 3,
    this.onNotificationPressed,
    this.actions,
    this.backgroundColor = const Color(0xFFFAF7F2),
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: const Border(), // Explicitly removes bottom border line
      centerTitle: true,
      leading: showLeading
          ? (leading ??
              IconButton(
                icon: const Icon(
                  CupertinoIcons.line_horizontal_3,
                  color: Color(0xFF1E1E1E),
                  size: 24,
                ),
                tooltip: 'Menu',
                onPressed: onMenuPressed ?? () => Scaffold.maybeOf(context)?.openDrawer(),
              ))
          : null,
      title: titleWidget ??
          Text(
            title ?? 'Rani Matrimonial',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
              letterSpacing: -0.2,
            ),
          ),
      actions: [
        ...?actions,
        IconButton(
          tooltip: 'Notifications ($notificationCount)',
          onPressed: onNotificationPressed ?? () => showNotificationsSheet(context, notificationCount),
          icon: notificationCount > 0
              ? Badge(
                  label: Text(
                    notificationCount > 99 ? '99+' : '$notificationCount',
                    style: GoogleFonts.outfit(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: const Color(0xFF750000), // Theme Burgundy
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
                  child: const Icon(
                    CupertinoIcons.bell,
                    color: Color(0xFF1E1E1E),
                    size: 22,
                  ),
                )
              : const Icon(
                  CupertinoIcons.bell,
                  color: Color(0xFF1E1E1E),
                  size: 22,
                ),
        ),
        const SizedBox(width: 8),
      ],
      bottom: bottom,
    );
  }

  /// Displays the interactive notifications bottom sheet
  static void showNotificationsSheet(BuildContext context, int count) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(CupertinoIcons.bell_fill, color: Color(0xFF750000), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Notifications ($count)',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E1E1E),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.xmark, size: 18),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF750000).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(CupertinoIcons.sparkles, color: Color(0xFF750000), size: 20),
                ),
                title: Text(
                  'New Daily Match Recommendations',
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'We curated compatible matrimonial matches matching your preferences.',
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(CupertinoIcons.checkmark_seal_fill, color: Colors.green, size: 20),
                ),
                title: Text(
                  'Profile Status Verified',
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Your profile details and Aadhaar status have been verified successfully.',
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
