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
  final bool showNotification;
  final VoidCallback? onNotificationPressed;
  final List<Widget>? actions;
  final List<Widget>? trailingActions;
  final Color backgroundColor;
  final PreferredSizeWidget? bottom;
  final double? leadingWidth;

  const RaniTopBar({
    super.key,
    this.title,
    this.titleWidget,
    this.showLeading = true,
    this.leading,
    this.onMenuPressed,
    this.notificationCount = 3,
    this.showNotification = true,
    this.onNotificationPressed,
    this.actions,
    this.trailingActions,
    this.backgroundColor = const Color(0xFFFAF7F2),
    this.bottom,
    this.leadingWidth,
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
      leadingWidth: leadingWidth,
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
        if (showNotification)
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
        ...?trailingActions,
        if (showNotification || (actions != null && actions!.isNotEmpty) || (trailingActions != null && trailingActions!.isNotEmpty))
          const SizedBox(width: 8),
      ],
      bottom: bottom,
    );
  }

  /// Displays the interactive notifications bottom sheet with real live data
  static void showNotificationsSheet(
    BuildContext context,
    int count, {
    List<dynamic>? notifications,
    Function(dynamic notif)? onNotificationTap,
    Function(dynamic notif)? onNotificationDismiss,
    VoidCallback? onDismissAll,
  }) {
    final list = notifications != null ? List<dynamic>.from(notifications) : <dynamic>[];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return SafeArea(
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
                            'Notifications (${list.length})',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E1E1E),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (list.isNotEmpty && onDismissAll != null)
                            GestureDetector(
                              onTap: () {
                                setSheetState(() {
                                  list.clear();
                                });
                                onDismissAll();
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Text(
                                  'Clear All',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF750000),
                                  ),
                                ),
                              ),
                            ),
                          IconButton(
                            icon: const Icon(CupertinoIcons.xmark, size: 18),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (list.isNotEmpty)
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const Divider(color: Color(0xFFF0EBE4), height: 1),
                        itemBuilder: (context, index) {
                          final notif = list[index];
                          final title = notif['name'] ?? notif['title'] ?? 'Notification';
                          final text = notif['text'] ?? notif['message'] ?? '';
                          final time = notif['time_ago'] ?? notif['time'] ?? 'Recently';
                          final isNew = notif['is_new'] == true;
                          final photo = notif['photo']?.toString();
                          final badge = notif['badge']?.toString();

                          return Dismissible(
                            key: ValueKey('notif_${notif['id'] ?? index}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(CupertinoIcons.trash, color: Colors.white, size: 20),
                            ),
                            onDismissed: (_) {
                              final dismissed = list.removeAt(index);
                              setSheetState(() {});
                              onNotificationDismiss?.call(dismissed);
                            },
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 4),
                              onTap: () {
                                final tapped = notif;
                                setSheetState(() {
                                  list.removeAt(index);
                                });
                                Navigator.pop(ctx);
                                onNotificationTap?.call(tapped);
                              },
                              leading: photo != null && photo.isNotEmpty && !photo.contains('sparkles')
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.network(
                                        photo,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF750000).withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(CupertinoIcons.sparkles, color: Color(0xFF750000), size: 20),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isNew
                                            ? const Color(0xFF750000).withValues(alpha: 0.12)
                                            : Colors.grey.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        CupertinoIcons.sparkles,
                                        color: isNew ? const Color(0xFF750000) : Colors.grey.shade600,
                                        size: 20,
                                      ),
                                    ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: isNew ? FontWeight.w700 : FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (badge != null && badge.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        badge,
                                        style: GoogleFonts.outfit(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  if (isNew) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF750000),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 2),
                                  Text(
                                    text,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    time,
                                    style: GoogleFonts.outfit(
                                      fontSize: 10.5,
                                      color: const Color(0xFF750000),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.bell_slash, size: 36, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          Text(
                            'No active notifications. You are all caught up!',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
