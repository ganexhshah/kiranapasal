import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/auth_text_field.dart';
import '../../domain/models/customer.dart';

/// Modal bottom sheet to adjust a customer's Udhar credit limit.
class CustomerCreditLimitSheet extends StatefulWidget {
  const CustomerCreditLimitSheet({
    super.key,
    required this.customer,
  });

  final Customer customer;

  static Future<double?> show(
    BuildContext context, {
    required Customer customer,
  }) {
    return showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => CustomerCreditLimitSheet(customer: customer),
    );
  }

  @override
  State<CustomerCreditLimitSheet> createState() => _CustomerCreditLimitSheetState();
}

class _CustomerCreditLimitSheetState extends State<CustomerCreditLimitSheet> {
  late final TextEditingController _limitController;

  @override
  void initState() {
    super.initState();
    _limitController = TextEditingController(text: widget.customer.creditLimit.toInt().toString());
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
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
                'Set Credit Limit',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colors.darkText),
              ),
              const Gap(6),
              Text(
                'Customer: ${widget.customer.name}',
                style: TextStyle(fontSize: 13, color: colors.inputLabel),
              ),
              const Gap(14),
              AuthTextField(
                controller: _limitController,
                label: 'Credit Limit',
                prefixText: 'Rs. ',
                keyboardType: TextInputType.number,
              ),
              const Gap(16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    final val = double.tryParse(_limitController.text.trim()) ?? widget.customer.creditLimit;
                    Navigator.pop(context, val);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Save Limit', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

