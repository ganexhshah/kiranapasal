import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../../core/repositories/app_data_repository.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/auth_text_field.dart';
import '../../domain/models/supplier.dart';
import 'select_supplier_sheet.dart';

class PurchaseRecordResult {
  final Supplier supplier;
  final String productName;
  final double quantity;
  final String unit;
  final double unitCost;
  final double totalAmount;
  final String invoiceNumber;
  final String paymentMethod;
  final bool isCredit;

  const PurchaseRecordResult({
    required this.supplier,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.unitCost,
    required this.totalAmount,
    required this.invoiceNumber,
    this.paymentMethod = 'Bank Transfer',
    this.isCredit = false,
  });
}

/// Modal bottom sheet to record wholesale inventory purchase shipments.
class RecordPurchaseSheet extends StatefulWidget {
  const RecordPurchaseSheet({
    super.key,
    this.initialSupplier,
  });

  final Supplier? initialSupplier;

  static Future<PurchaseRecordResult?> show(
    BuildContext context, {
    Supplier? initialSupplier,
  }) {
    return showModalBottomSheet<PurchaseRecordResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => RecordPurchaseSheet(initialSupplier: initialSupplier),
    );
  }

  @override
  State<RecordPurchaseSheet> createState() => _RecordPurchaseSheetState();
}

class _RecordPurchaseSheetState extends State<RecordPurchaseSheet> {
  Supplier? _supplier;
  final _productNameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _unitCostController = TextEditingController();
  final _invoiceController = TextEditingController();
  String _unit = 'pkt';

  @override
  void initState() {
    super.initState();
    _supplier = widget.initialSupplier ??
        (AppDataRepository.instance.suppliers.isNotEmpty
            ? AppDataRepository.instance.suppliers.first
            : null);
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _qtyController.dispose();
    _unitCostController.dispose();
    _invoiceController.dispose();
    super.dispose();
  }

  double get _qty => double.tryParse(_qtyController.text.trim()) ?? 0;
  double get _cost => double.tryParse(_unitCostController.text.trim()) ?? 0;
  double get _total => _qty * _cost;

  Future<void> _pickSupplier() async {
    final sup = await SelectSupplierSheet.show(context, selectedSupplierId: _supplier?.id);
    if (sup != null && mounted) setState(() => _supplier = sup);
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
                'Record Purchase',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colors.darkText),
              ),
              const Gap(14),

              // Supplier Selector Tile
              InkWell(
                onTap: _pickSupplier,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Supplier', style: TextStyle(fontSize: 11.5, color: colors.inputLabel)),
                          Text(_supplier?.name ?? 'Select Supplier', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: colors.darkText)),
                        ],
                      ),
                      const Icon(Icons.arrow_drop_down, color: Color(0xFF0066FF)),
                    ],
                  ),
                ),
              ),
              const Gap(12),

              AuthTextField(
                controller: _productNameController,
                label: 'Product Item Name',
                hintText: 'Item name',
                onChanged: (_) => setState(() {}),
              ),
              const Gap(12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AuthTextField(
                      controller: _qtyController,
                      label: 'Quantity',
                      hintText: '10',
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const Gap(10),
                  Expanded(
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.inputBorder.withValues(alpha: 0.2)),
                      ),
                      alignment: Alignment.centerLeft,
                      child: DropdownButton<String>(
                        value: _unit,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: ['Bora', 'Carton', 'kg', 'Packet', 'Piece'].map((u) {
                          return DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _unit = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(12),
              AuthTextField(
                controller: _unitCostController,
                label: 'Cost Per Unit',
                hintText: '2000',
                prefixText: 'Rs. ',
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              const Gap(12),
              AuthTextField(
                controller: _invoiceController,
                label: 'Supplier Invoice #',
                hintText: 'INV-XXX',
                onChanged: (_) => setState(() {}),
              ),
              const Gap(14),

              // Total Row
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Shipment Cost', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    Text('Rs. ${_total.toInt()}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0066FF))),
                  ],
                ),
              ),
              const Gap(16),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    if (_supplier == null) return;
                    Navigator.pop(
                      context,
                      PurchaseRecordResult(
                        supplier: _supplier!,
                        productName: _productNameController.text.trim(),
                        quantity: _qty,
                        unit: _unit,
                        unitCost: _cost,
                        totalAmount: _total,
                        invoiceNumber: _invoiceController.text.trim(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Save Purchase Entry', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

