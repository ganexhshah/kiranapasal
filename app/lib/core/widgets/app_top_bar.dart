import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/theme.dart';

/// Standard, unified top bar for screens with a back button, title, and action widgets.
/// Guarantees consistent 56px height, consistent status-bar/notch spacing, and unified typography.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.onBack,
    this.leading,
    this.actions,
    this.bottom,
    this.titleStyle,
    this.centerTitle = false,
  });

  final String title;
  final bool showBackButton;
  final VoidCallback? onBack;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final TextStyle? titleStyle;
  final bool centerTitle;

  @override
  Size get preferredSize => Size.fromHeight(56.0 + (bottom?.preferredSize.height ?? 0.0));

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 56.0,
      centerTitle: centerTitle,
      titleSpacing: (showBackButton || leading != null) ? 0 : 16,
      leading: leading ??
          (showBackButton
              ? IconButton(
                  icon: Icon(LucideIcons.arrowLeft, size: 20, color: colors.darkText),
                  splashRadius: 20,
                  tooltip: 'Back',
                  onPressed: onBack ?? () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                )
              : null),
      title: Text(
        title,
        style: titleStyle ??
            TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colors.darkText,
              letterSpacing: -0.3,
            ),
      ),
      actions: actions != null ? [...actions!, const Gap(6)] : null,
      bottom: bottom,
    );
  }
}

