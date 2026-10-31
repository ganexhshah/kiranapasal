import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/theme.dart';
import '../../../sales/presentation/screens/transaction_details_screen.dart';

class TransactionData {
  final String title;
  final String subtitle;
  final String amount;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final Color? amountColor;
  final VoidCallback? onTap;

  const TransactionData({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    this.amountColor,
    this.onTap,
  });
}

/// Reusable section listing recent shop transactions.
class RecentTransactionsSection extends StatelessWidget {
  const RecentTransactionsSection({
    super.key,
    this.transactions,
    this.onViewAllTap,
  });

  final List<TransactionData>? transactions;
  final VoidCallback? onViewAllTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final list = transactions ?? [];

    return Column(
      children: [
        // Header Row: Recent Transactions + View All
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.darkText,
                letterSpacing: -0.2,
              ),
            ),
            InkWell(
              onTap: onViewAllTap,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const Gap(10),

        if (list.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Text(
              'No recent transactions recorded today',
              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            ),
          )
        else
          // Transactions Cards List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (context, index) => const Gap(8),
            itemBuilder: (context, index) {
              final tx = list[index];
              return _TransactionTile(data: tx);
            },
          ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.data});

  final TransactionData data;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: data.onTap ??
          () {
            final recNum = data.title.contains('#')
                ? data.title.split('#').last.trim()
                : 'RECEIPT';
            final cleanAmtStr = data.amount.replaceAll(RegExp(r'[^0-9.]'), '');
            final parsedAmt = double.tryParse(cleanAmtStr) ?? 0.0;

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => TransactionDetailsScreen(
                  receiptNumber: recNum,
                  title: data.title,
                  timestamp: DateTime.now(),
                  items: const [],
                  subtotal: parsedAmt,
                  totalAmount: parsedAmt,
                  paymentMethod: data.subtitle,
                ),
              ),
            );
          },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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
            const Gap(10),

            // Title & Subtitle column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    data.title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: colors.darkText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(2),
                  Text(
                    data.subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: colors.inputLabel,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Gap(8),

            // Amount
            Text(
              data.amount,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: data.amountColor ?? colors.darkText,
              ),
            ),
            const Gap(4),

            // Trailing Chevron
            Icon(
              Icons.chevron_right_rounded,
              color: colors.inputBorder.withValues(alpha: 0.7),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
