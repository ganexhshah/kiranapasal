import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme.dart';

/// Top summary statistic cards for the supplier screen.
class SupplierStatsRow extends StatelessWidget {
  const SupplierStatsRow({
    super.key,
    required this.totalSuppliers,
    required this.totalPayable,
    required this.suppliersWithBalance,
  });

  final int totalSuppliers;
  final double totalPayable;
  final int suppliersWithBalance;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        // Total Suppliers
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
                    Icon(LucideIcons.truck, size: 14, color: colors.inputLabel),
                    const Gap(6),
                    Text(
                      'Suppliers',
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
                  '$totalSuppliers',
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

        // Total Outstanding Payable
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
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
                        Icon(LucideIcons.arrowUpRight, size: 14, color: Color(0xFFDC2626)),
                        Gap(6),
                        Text(
                          'Total Payable',
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
                        '$suppliersWithBalance due',
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
                  'Rs. ${totalPayable.toInt()}',
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

