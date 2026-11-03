import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/models/supplier.dart';

/// Modal bottom sheet to view and update supplier outstanding balance records.
class SupplierCreditSheet extends StatelessWidget {
  const SupplierCreditSheet({
    super.key,
    required this.supplier,
  });

  final Supplier supplier;

  static Future<void> show(
    BuildContext context, {
    required Supplier supplier,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SupplierCreditSheet(supplier: supplier),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

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
              'Supplier Credit & Payables',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colors.darkText),
            ),
            const Gap(14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Supplier Name', style: TextStyle(fontSize: 12.5, color: colors.inputLabel)),
                      Text(supplier.name, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: colors.darkText)),
                    ],
                  ),
                  const Gap(8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('PAN / VAT', style: TextStyle(fontSize: 12.5, color: colors.inputLabel)),
                      Text(supplier.panNumber.isNotEmpty ? supplier.panNumber : 'N/A', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.darkText)),
                    ],
                  ),
                  const Gap(10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Outstanding Due', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                      Text('Rs. ${supplier.outstandingBalance.toInt()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFFEF4444))),
                    ],
                  ),
                ],
              ),
            ),
            const Gap(16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

