import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme.dart';
import '../../../sales/domain/models/supplier.dart';

/// Clean, lineless supplier card showing distributor details, balance, and purchase actions.
class SupplierCard extends StatelessWidget {
  const SupplierCard({
    super.key,
    required this.supplier,
    required this.onTap,
    required this.onRecordPurchase,
    required this.onPaySupplier,
    required this.onMoreOptions,
  });

  final Supplier supplier;
  final VoidCallback onTap;
  final VoidCallback onRecordPurchase;
  final VoidCallback onPaySupplier;
  final VoidCallback onMoreOptions;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasBalance = supplier.outstandingBalance > 0;
    final initials = supplier.name.trim().isNotEmpty
        ? supplier.name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join()
        : 'S';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar, Info & More Options
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFF1F5F9),
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            supplier.name,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: colors.darkText,
                            ),
                          ),
                          const Gap(2),
                          Row(
                            children: [
                              Icon(LucideIcons.phone, size: 12, color: colors.inputLabel),
                              const Gap(4),
                              Text(
                                supplier.phone,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.inputLabel,
                                ),
                              ),
                              if (supplier.panNumber.isNotEmpty) ...[
                                const Gap(8),
                                Text('•', style: TextStyle(color: colors.inputBorder)),
                                const Gap(8),
                                Text(
                                  'PAN: ${supplier.panNumber}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.inputLabel,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (supplier.address.isNotEmpty) ...[
                            const Gap(2),
                            Text(
                              supplier.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: colors.inputLabel,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(LucideIcons.moreVertical, size: 18, color: colors.inputLabel),
                      onPressed: onMoreOptions,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
                const Gap(12),

                // Middle Row: Balance Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: hasBalance ? const Color(0xFFFEF2F2) : const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              hasBalance
                                  ? 'Payable: Rs. ${supplier.outstandingBalance.toInt()}'
                                  : 'Settled (No Dues)',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: hasBalance ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Distributor',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: colors.inputLabel,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(10),

                // Bottom Row: Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onRecordPurchase,
                        icon: const Icon(LucideIcons.packagePlus, size: 14),
                        label: const Text(
                          'Purchase',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const Gap(8),
                    if (hasBalance) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onPaySupplier,
                          icon: const Icon(LucideIcons.arrowUpRight, size: 14),
                          label: const Text(
                            'Pay Due',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                            side: const BorderSide(color: Color(0xFFFECACA)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onTap,
                          icon: const Icon(LucideIcons.fileSpreadsheet, size: 14),
                          label: const Text(
                            'Statement',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.darkText,
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

