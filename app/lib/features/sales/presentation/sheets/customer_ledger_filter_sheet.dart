import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/theme.dart';

enum LedgerFilterType { all, creditSales, repayments, pendingOnly }

/// Modal bottom sheet to filter customer ledger entries by transaction type.
class CustomerLedgerFilterSheet extends StatelessWidget {
  const CustomerLedgerFilterSheet({
    super.key,
    this.selected = LedgerFilterType.all,
  });

  final LedgerFilterType selected;

  static Future<LedgerFilterType?> show(
    BuildContext context, {
    LedgerFilterType selected = LedgerFilterType.all,
  }) {
    return showModalBottomSheet<LedgerFilterType>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => CustomerLedgerFilterSheet(selected: selected),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final options = [
      (LedgerFilterType.all, 'All Transactions'),
      (LedgerFilterType.creditSales, 'Udhar Sales Only'),
      (LedgerFilterType.repayments, 'Payments Received Only'),
      (LedgerFilterType.pendingOnly, 'Pending Balances Only'),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Text(
              'Filter Customer Ledger',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colors.darkText),
            ),
            const Gap(14),
            ...options.map((opt) {
              final isChosen = opt.$1 == selected;
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                title: Text(
                  opt.$2,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isChosen ? FontWeight.w700 : FontWeight.w500,
                    color: isChosen ? const Color(0xFF0066FF) : colors.darkText,
                  ),
                ),
                trailing: isChosen ? const Icon(Icons.check, color: Color(0xFF0066FF), size: 18) : null,
                onTap: () => Navigator.pop(context, opt.$1),
              );
            }),
          ],
        ),
      ),
    );
  }
}

