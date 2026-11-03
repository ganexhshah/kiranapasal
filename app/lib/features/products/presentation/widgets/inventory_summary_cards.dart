import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme.dart';

/// Reusable compact inventory summary row containing 2 stat cards: Total Products & Low Stock Items.
class InventorySummaryCards extends StatelessWidget {
  const InventorySummaryCards({
    super.key,
    this.totalProducts = '248',
    this.lowStockItems = '12',
    this.onTotalProductsTap,
    this.onLowStockItemsTap,
  });

  final String totalProducts;
  final String lowStockItems;
  final VoidCallback? onTotalProductsTap;
  final VoidCallback? onLowStockItemsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Total Products Card
        Expanded(
          child: _CompactInventoryCard(
            title: 'Total Products',
            value: totalProducts,
            icon: LucideIcons.package,
            iconColor: const Color(0xFF2563EB),
            iconBackgroundColor: const Color(0xFFE8F1FF),
            onTap: onTotalProductsTap,
          ),
        ),
        const Gap(10),

        // Low Stock Items Card
        Expanded(
          child: _CompactInventoryCard(
            title: 'Low Stock Items',
            value: lowStockItems,
            icon: LucideIcons.package,
            iconColor: const Color(0xFFEF4444),
            iconBackgroundColor: const Color(0xFFFEECEC),
            valueColor: const Color(0xFFEF4444),
            onTap: onLowStockItemsTap,
          ),
        ),
      ],
    );
  }
}

class _CompactInventoryCard extends StatelessWidget {
  const _CompactInventoryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    this.valueColor,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final Color? valueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FC),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 16,
                ),
              ),
            ),
            const Gap(8),

            // Content column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: colors.inputLabel,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(1),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: valueColor ?? colors.darkText,
                    ),
                  ),
                ],
              ),
            ),

            // Trailing Chevron
            Icon(
              Icons.chevron_right_rounded,
              color: colors.inputBorder.withValues(alpha: 0.7),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

