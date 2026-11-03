import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/auth_text_field.dart';
import '../../domain/models/selling_unit_detail.dart';
import 'unit_picker_sheet.dart';

/// Clean, lineless modal bottom sheet to Add or Edit a Selling Unit.
/// Reuses [UnitPickerSheet] for selecting or typing unit names.
class AddEditSellingUnitSheet extends StatefulWidget {
  const AddEditSellingUnitSheet({
    super.key,
    this.initialUnit,
    this.baseUnit = 'kg',
  });

  final SellingUnitDetail? initialUnit;
  final String baseUnit;

  static Future<SellingUnitDetail?> show(
    BuildContext context, {
    SellingUnitDetail? initialUnit,
    String baseUnit = 'kg',
  }) {
    return showModalBottomSheet<SellingUnitDetail>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => AddEditSellingUnitSheet(
        initialUnit: initialUnit,
        baseUnit: baseUnit,
      ),
    );
  }

  @override
  State<AddEditSellingUnitSheet> createState() => _AddEditSellingUnitSheetState();
}

class _AddEditSellingUnitSheetState extends State<AddEditSellingUnitSheet> {
  final _unitNameController = TextEditingController();
  final _equivalentController = TextEditingController();
  final _priceController = TextEditingController();

  bool _isDefault = false;
  bool _isActive = true;

  final List<String> _suggestedUnits = const [
    'Kilogram (kg)',
    'Gram (g)',
    'Packet (pkt)',
    'Piece (pcs)',
    'Bora (Sack)',
    'Carton (ctn)',
    'Box',
    'Dozen',
    'Litre (ltr)',
    'Millilitre (ml)',
  ];

  @override
  void initState() {
    super.initState();
    final unit = widget.initialUnit;
    if (unit != null) {
      _unitNameController.text = unit.name;
      _equivalentController.text = unit.equivalent;
      _priceController.text = unit.price > 0
          ? (unit.price == unit.price.roundToDouble()
              ? unit.price.toInt().toString()
              : unit.price.toString())
          : '';
      _isDefault = unit.isDefault;
      _isActive = unit.isActive;
    } else {
      _equivalentController.text = '1 ${widget.baseUnit}';
    }
  }

  @override
  void dispose() {
    _unitNameController.dispose();
    _equivalentController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickUnitName() async {
    final picked = await UnitPickerSheet.show(
      context,
      title: 'Select Selling Unit',
      units: _suggestedUnits,
      selectedUnit: _unitNameController.text.trim(),
    );

    if (picked != null && picked.trim().isNotEmpty) {
      setState(() {
        _unitNameController.text = picked.trim();
        final lower = picked.toLowerCase();
        if (_equivalentController.text.isEmpty || _equivalentController.text == '1 ${widget.baseUnit}') {
          if (lower.contains('gram') || lower.contains('(g)')) {
            _equivalentController.text = '0.001 ${widget.baseUnit}';
          } else if (lower.contains('bora') || lower.contains('sack')) {
            _equivalentController.text = '25 ${widget.baseUnit}';
          } else {
            _equivalentController.text = '1 ${widget.baseUnit}';
          }
        }
      });
    }
  }

  void _save() {
    final name = _unitNameController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final equivalent = _equivalentController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter a unit name')),
      );
      return;
    }

    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid selling price')),
      );
      return;
    }

    final result = SellingUnitDetail(
      id: widget.initialUnit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      equivalent: equivalent.isEmpty ? '1 ${widget.baseUnit}' : equivalent,
      price: price,
      isDefault: _isDefault,
      isActive: _isActive,
    );

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isEditing = widget.initialUnit != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
              const Gap(12),

              // Title Row (Clean, no unnecessary subtitle)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Selling Unit' : 'Add Selling Unit',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: colors.darkText,
                      letterSpacing: -0.3,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x, size: 20),
                    splashRadius: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
              const Gap(14),

              // 1. Unit Name Selector (Reusing UnitPickerSheet!)
              InkWell(
                onTap: _pickUnitName,
                borderRadius: BorderRadius.circular(10),
                child: IgnorePointer(
                  child: AuthTextField(
                    label: 'Unit Name *',
                    hintText: 'Select or add unit name',
                    controller: _unitNameController,
                    prefixIcon: const Icon(LucideIcons.scale, size: 18),
                    suffixIcon: const Icon(LucideIcons.chevronDown, size: 18, color: Color(0xFF64748B)),
                    readOnly: true,
                  ),
                ),
              ),
              const Gap(12),

              // 2. Conversion Quantity (Equivalent in base stock unit)
              AuthTextField(
                label: 'Equivalent in Base Stock *',
                hintText: 'e.g. 1 kg, 0.001 kg, 25 kg',
                controller: _equivalentController,
                prefixIcon: const Icon(LucideIcons.arrowRightLeft, size: 18),
              ),
              const Gap(12),

              // 3. Selling Price
              AuthTextField(
                label: 'Selling Price (Rs.) *',
                hintText: '0.00',
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: const Icon(LucideIcons.tag, size: 18),
              ),
              const Gap(14),

              // 4. Default Unit Toggle (Lineless, clean soft card, no redundant text)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Default Selling Unit',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.darkText,
                      ),
                    ),
                    Switch(
                      value: _isDefault,
                      activeThumbColor: const Color(0xFF2563EB),
                      onChanged: (val) => setState(() => _isDefault = val),
                    ),
                  ],
                ),
              ),
              const Gap(10),

              // 5. Active Status Toggle (Lineless, clean soft card, no redundant text)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Active Status',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.darkText,
                      ),
                    ),
                    Switch(
                      value: _isActive,
                      activeThumbColor: const Color(0xFF10B981),
                      onChanged: (val) => setState(() => _isActive = val),
                    ),
                  ],
                ),
              ),
              const Gap(18),

              // 6. Action Button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(LucideIcons.check, size: 17, color: Colors.white),
                  label: Text(
                    isEditing ? 'Update Selling Unit' : 'Add Selling Unit',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
