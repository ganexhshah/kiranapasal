import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme.dart';

/// Modal bottom sheet allowing users to quickly pick Today, Yesterday, or custom calendar dates to view bills.
class BillDatePickerSheet extends StatelessWidget {
  const BillDatePickerSheet({
    super.key,
    required this.selectedDate,
  });

  final DateTime selectedDate;

  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime selectedDate,
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => BillDatePickerSheet(selectedDate: selectedDate),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDaysAgo = today.subtract(const Duration(days: 2));
    final threeDaysAgo = today.subtract(const Duration(days: 3));

    final presets = [
      {'label': 'Today', 'date': today, 'sub': DateFormat('EEE, dd MMM yyyy').format(today)},
      {'label': 'Yesterday', 'date': yesterday, 'sub': DateFormat('EEE, dd MMM yyyy').format(yesterday)},
      {'label': '2 Days Ago', 'date': twoDaysAgo, 'sub': DateFormat('EEE, dd MMM yyyy').format(twoDaysAgo)},
      {'label': '3 Days Ago', 'date': threeDaysAgo, 'sub': DateFormat('EEE, dd MMM yyyy').format(threeDaysAgo)},
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Gap(16),

            // Sheet Title & Close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Bills Date',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: colors.darkText,
                    letterSpacing: -0.3,
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 18),
                  onPressed: () => Navigator.pop(context),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const Gap(14),

            // Quick Preset Tiles
            ...presets.map((preset) {
              final date = preset['date'] as DateTime;
              final isSelected = _isSameDay(selectedDate, date);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => Navigator.pop(context, date),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF0066FF) : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.calendar,
                              size: 16,
                              color: isSelected ? const Color(0xFF0066FF) : const Color(0xFF64748B),
                            ),
                            const Gap(10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  preset['label'] as String,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? const Color(0xFF0066FF) : const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  preset['sub'] as String,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (isSelected)
                          const Icon(
                            LucideIcons.check,
                            size: 18,
                            color: Color(0xFF0066FF),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const Gap(6),

            // Calendar Custom Date Picker Button
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate.isAfter(today) ? today : selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: today,
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Color(0xFF0066FF),
                          onPrimary: Colors.white,
                          onSurface: Color(0xFF0F172A),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );

                if (picked != null && context.mounted) {
                  Navigator.pop(context, picked);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.calendarDays, size: 16, color: Color(0xFF0066FF)),
                    Gap(8),
                    Text(
                      'Choose Custom Date from Calendar',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0066FF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
