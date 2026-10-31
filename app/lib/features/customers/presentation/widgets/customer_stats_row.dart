import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme.dart';

/// Top summary statistic cards for the customer screen.
class CustomerStatsRow extends StatelessWidget {
  const CustomerStatsRow({
    super.key,
    required this.totalCustomers,
    required this.totalUdhar,
    required this.customersWithUdhar,
  });

  final int totalCustomers;
  final double totalUdhar;
  final int customersWithUdhar;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        // Total Customers
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.users, size: 14, color: colors.inputLabel),
                    const Gap(6),
                    Text(
                      'Customers',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: colors.inputLabel,
                      ),
                    ),
                  ],
                ),
                const Gap(6),
                Text(
                  '$totalCustomers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colors.darkText,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Gap(10),

        // Total Udhar
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(LucideIcons.receipt, size: 14, color: Color(0xFFDC2626)),
                        Gap(6),
                        Text(
                          'Total Udhar Due',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$customersWithUdhar due',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(6),
                Text(
                  'Rs. ${totalUdhar.toInt()}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

