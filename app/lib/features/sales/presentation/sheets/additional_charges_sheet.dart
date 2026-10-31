import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/theme.dart';

class AdditionalChargeResult {
  final String title;
  final double amount;

  const AdditionalChargeResult({
    required this.title,
    required this.amount,
  });
}

/// Modal bottom sheet to add delivery, packaging, or custom service charges to a sale.
class AdditionalChargesSheet extends StatefulWidget {
  const AdditionalChargesSheet({
    super.key,
    this.initialTitle = 'Delivery Charge',
    this.initialAmount = 50.0,
  });

  final String initialTitle;
  final double initialAmount;

  static Future<AdditionalChargeResult?> show(
    BuildContext context, {
    String initialTitle = 'Delivery Charge',
    double initialAmount = 50.0,
  }) {
    return showModalBottomSheet<AdditionalChargeResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AdditionalChargesSheet(
        initialTitle: initialTitle,
        initialAmount: initialAmount,
      ),
    );
  }

  @override
  State<AdditionalChargesSheet> createState() => _AdditionalChargesSheetState();
}

class _AdditionalChargesSheetState extends State<AdditionalChargesSheet> {
  late String _selectedTitle;
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late double _amount;

  final List<String> _presets = const [
    'Delivery Charge',
    'Packaging Fee',
    'Service Charge',
    'Transport / Freight',
  ];

  @override
  void initState() {
    super.initState();
    _selectedTitle = widget.initialTitle;
    _amount = widget.initialAmount;
    _titleController = TextEditingController(text: _selectedTitle);
    _amountController = TextEditingController(
      text: _amount > 0
          ? (_amount == _amount.roundToDouble() ? _amount.toInt().toString() : _amount.toString())
          : '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _selectPreset(String title) {
    setState(() {
      _selectedTitle = title;
      _titleController.text = title;
    });
  }

  void _selectAmountPreset(double val) {
    setState(() {
      _amount = val;
      _amountController.text = val == val.roundToDouble() ? val.toInt().toString() : val.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
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
                    color: colors.inputBorder.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Gap(14),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Additional Charges',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: colors.darkText,
                    ),
                  ),
                  if (_amount > 0)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _amount = 0;
                          _amountController.text = '0';
                        });
                      },
                      child: const Text(
                        'Remove',
                        style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                ],
              ),
              const Gap(14),

              Text(
                'Charge Type',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: colors.inputLabel),
              ),
              const Gap(8),

              // Presets wrap
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presets.map((title) {
                  final isSelected = title == _selectedTitle;
                  return InkWell(
                    onTap: () => _selectPreset(title),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0066FF) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : colors.darkText,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Gap(14),

              // Title Field
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: _titleController,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.darkText),
                  decoration: const InputDecoration(
                    hintText: 'Charge name (e.g. Delivery fee)...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onChanged: (val) => _selectedTitle = val.trim(),
                ),
              ),
              const Gap(14),

              Text(
                'Charge Amount (Rs.)',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: colors.inputLabel),
              ),
              const Gap(6),

              // Amount Field
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: colors.darkText),
                  decoration: const InputDecoration(
                    prefixText: 'Rs. ',
                    hintText: '0',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  ),
                  onChanged: (val) {
                    setState(() => _amount = double.tryParse(val) ?? 0);
                  },
                ),
              ),
              const Gap(8),

              // Quick Amount Suggestion Chips
              Row(
                children: [20.0, 50.0, 100.0, 150.0].map((amt) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => _selectAmountPreset(amt),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Rs. ${amt.toInt()}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.darkText),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Gap(18),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final title = _titleController.text.trim().isNotEmpty
                        ? _titleController.text.trim()
                        : 'Additional Charge';
                    Navigator.pop(
                      context,
                      AdditionalChargeResult(
                        title: title,
                        amount: _amount,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Apply Charge', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

