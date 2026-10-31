import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/auth_text_field.dart';
import '../../domain/models/customer.dart';

/// Modal bottom sheet to create or edit customer profiles.
class AddEditCustomerSheet extends StatefulWidget {
  const AddEditCustomerSheet({
    super.key,
    this.customer,
    this.initialName,
    this.initialPhone,
  });

  final Customer? customer;
  final String? initialName;
  final String? initialPhone;

  static Future<Customer?> show(
    BuildContext context, {
    Customer? customer,
    String? initialName,
    String? initialPhone,
  }) {
    return showModalBottomSheet<Customer>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AddEditCustomerSheet(
        customer: customer,
        initialName: initialName,
        initialPhone: initialPhone,
      ),
    );
  }

  @override
  State<AddEditCustomerSheet> createState() => _AddEditCustomerSheetState();
}

class _AddEditCustomerSheetState extends State<AddEditCustomerSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _limitController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name ?? widget.initialName ?? '');
    _phoneController = TextEditingController(text: widget.customer?.phone ?? widget.initialPhone ?? '');
    _addressController = TextEditingController(text: widget.customer?.address ?? '');
    _limitController = TextEditingController(
      text: widget.customer != null ? widget.customer!.creditLimit.toInt().toString() : '10000',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final customer = Customer(
      id: widget.customer?.id ?? 'cust_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      udharBalance: widget.customer?.udharBalance ?? 0,
      creditLimit: double.tryParse(_limitController.text.trim()) ?? 10000,
    );
    Navigator.pop(context, customer);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = widget.customer != null;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
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
                    isEditing ? 'Edit Customer' : 'Add Customer',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colors.darkText),
                  ),
                ],
              ),
              const Gap(16),

              AuthTextField(
                controller: _nameController,
                label: 'Full Name',
                hintText: 'Customer Name',
                prefixIcon: const Icon(LucideIcons.user, size: 18),
              ),
              const Gap(12),
              AuthTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hintText: '98XXXXXXXX',
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(LucideIcons.phone, size: 18),
              ),
              const Gap(12),
              AuthTextField(
                controller: _addressController,
                label: 'Address (Optional)',
                hintText: 'Location / Area',
                prefixIcon: const Icon(LucideIcons.mapPin, size: 18),
              ),
              const Gap(12),
              AuthTextField(
                controller: _limitController,
                label: 'Credit Limit',
                hintText: '10000',
                prefixText: 'Rs. ',
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(LucideIcons.shieldCheck, size: 18),
              ),
              const Gap(16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: colors.inputBorder.withValues(alpha: 0.2)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Cancel', style: TextStyle(color: colors.darkText)),
                    ),
                  ),
                  const Gap(10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066FF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(isEditing ? 'Save Changes' : 'Create Customer', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

