import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/services/printing_service.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/models/sale_record.dart';

/// Modal bottom sheet celebrating sale completion with receipt printing and sharing.
class SaleSuccessSheet extends StatelessWidget {
  const SaleSuccessSheet({
    super.key,
    required this.sale,
  });

  final SaleRecord sale;

  static Future<void> show(
    BuildContext context, {
    required SaleRecord sale,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SaleSuccessSheet(sale: sale),
    );
  }

  InvoicePrintData _toInvoiceData() {
    return InvoicePrintData(
      invoiceNumber: sale.receiptNumber,
      date: sale.timestamp,
      customerName: sale.customer.name,
      customerPhone: sale.customer.phone,
      items: sale.items
          .map((item) => InvoiceItemData(
                name: item.product.name,
                quantity: item.quantity,
                unit: item.unit,
                unitPrice: item.rate,
                total: item.total,
              ))
          .toList(),
      subtotal: sale.subtotal,
      discount: sale.discountAmount,
      tax: sale.taxAmount,
      charges: sale.additionalCharges,
      grandTotal: sale.totalAmount,
      paymentMethod: sale.paymentMethodName,
      cashReceived: sale.cashReceived,
      changeDue: sale.changeReturned,
      note: sale.note,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isInt = sale.totalAmount == sale.totalAmount.roundToDouble();
    final amountStr = isInt ? sale.totalAmount.toInt().toString() : sale.totalAmount.toStringAsFixed(2);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Big Green Checkmark
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.check, size: 32, color: Color(0xFF16A34A)),
            ),
            const Gap(14),

            Text(
              'Sale Completed!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: colors.darkText,
              ),
            ),
            const Gap(4),

            Text(
              'Receipt ${sale.receiptNumber}',
              style: TextStyle(fontSize: 13, color: colors.inputLabel),
            ),
            const Gap(16),

            // Receipt Summary Card
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
                      Text(sale.customer.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.darkText)),
                    ],
                  ),
                  const Gap(8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Payment Method', style: TextStyle(fontSize: 12.5, color: colors.inputLabel)),
                      Text(sale.paymentMethodName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0066FF))),
                    ],
                  ),
                  const Gap(8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Items Purchased', style: TextStyle(fontSize: 12.5, color: colors.inputLabel)),
                      Text('${sale.items.length} items', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.darkText)),
                    ],
                  ),
                  const Gap(10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount Paid', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                      Text('Rs. $amountStr', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF16A34A))),
                    ],
                  ),
                ],
              ),
            ),
            const Gap(18),

            // Print & Share Action Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await PrintingService.instance.printInvoice(_toInvoiceData());
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Print failed: $e')),
                          );
                        }
                      }
                    },
                    icon: const Icon(LucideIcons.printer, size: 16),
                    label: const Text('Print Receipt', style: TextStyle(fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: colors.inputBorder.withValues(alpha: 0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await PrintingService.instance.shareInvoicePdf(_toInvoiceData());
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Share failed: $e')),
                          );
                        }
                      }
                    },
                    icon: const Icon(LucideIcons.share2, size: 16),
                    label: const Text('Share Receipt', style: TextStyle(fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: colors.inputBorder.withValues(alpha: 0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const Gap(10),

            // Start New Sale Primary Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Start New Sale', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

