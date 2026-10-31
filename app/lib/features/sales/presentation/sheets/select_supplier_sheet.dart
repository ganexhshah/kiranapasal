import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/repositories/app_data_repository.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/models/supplier.dart';
import 'add_edit_supplier_sheet.dart';

/// Modal bottom sheet allowing selection of an inventory supplier.
class SelectSupplierSheet extends StatefulWidget {
  const SelectSupplierSheet({
    super.key,
    this.selectedSupplierId,
  });

  final String? selectedSupplierId;

  static Future<Supplier?> show(
    BuildContext context, {
    String? selectedSupplierId,
  }) {
    return showModalBottomSheet<Supplier>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SelectSupplierSheet(selectedSupplierId: selectedSupplierId),
    );
  }

  @override
  State<SelectSupplierSheet> createState() => _SelectSupplierSheetState();
}

class _SelectSupplierSheetState extends State<SelectSupplierSheet> {
  List<Supplier> get _suppliers => AppDataRepository.instance.suppliers;
  String _query = '';

  List<Supplier> get _filtered {
    if (_query.isEmpty) return _suppliers;
    return _suppliers
        .where((s) => s.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  Future<void> _addSupplier() async {
    final sup = await AddEditSupplierSheet.show(context);
    if (sup != null && mounted) {
      await AppDataRepository.instance.addSupplier(sup);
      if (mounted) {
        Navigator.pop(context, sup);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
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
                  'Select Supplier',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colors.darkText),
                ),
                TextButton.icon(
                  onPressed: _addSupplier,
                  icon: const Icon(LucideIcons.plus, size: 15, color: Color(0xFF0066FF)),
                  label: const Text('Add Supplier', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0066FF))),
                ),
              ],
            ),
            const Gap(10),
            Container(
              height: 40,
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
              child: TextField(
                onChanged: (val) => setState(() => _query = val.trim()),
                style: TextStyle(fontSize: 13.5, color: colors.darkText),
                decoration: InputDecoration(
                  hintText: 'Search supplier name...',
                  prefixIcon: Icon(LucideIcons.search, size: 16, color: colors.inputLabel),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
            const Gap(12),
            Expanded(
              child: ListView.separated(
                itemCount: _filtered.length,
                separatorBuilder: (ctx, i) => const Gap(8),
                itemBuilder: (ctx, i) {
                  final s = _filtered[i];
                  final isSelected = s.id == widget.selectedSupplierId;
                  return InkWell(
                    onTap: () => Navigator.pop(context, s),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected ? Border.all(color: const Color(0xFF0066FF), width: 1.2) : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(color: Color(0xFFE2E8F0), shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: const Icon(LucideIcons.truck, size: 18, color: Color(0xFF475569)),
                          ),
                          const Gap(12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.darkText)),
                                Text('${s.phone} • ${s.address}', style: TextStyle(fontSize: 11.5, color: colors.inputLabel)),
                              ],
                            ),
                          ),
                          if (s.outstandingBalance > 0)
                            Text(
                              'Due: Rs. ${s.outstandingBalance.toInt()}',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFFEF4444)),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

