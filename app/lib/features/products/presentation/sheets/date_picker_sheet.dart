import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme.dart';

/// Lineless bottom sheet modal to select an expiry date with quick preset suggestions.
/// Supports clearing the date when [canClear] is true.
class DatePickerSheet extends StatefulWidget {
  const DatePickerSheet({
    super.key,
    this.initialDate,
    this.canClear = false,
  });

  final DateTime? initialDate;
  final bool canClear;

  static Future<DateTime?> show(
    BuildContext context, {
    DateTime? initialDate,
    bool canClear = false,
  }) {
    return showModalBottomSheet<DateTime?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => DatePickerSheet(
        initialDate: initialDate,
        canClear: canClear,
      ),
    );
  }

  @override
  State<DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<DatePickerSheet> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now().add(const Duration(days: 90));
  }

  void _selectPreset(Duration duration) {
    setState(() {
      _selectedDate = DateTime.now().add(duration);
    });
  }

  Future<void> _pickFromCalendar() async {
    final now = DateTime.now();
    // Allow past dates when the item already expired, otherwise showDatePicker
    // asserts because initialDate < firstDate.
    final existing = _selectedDate;
    final firstAllowed =
        (existing != null && existing.isBefore(now)) ? existing : now;
    final picked = await showDatePicker(
      context: context,
      initialDate: existing ?? now.add(const Duration(days: 90)),
      firstDate: firstAllowed,
      lastDate: now.add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final formatted = _selectedDate != null
        ? DateFormat('dd MMM yyyy').format(_selectedDate!)
        : 'Not Set';

    final presets = [
      {'label': '1 Month', 'duration': const Duration(days: 30)},
      {'label': '3 Months', 'duration': const Duration(days: 90)},
      {'label': '6 Months', 'duration': const Duration(days: 180)},
      {'label': '1 Year', 'duration': const Duration(days: 365)},
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.inputBorder.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Gap(14),

            // Header Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Expiry Date',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colors.darkText,
                  ),
                ),
                IconButton(
                  icon: Icon(LucideIcons.x, size: 20, color: colors.inputLabel),
                  onPressed: () => Navigator.pop(context),
                  splashRadius: 18,
                ),
              ],
            ),
            const Gap(12),

            // Active Date Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F1FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Icon(
                        LucideIcons.calendar,
                        color: Color(0xFF0866FF),
                        size: 18,
                      ),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Date',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.inputLabel,
                          ),
                        ),
                        Text(
                          formatted,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: colors.darkText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _pickFromCalendar,
                    icon: const Icon(LucideIcons.calendarDays, size: 14),
                    label: const Text('Calendar', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            const Gap(14),

            // Presets
            Text(
              'Quick Presets',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: colors.darkText,
              ),
            ),
            const Gap(8),
            Row(
              children: presets.map((preset) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      onTap: () => _selectPreset(preset['duration'] as Duration),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8FC),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          preset['label'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.darkText,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const Gap(18),

            // Action Buttons
            Row(
              children: [
                if (widget.canClear && widget.initialDate != null) ...[
                  Expanded(
                    flex: 4,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, null),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Clear Date',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ),
                  const Gap(10),
                ],
                Expanded(
                  flex: 6,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _selectedDate),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066FF),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Confirm Date',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
