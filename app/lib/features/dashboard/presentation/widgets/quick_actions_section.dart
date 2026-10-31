import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme.dart';

class QuickActionData {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback? onTap;

  const QuickActionData({
    required this.label,
    required this.icon,
    this.backgroundColor = const Color(0xFFF0F2FA),
    this.iconColor = const Color(0xFF292D38),
    this.onTap,
  });
}

/// Reusable Quick Actions row displaying 4 action items (New Sale, Products, Customers, View All).
class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({
    super.key,
    this.actions,
    this.onNewSale,
    this.onProducts,
    this.onCustomers,
    this.onViewAll,
  });

  final List<QuickActionData>? actions;
  final VoidCallback? onNewSale;
  final VoidCallback? onProducts;
  final VoidCallback? onCustomers;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final defaultActions = [
      QuickActionData(
        label: 'New Sale',
        icon: LucideIcons.shoppingCart,
        backgroundColor: const Color(0xFFE8F1FF),
        iconColor: const Color(0xFF0866FF),
        onTap: onNewSale,
      ),
      QuickActionData(
        label: 'Products',
        icon: LucideIcons.package,
        backgroundColor: const Color(0xFFF4EEFF),
        iconColor: const Color(0xFF7C3AED),
        onTap: onProducts,
      ),
      QuickActionData(
        label: 'Customers',
        icon: LucideIcons.users,
        backgroundColor: const Color(0xFFFFF4E6),
        iconColor: const Color(0xFFF59E0B),
        onTap: onCustomers,
      ),
      QuickActionData(
        label: 'View All',
        icon: LucideIcons.layoutGrid,
        backgroundColor: const Color(0xFFE6F8F0),
        iconColor: const Color(0xFF10B981),
        onTap: onViewAll,
      ),
    ];

    final items = actions ?? defaultActions;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items.map((action) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _QuickActionButton(action: action),
          ),
        );
      }).toList(),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.action});

  final QuickActionData action;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: action.onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: action.backgroundColor,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.025),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                action.icon,
                color: action.iconColor,
                size: 20,
              ),
            ),
          ),
        ),
        const Gap(6),
        Text(
          action.label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: colors.darkText,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

