import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme.dart';

/// Compact, clean Deep Blue card for Today's Sales with zero neon glow.
class TodaySalesCard extends StatelessWidget {
  const TodaySalesCard({
    super.key,
    this.title = "Today's Sales",
    this.date = 'Tue, 27 Oct 2026',
    this.totalSales = 'Rs. 12,450.00',
    this.cashAmount = 'Rs. 9,450',
    this.cardAmount = 'Rs. 1,500',
    this.udharAmount = 'Rs. 1,500',
    this.onMoreTap,
  });

  final String title;
  final String date;
  final String totalSales;
  final String cashAmount;
  final String cardAmount;
  final String udharAmount;
  final VoidCallback? onMoreTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.deepBlueCards,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title, Date & More Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: onMoreTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    LucideIcons.moreVertical,
                    color: Colors.white.withValues(alpha: 0.85),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const Gap(10),

          // Total Sales Display (Right Aligned)
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  totalSales,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
                const Gap(1),
                Text(
                  'Total Sales',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
          const Gap(14),

          // Bottom Breakdown Row (Cash, Card, Udhar)
          Row(
            children: [
              Expanded(
                child: _BreakdownItem(
                  label: 'Cash',
                  amount: cashAmount,
                  icon: LucideIcons.wallet,
                ),
              ),
              const Gap(8),
              Expanded(
                child: _BreakdownItem(
                  label: 'Card',
                  amount: cardAmount,
                  icon: LucideIcons.creditCard,
                ),
              ),
              const Gap(8),
              Expanded(
                child: _BreakdownItem(
                  label: 'Udhar',
                  amount: udharAmount,
                  icon: LucideIcons.clock,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BreakdownItem extends StatelessWidget {
  const _BreakdownItem({
    required this.label,
    required this.amount,
    required this.icon,
  });

  final String label;
  final String amount;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Rounded semi-transparent icon box
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(
              icon,
              color: Colors.white,
              size: 15,
            ),
          ),
        ),
        const Gap(6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const Gap(1),
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
