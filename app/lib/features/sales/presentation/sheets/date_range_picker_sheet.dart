import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme.dart';

class CustomDateRange {
  final DateTime from;
  final DateTime to;

  const CustomDateRange({
    required this.from,
    required this.to,
  });
}

/// Modal bottom sheet to select a custom date range for business analytics.
class DateRangePickerSheet extends StatefulWidget {
  const DateRangePickerSheet({
    super.key,
    this.initialRange,
  });

  final CustomDateRange? initialRange;

  static Future<CustomDateRange?> show(
    BuildContext context, {
    CustomDateRange? initialRange,
  }) {
    return showModalBottomSheet<CustomDateRange>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DateRangePickerSheet(initialRange: initialRange),
    );
  }

  @override
  State<DateRangePickerSheet> createState() => _DateRangePickerSheetState();
}

class _DateRangePickerSheetState extends State<DateRangePickerSheet> {
  late DateTime _from;
  late DateTime _to;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = widget.initialRange?.from ?? now.subtract(const Duration(days: 7));
    _to = widget.initialRange?.to ?? now;
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _from : _to,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isFrom) {
          _from = picked;
          if (_from.isAfter(_to)) _to = _from;
        } else {
          _to = picked;
          if (_to.isBefore(_from)) _from = _to;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final formatter = DateFormat('dd MMM yyyy');

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
              'Select Date Range',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colors.darkText),
            ),
            const Gap(16),

            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(isFrom: true),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('From Date', style: TextStyle(fontSize: 11.5, color: colors.inputLabel)),
                          const Gap(4),
                          Text(formatter.format(_from), style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: colors.darkText)),
                        ],
                      ),
                    ),
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(isFrom: false),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('To Date', style: TextStyle(fontSize: 11.5, color: colors.inputLabel)),
                          const Gap(4),
                          Text(formatter.format(_to), style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: colors.darkText)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Gap(20),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, CustomDateRange(from: _from, to: _to)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Apply Date Range', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

