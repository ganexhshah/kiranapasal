import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/auth_text_field.dart';
import '../../domain/models/supplier.dart';

/// Modal bottom sheet to create or edit an inventory supplier profile.
class AddEditSupplierSheet extends StatefulWidget {
  const AddEditSupplierSheet({
    super.key,
    this.supplier,
    this.initialName,
    this.initialPhone,
  });

  final Supplier? supplier;
  final String? initialName;
  final String? initialPhone;

  static Future<Supplier?> show(
    BuildContext context, {
    Supplier? supplier,
    String? initialName,
    String? initialPhone,
  }) {
    return showModalBottomSheet<Supplier>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AddEditSupplierSheet(
        supplier: supplier,
        initialName: initialName,
        initialPhone: initialPhone,
      ),
    );
  }

  @override
  State<AddEditSupplierSheet> createState() => _AddEditSupplierSheetState();
}

class _AddEditSupplierSheetState extends State<AddEditSupplierSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _panController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.supplier?.name ?? widget.initialName ?? '');
    _phoneController = TextEditingController(text: widget.supplier?.phone ?? widget.initialPhone ?? '');
    _addressController = TextEditingController(text: widget.supplier?.address ?? '');
    _panController = TextEditingController(text: widget.supplier?.panNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _panController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final sup = Supplier(
      id: widget.supplier?.id ?? 'sup_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      panNumber: _panController.text.trim(),
      outstandingBalance: widget.supplier?.outstandingBalance ?? 0,
    );
    Navigator.pop(context, sup);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = widget.supplier != null;

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Supplier' : 'Add Supplier',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colors.darkText),
                  ),
                ],
              ),
              const Gap(16),
              AuthTextField(
                controller: _nameController,
                label: 'Supplier / Company Name',
                hintText: 'e.g. Nepal Agro Distributors',
                prefixIcon: const Icon(LucideIcons.truck, size: 18),
              ),
              const Gap(12),
              AuthTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hintText: '01-XXXXXXX',
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(LucideIcons.phone, size: 18),
              ),
              const Gap(12),
              AuthTextField(
                controller: _addressController,
                label: 'Address (Optional)',
                hintText: 'City / Market Location',
                prefixIcon: const Icon(LucideIcons.mapPin, size: 18),
              ),
              const Gap(12),
              AuthTextField(
                controller: _panController,
                label: 'PAN / VAT Number',
                hintText: '9-digit PAN',
                prefixIcon: const Icon(LucideIcons.fileCheck2, size: 18),
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
                      child: Text(isEditing ? 'Save Changes' : 'Create Supplier', style: const TextStyle(fontWeight: FontWeight.w700)),
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

