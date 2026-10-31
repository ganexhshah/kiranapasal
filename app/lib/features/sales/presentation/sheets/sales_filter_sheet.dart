import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/theme.dart';

class SalesFilterOptions {
  final String datePeriod;
  final String paymentMethod;
  final String status;

  const SalesFilterOptions({
    this.datePeriod = 'Today',
    this.paymentMethod = 'All',
    this.status = 'Completed',
  });
}

/// Modal bottom sheet to filter sales reports by period and payment method.
class SalesFilterSheet extends StatefulWidget {
  const SalesFilterSheet({
    super.key,
    this.initialOptions = const SalesFilterOptions(),
  });

  final SalesFilterOptions initialOptions;

  static Future<SalesFilterOptions?> show(
    BuildContext context, {
    SalesFilterOptions initialOptions = const SalesFilterOptions(),
  }) {
    return showModalBottomSheet<SalesFilterOptions>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SalesFilterSheet(initialOptions: initialOptions),
    );
  }

  @override
  State<SalesFilterSheet> createState() => _SalesFilterSheetState();
}

class _SalesFilterSheetState extends State<SalesFilterSheet> {
  late String _datePeriod;
  late String _paymentMethod;

  @override
  void initState() {
    super.initState();
    _datePeriod = widget.initialOptions.datePeriod;
    _paymentMethod = widget.initialOptions.paymentMethod;
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
              'Filter Sales Records',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colors.darkText),
            ),
            const Gap(14),

            Text('Time Period', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: colors.inputLabel)),
            const Gap(8),
            Wrap(
              spacing: 8,
              children: ['Today', 'Yesterday', 'This Week', 'This Month'].map((p) {
                final isSelected = p == _datePeriod;
                return ChoiceChip(
                  label: Text(p),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _datePeriod = p),
                  selectedColor: const Color(0xFF0066FF),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : colors.darkText,
                  ),
                  backgroundColor: const Color(0xFFF1F5F9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  side: BorderSide.none,
                );
              }).toList(),
            ),
            const Gap(14),

            Text('Payment Method', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: colors.inputLabel)),
            const Gap(8),
            Wrap(
              spacing: 8,
              children: ['All', 'Cash', 'QR / Fonepay', 'Card', 'Udhar'].map((m) {
                final isSelected = m == _paymentMethod;
                return ChoiceChip(
                  label: Text(m),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _paymentMethod = m),
                  selectedColor: const Color(0xFF0066FF),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : colors.darkText,
                  ),
                  backgroundColor: const Color(0xFFF1F5F9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  side: BorderSide.none,
                );
              }).toList(),
            ),
            const Gap(20),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    SalesFilterOptions(
                      datePeriod: _datePeriod,
                      paymentMethod: _paymentMethod,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

