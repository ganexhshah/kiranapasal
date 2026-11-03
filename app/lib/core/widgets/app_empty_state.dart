import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/theme.dart';

/// Clean empty state display with icon, title, description, and optional action.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    required this.description,
    this.icon = LucideIcons.packageOpen,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 26,
                color: colors.inputLabel,
              ),
            ),
            const Gap(14),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colors.darkText,
              ),
              textAlign: TextAlign.center,
            ),
            const Gap(4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12.5,
                color: colors.inputLabel,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onActionTap != null) ...[
              const Gap(16),
              TextButton(
                onPressed: onActionTap,
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

