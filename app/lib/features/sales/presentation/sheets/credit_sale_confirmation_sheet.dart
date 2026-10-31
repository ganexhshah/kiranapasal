import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/models/customer.dart';

/// Modal bottom sheet to confirm charging a sale to a customer's Udhar (credit) ledger.
class CreditSaleConfirmationSheet extends StatelessWidget {
  const CreditSaleConfirmationSheet({
    super.key,
    required this.customer,
    required this.amount,
  });

  final Customer customer;
  final double amount;

  static Future<bool> show(
    BuildContext context, {
    required Customer customer,
    required double amount,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => CreditSaleConfirmationSheet(
        customer: customer,
        amount: amount,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final newBalance = customer.udharBalance + amount;
    final isLimitExceeded = newBalance > customer.creditLimit;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.inputBorder.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Gap(14),

            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(LucideIcons.bookOpen, size: 18, color: Color(0xFFD97706)),
                ),
                const Gap(10),
                Text(
                  'Confirm Udhar Sale',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: colors.darkText,
                  ),
                ),
              ],
            ),
            const Gap(16),

            // Customer Details Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Customer', style: TextStyle(fontSize: 12.5, color: colors.inputLabel)),
                      Text(customer.name, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: colors.darkText)),
                    ],
                  ),
                  const Gap(8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Current Balance', style: TextStyle(fontSize: 12.5, color: colors.inputLabel)),
                      Text('Rs. ${customer.udharBalance.toInt()}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.darkText)),
                    ],
                  ),
                  const Gap(8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('New Sale Amount', style: TextStyle(fontSize: 12.5, color: colors.inputLabel)),
                      Text('+ Rs. ${amount.toInt()}', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF0066FF))),
                    ],
                  ),
                  const Gap(10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Updated Balance', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFEA580C))),
                      Text('Rs. ${newBalance.toInt()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFEA580C))),
                    ],
                  ),
                ],
              ),
            ),
            const Gap(12),

            if (isLimitExceeded)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(LucideIcons.alertCircle, size: 16, color: Color(0xFFEF4444)),
                    Gap(8),
                    Expanded(
                      child: Text(
                        'Exceeds credit limit threshold.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFEF4444)),
                      ),
                    ),
                  ],
                ),
              ),
            const Gap(16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: colors.inputBorder.withValues(alpha: 0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Cancel', style: TextStyle(color: colors.darkText)),
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Confirm Udhar', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

