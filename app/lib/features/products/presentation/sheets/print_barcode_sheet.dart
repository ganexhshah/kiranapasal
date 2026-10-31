import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/services/printing_service.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/models/product.dart';

class PrintBarcodeSheet extends StatefulWidget {
  final Product product;

  const PrintBarcodeSheet({super.key, required this.product});

  static Future<void> show(BuildContext context, {required Product product}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => PrintBarcodeSheet(product: product),
    );
  }

  @override
  State<PrintBarcodeSheet> createState() => _PrintBarcodeSheetState();
}

class _PrintBarcodeSheetState extends State<PrintBarcodeSheet> {
  int _copies = 10;
  bool _isQr = false;
  bool _showPrice = true;
  bool _showName = true;
  bool _showStoreName = true;
  bool _isSingleThermal = true; // true = 50x30mm thermal rolls, false = A4 sheet
  bool _isPrinting = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final barcodeData = widget.product.sku.isNotEmpty
        ? widget.product.sku
        : (widget.product.id.isNotEmpty ? widget.product.id : 'SKU-001');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top drag indicator
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Gap(14),

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(LucideIcons.printer,
                              size: 20, color: Color(0xFF0284C7)),
                        ),
                        const Gap(10),
                        Expanded(
                          child: Text(
                            'Print Barcode Labels',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: colors.darkText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20, color: Color(0xFF64748B)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Gap(16),

              // Label Live Preview Container
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'LABEL PREVIEW',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const Gap(8),
                    Container(
                      width: 220,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_showStoreName)
                            Text(
                              PrintingService.instance.storeName,
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF475569),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (_showName)
                            Text(
                              widget.product.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const Gap(6),
                          if (_isQr)
                            BarcodeWidget(
                              barcode: Barcode.qrCode(),
                              data: barcodeData,
                              width: 80,
                              height: 80,
                            )
                          else
                            BarcodeWidget(
                              barcode: Barcode.code128(),
                              data: barcodeData,
                              width: 170,
                              height: 48,
                              drawText: true,
                              style: const TextStyle(fontSize: 9),
                            ),
                          if (_showPrice) ...[
                            const Gap(4),
                            Text(
                              'Rs. ${widget.product.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(16),

              // Barcode format toggle (Code128 vs QR)
              Row(
                children: [
                  Expanded(
                    child: _buildChoiceChip(
                      label: 'Linear Barcode',
                      icon: LucideIcons.scanLine,
                      selected: !_isQr,
                      onTap: () => setState(() => _isQr = false),
                    ),
                  ),
                  const Gap(10),
                  Expanded(
                    child: _buildChoiceChip(
                      label: 'QR Code',
                      icon: LucideIcons.qrCode,
                      selected: _isQr,
                      onTap: () => setState(() => _isQr = true),
                    ),
                  ),
                ],
              ),
              const Gap(12),

              // Paper Type toggle (Thermal Label roll vs A4 Sticker Sheet)
              Row(
                children: [
                  Expanded(
                    child: _buildChoiceChip(
                      label: 'Thermal Roll (50x30mm)',
                      icon: LucideIcons.receipt,
                      selected: _isSingleThermal,
                      onTap: () => setState(() => _isSingleThermal = true),
                    ),
                  ),
                  const Gap(10),
                  Expanded(
                    child: _buildChoiceChip(
                      label: 'A4 Sheet (24 labels)',
                      icon: LucideIcons.fileSpreadsheet,
                      selected: !_isSingleThermal,
                      onTap: () => setState(() => _isSingleThermal = false),
                    ),
                  ),
                ],
              ),
              const Gap(16),

              // Number of copies
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Number of Labels',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.minusCircle, size: 22, color: Color(0xFF64748B)),
                        onPressed: _copies > 1 ? () => setState(() => _copies--) : null,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_copies',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.plusCircle, size: 22, color: Color(0xFF0284C7)),
                        onPressed: () => setState(() => _copies++),
                      ),
                    ],
                  ),
                ],
              ),
              const Gap(8),

              // Preset copy pills
              Row(
                children: [1, 5, 10, 24, 50].map((preset) {
                  final isCurrent = _copies == preset;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text('$preset'),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isCurrent ? Colors.white : const Color(0xFF334155),
                      ),
                      backgroundColor: isCurrent ? const Color(0xFF0284C7) : const Color(0xFFF1F5F9),
                      onPressed: () => setState(() => _copies = preset),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  );
                }).toList(),
              ),
              const Gap(12),

              // Visibility Toggles
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  FilterChip(
                    label: const Text('Show Price'),
                    selected: _showPrice,
                    onSelected: (val) => setState(() => _showPrice = val),
                    backgroundColor: const Color(0xFFF8FAFC),
                    selectedColor: const Color(0xFFE0F2FE),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _showPrice ? const Color(0xFF0369A1) : const Color(0xFF475569),
                    ),
                  ),
                  FilterChip(
                    label: const Text('Show Name'),
                    selected: _showName,
                    onSelected: (val) => setState(() => _showName = val),
                    backgroundColor: const Color(0xFFF8FAFC),
                    selectedColor: const Color(0xFFE0F2FE),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _showName ? const Color(0xFF0369A1) : const Color(0xFF475569),
                    ),
                  ),
                  FilterChip(
                    label: const Text('Show Store Name'),
                    selected: _showStoreName,
                    onSelected: (val) => setState(() => _showStoreName = val),
                    backgroundColor: const Color(0xFFF8FAFC),
                    selectedColor: const Color(0xFFE0F2FE),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _showStoreName ? const Color(0xFF0369A1) : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
              const Gap(20),

              // Print Button
              FilledButton.icon(
                onPressed: _isPrinting
                    ? null
                    : () async {
                        setState(() => _isPrinting = true);
                        try {
                          await PrintingService.instance.printBarcodeLabels(
                            product: widget.product,
                            copies: _copies,
                            isQr: _isQr,
                            showPrice: _showPrice,
                            showName: _showName,
                            showStoreName: _showStoreName,
                            isSingleThermal: _isSingleThermal,
                          );
                          if (!context.mounted) return;
                          Navigator.pop(context);
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error printing labels: $e'),
                              backgroundColor: const Color(0xFFEF4444),
                            ),
                          );
                        } finally {
                          if (mounted) setState(() => _isPrinting = false);
                        }
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isPrinting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(LucideIcons.printer, size: 18),
                label: Text(
                  _isPrinting ? 'Preparing Print...' : 'Print $_copies Label${_copies > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? const Color(0xFF0284C7) : const Color(0xFF64748B),
            ),
            const Gap(6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: selected ? const Color(0xFF0369A1) : const Color(0xFF475569),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
