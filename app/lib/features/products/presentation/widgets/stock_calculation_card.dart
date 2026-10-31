import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme.dart';

/// Reusable card displaying live automatic stock calculation and financial estimates.
class StockCalculationCard extends StatelessWidget {
  const StockCalculationCard({
    super.key,
    required this.purchaseQuantity,
    required this.purchaseUnit,
    required this.quantityPerPurchaseUnit,
    required this.sellingUnit,
    this.purchasePricePerUnit,
    this.sellingPricePerUnit,
  });

  final double purchaseQuantity;
  final String purchaseUnit;
  final double quantityPerPurchaseUnit;
  final String sellingUnit;
  final double? purchasePricePerUnit;
  final double? sellingPricePerUnit;

  double get totalCalculatedStock => purchaseQuantity * quantityPerPurchaseUnit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final currencyFormatter = NumberFormat('#,##0.00');

    final hasValidStock = totalCalculatedStock > 0;
    final totalStockFormatted = hasValidStock
        ? (totalCalculatedStock == totalCalculatedStock.roundToDouble()
            ? totalCalculatedStock.toInt().toString()
            : totalCalculatedStock.toStringAsFixed(1))
        : '0';

    final totalPurchaseCost = (purchasePricePerUnit != null && purchasePricePerUnit! > 0)
        ? (purchaseQuantity * purchasePricePerUnit!)
        : null;

    final totalSellingValue = (sellingPricePerUnit != null && sellingPricePerUnit! > 0 && hasValidStock)
        ? (totalCalculatedStock * sellingPricePerUnit!)
        : null;

    final estimatedProfit = (totalSellingValue != null && totalPurchaseCost != null)
        ? (totalSellingValue - totalPurchaseCost)
        : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    LucideIcons.calculator,
                    color: colors.primary,
                    size: 16,
                  ),
                ),
              ),
              const Gap(10),
              Text(
                'Live Stock Calculation',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: colors.darkText,
                ),
              ),
            ],
          ),
          const Gap(12),

          // Formula Display Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${purchaseQuantity > 0 ? (purchaseQuantity == purchaseQuantity.roundToDouble() ? purchaseQuantity.toInt() : purchaseQuantity) : 0} $purchaseUnit × ${quantityPerPurchaseUnit > 0 ? (quantityPerPurchaseUnit == quantityPerPurchaseUnit.roundToDouble() ? quantityPerPurchaseUnit.toInt() : quantityPerPurchaseUnit) : 0} $sellingUnit',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: colors.inputLabel,
                  ),
                ),
                Text(
                  '= $totalStockFormatted $sellingUnit',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
          const Gap(10),

          // Total Stock Highlight Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Available Stock:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.darkText,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F8F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$totalStockFormatted $sellingUnit',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),

          // Optional Financial Insights
          if (totalPurchaseCost != null || totalSellingValue != null) ...[
            const Gap(10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  if (totalPurchaseCost != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Purchase Cost:',
                          style: TextStyle(fontSize: 11.5, color: colors.inputLabel),
                        ),
                        Text(
                          'Rs. ${currencyFormatter.format(totalPurchaseCost)}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.darkText),
                        ),
                      ],
                    ),
                  if (totalSellingValue != null) ...[
                    const Gap(4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Selling Revenue:',
                          style: TextStyle(fontSize: 11.5, color: colors.inputLabel),
                        ),
                        Text(
                          'Rs. ${currencyFormatter.format(totalSellingValue)}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.primary),
                        ),
                      ],
                    ),
                  ],
                  if (estimatedProfit != null) ...[
                    const Gap(4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Estimated Profit:',
                          style: TextStyle(fontSize: 11.5, color: colors.inputLabel),
                        ),
                        Text(
                          '${estimatedProfit >= 0 ? '+' : ''}Rs. ${currencyFormatter.format(estimatedProfit)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: estimatedProfit >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

