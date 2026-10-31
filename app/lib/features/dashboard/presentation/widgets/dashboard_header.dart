import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/core_widgets.dart';

/// Reusable dashboard top header: Real Profile Image -> "Hi, {Name}!" -> Search & Notification icons.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    this.greeting = 'Hi there!',
    this.profileImageUrl,
    this.userInitials = 'KO',
    this.subtitle,
    this.hasUnreadNotifications = true,
    this.onProfileTap,
    this.onSearchTap,
    this.onNotificationTap,
  });

  final String greeting;
  final String? profileImageUrl;
  final String userInitials;
  final String? subtitle;
  final bool hasUnreadNotifications;
  final VoidCallback? onProfileTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        // 1. Real Profile Image (Circular Avatar with Lazy Loading & Fallback)
        InkWell(
          onTap: onProfileTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: AppLazyImage(
              imageUrl: profileImageUrl,
              width: 38,
              height: 38,
              isCircle: true,
              fallbackInitials: userInitials,
              fallbackIcon: LucideIcons.user,
              memCacheWidth: 100,
              memCacheHeight: 100,
            ),
          ),
        ),
        const Gap(12),

        // 2. Greeting (Hi, Ganesh!) - clean without redundant shop text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                greeting,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: colors.darkText,
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const Gap(2),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: colors.inputLabel,
                  ),
                ),
              ],
            ],
          ),
        ),

        // 3. Search Icon Button
        IconButton(
          onPressed: onSearchTap,
          tooltip: 'Search products',
          icon: Icon(
            LucideIcons.search,
            color: colors.darkText,
            size: 20,
          ),
          splashRadius: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        ),

        // 4. Notification Bell with Red Badge Dot
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: onNotificationTap,
              tooltip: 'Notifications',
              icon: Icon(
                LucideIcons.bell,
                color: colors.darkText,
                size: 20,
              ),
              splashRadius: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
            if (hasUnreadNotifications)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
