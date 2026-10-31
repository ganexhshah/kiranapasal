import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme.dart';
import '../../../sales/domain/models/customer.dart';

/// Clean, lineless customer card showing profile details, udhar status, and quick actions.
class CustomerCard extends StatelessWidget {
  const CustomerCard({
    super.key,
    required this.customer,
    required this.onTap,
    required this.onReceivePayment,
    required this.onMoreOptions,
  });

  final Customer customer;
  final VoidCallback onTap;
  final VoidCallback onReceivePayment;
  final VoidCallback onMoreOptions;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasUdhar = customer.udharBalance > 0;
    final initials = customer.name.trim().isNotEmpty
        ? customer.name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join()
        : 'C';

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
                      backgroundColor: hasUdhar ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9),
                      child: Text(
                        initials,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: hasUdhar ? const Color(0xFFDC2626) : const Color(0xFF475569),
                        ),
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
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
                                customer.phone.isNotEmpty ? customer.phone : 'No phone',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.inputLabel,
                                ),
                              ),
                              if (customer.address.isNotEmpty) ...[
                                const Gap(8),
                                Text('•', style: TextStyle(color: colors.inputBorder)),
                                const Gap(8),
                                Expanded(
                                  child: Text(
                                    customer.address,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colors.inputLabel,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
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

                // Middle Row: Udhar Status & Credit Limit
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
                              color: hasUdhar ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              hasUdhar
                                  ? 'Udhar: Rs. ${customer.udharBalance.toInt()}'
                                  : 'No Udhar (Settled)',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: hasUdhar ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Limit: Rs. ${customer.creditLimit.toInt()}',
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
                    if (hasUdhar) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onReceivePayment,
                          icon: const Icon(LucideIcons.arrowDownLeft, size: 14),
                          label: const Text(
                            'Receive Udhar',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
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
                    ],
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onTap,
                        icon: const Icon(LucideIcons.bookOpen, size: 14),
                        label: const Text(
                          'View Ledger',
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

