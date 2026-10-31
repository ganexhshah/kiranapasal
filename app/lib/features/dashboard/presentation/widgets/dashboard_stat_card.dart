import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme.dart';

class DashboardStatData {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final Color? valueColor;
  final VoidCallback? onTap;

  const DashboardStatData({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    this.valueColor,
    this.onTap,
  });
}

/// Compact, lineless individual statistic card.
class DashboardStatCard extends StatelessWidget {
  const DashboardStatCard({
    super.key,
    required this.data,
  });

  final DashboardStatData data;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FC),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: data.iconBackgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  data.icon,
                  color: data.iconColor,
                  size: 18,
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
                    data.title,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: colors.inputLabel,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(1),
                  Text(
                    data.value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: data.valueColor ?? colors.darkText,
                    ),
                  ),
                ],
              ),
            ),

            // Trailing Chevron
            Icon(
              Icons.chevron_right_rounded,
              color: colors.inputBorder.withValues(alpha: 0.7),
              size: 17,
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact 2x2 Grid widget organizing the 4 dashboard stat cards.
class DashboardStatsGrid extends StatelessWidget {
  const DashboardStatsGrid({
    super.key,
    this.totalProducts = '248',
    this.totalCustomers = '86',
    this.lowStockItems = '12',
    this.todaysBills = '18',
    this.onProductsTap,
    this.onCustomersTap,
    this.onLowStockTap,
    this.onBillsTap,
  });

  final String totalProducts;
  final String totalCustomers;
  final String lowStockItems;
  final String todaysBills;
  final VoidCallback? onProductsTap;
  final VoidCallback? onCustomersTap;
  final VoidCallback? onLowStockTap;
  final VoidCallback? onBillsTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DashboardStatCard(
                data: DashboardStatData(
                  title: 'Total Products',
                  value: totalProducts,
                  icon: LucideIcons.package,
                  iconColor: const Color(0xFF0866FF),
                  iconBackgroundColor: const Color(0xFFE8F1FF),
                  onTap: onProductsTap,
                ),
              ),
            ),
            const Gap(10),
            Expanded(
              child: DashboardStatCard(
                data: DashboardStatData(
                  title: 'Total Customers',
                  value: totalCustomers,
                  icon: LucideIcons.users,
                  iconColor: const Color(0xFF10B981),
                  iconBackgroundColor: const Color(0xFFE6F8F0),
                  onTap: onCustomersTap,
                ),
              ),
            ),
          ],
        ),
        const Gap(10),
        Row(
          children: [
            Expanded(
              child: DashboardStatCard(
                data: DashboardStatData(
                  title: 'Low Stock Items',
                  value: lowStockItems,
                  icon: LucideIcons.shoppingCart,
                  iconColor: const Color(0xFFF59E0B),
                  iconBackgroundColor: const Color(0xFFFFF4E6),
                  valueColor: const Color(0xFFEF4444),
                  onTap: onLowStockTap,
                ),
              ),
            ),
            const Gap(10),
            Expanded(
              child: DashboardStatCard(
                data: DashboardStatData(
                  title: "Today's Bills",
                  value: todaysBills,
                  icon: LucideIcons.fileText,
                  iconColor: const Color(0xFF7C3AED),
                  iconBackgroundColor: const Color(0xFFF4EEFF),
                  onTap: onBillsTap,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
