import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/auth_text_field.dart';

class ExpenseEntryResult {
  final String category;
  final double amount;
  final String paymentMethod;
  final String note;

  const ExpenseEntryResult({
    required this.category,
    required this.amount,
    required this.paymentMethod,
    required this.note,
  });
}

/// Modal bottom sheet to record daily shop operating expenses (rent, electricity, tea, travel).
class ExpenseEntrySheet extends StatefulWidget {
  const ExpenseEntrySheet({super.key});

  static Future<ExpenseEntryResult?> show(BuildContext context) {
    return showModalBottomSheet<ExpenseEntryResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const ExpenseEntrySheet(),
    );
  }

  @override
  State<ExpenseEntrySheet> createState() => _ExpenseEntrySheetState();
}

class _ExpenseEntrySheetState extends State<ExpenseEntrySheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _category = 'Tea & Refreshments';
  String _method = 'Cash';

  final List<String> _categories = const [
    'Tea & Refreshments',
    'Shop Rent',
    'Electricity & Water',
    'Transport / Freight',
    'Staff Salary',
    'Packaging / Bags',
    'Other Expenses',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SingleChildScrollView(
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
                'Record Shop Expense',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colors.darkText),
              ),
              const Gap(14),

              Text('Expense Category', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: colors.inputLabel)),
              const Gap(6),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.centerLeft,
                child: DropdownButton<String>(
                  value: _category,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: _categories.map((c) {
                    return DropdownMenuItem(value: c, child: Text(c, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: colors.darkText)));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _category = val);
                  },
                ),
              ),
              const Gap(14),

              AuthTextField(
                controller: _amountController,
                label: 'Expense Amount',
                prefixText: 'Rs. ',
                keyboardType: TextInputType.number,
              ),
              const Gap(14),

              Text('Paid Via', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: colors.inputLabel)),
              const Gap(6),
              Row(
                children: ['Cash', 'Fonepay QR', 'Bank'].map((m) {
                  final isSelected = m == _method;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => _method = m),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          m,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : colors.darkText,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Gap(14),

              AuthTextField(
                controller: _noteController,
                label: 'Notes (Optional)',
                hintText: 'e.g. Paid to Ram for tea',
              ),
              const Gap(16),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    final amt = double.tryParse(_amountController.text.trim()) ?? 0;
                    Navigator.pop(
                      context,
                      ExpenseEntryResult(
                        category: _category,
                        amount: amt,
                        paymentMethod: _method,
                        note: _noteController.text.trim(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Save Expense', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

