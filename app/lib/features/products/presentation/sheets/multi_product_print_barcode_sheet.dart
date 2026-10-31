import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/services/printing_service.dart';
import '../../../../core/theme/theme.dart';

/// Modal bottom sheet to configure and execute batch barcode printing or saving to PDF.
class MultiProductPrintBarcodeSheet extends StatefulWidget {
  final List<BarcodePrintItem> items;

  const MultiProductPrintBarcodeSheet({
    super.key,
    required this.items,
  });

  static Future<void> show(
    BuildContext context, {
    required List<BarcodePrintItem> items,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => MultiProductPrintBarcodeSheet(items: items),
    );
  }

  @override
  State<MultiProductPrintBarcodeSheet> createState() => _MultiProductPrintBarcodeSheetState();
}

class _MultiProductPrintBarcodeSheetState extends State<MultiProductPrintBarcodeSheet> {
  bool _isQr = false;
  bool _showPrice = true;
  bool _showName = true;
  bool _showStoreName = true;
  bool _isSingleThermal = true; // true = 50x30mm thermal rolls, false = A4 sheet
  bool _isPrinting = false;
  bool _isSharing = false;

  int get _totalLabels => widget.items.fold(0, (sum, item) => sum + item.copies);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final firstProduct = widget.items.isNotEmpty ? widget.items.first.product : null;
    final barcodeData = firstProduct != null
        ? (firstProduct.sku.isNotEmpty ? firstProduct.sku : firstProduct.id)
        : 'SAMPLE-123';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Drag Notch
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Gap(14),

              // 2. Header
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
                          child: const Icon(LucideIcons.printer, size: 20, color: AppColors.primary),
                        ),
                        const Gap(10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Print Barcodes',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: colors.darkText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${widget.items.length} Products ($_totalLabels total labels)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
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

              // 3. Label Live Preview
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    const Text(
                      'PREVIEW SAMPLE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const Gap(8),
                    Container(
                      width: 210,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
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
                          if (_showName && firstProduct != null)
                            Text(
                              firstProduct.name,
                              style: const TextStyle(
                                fontSize: 11.5,
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
                              width: 70,
                              height: 70,
                            )
                          else
                            BarcodeWidget(
                              barcode: Barcode.code128(),
                              data: barcodeData,
                              width: 160,
                              height: 42,
                              drawText: true,
                              style: const TextStyle(fontSize: 8.5),
                            ),
                          if (_showPrice && firstProduct != null) ...[
                            const Gap(4),
                            Text(
                              'Rs. ${firstProduct.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 12.5,
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

              // 4. Barcode format (Code 128 vs QR)
              Row(
                children: [
                  Expanded(
                    child: _buildChoiceChip(
                      label: 'Standard Barcode',
                      icon: LucideIcons.barcode,
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
              const Gap(10),

              // 5. Paper Format (50x30 Thermal roll vs A4 Sticker Sheet)
              Row(
                children: [
                  Expanded(
                    child: _buildChoiceChip(
                      label: '50x30mm Thermal',
                      icon: LucideIcons.printer,
                      selected: _isSingleThermal,
                      onTap: () => setState(() => _isSingleThermal = true),
                    ),
                  ),
                  const Gap(10),
                  Expanded(
                    child: _buildChoiceChip(
                      label: 'A4 Sheet (24/page)',
                      icon: LucideIcons.fileSpreadsheet,
                      selected: !_isSingleThermal,
                      onTap: () => setState(() => _isSingleThermal = false),
                    ),
                  ),
                ],
              ),
              const Gap(14),

              // 6. Label display toggles
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Store Name'),
                    selected: _showStoreName,
                    onSelected: (val) => setState(() => _showStoreName = val),
                    backgroundColor: const Color(0xFFF1F5F9),
                    selectedColor: AppColors.primary.withAlpha(30),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: _showStoreName ? FontWeight.w700 : FontWeight.w500,
                      color: _showStoreName ? AppColors.primary : const Color(0xFF475569),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide.none),
                  ),
                  FilterChip(
                    label: const Text('Product Name'),
                    selected: _showName,
                    onSelected: (val) => setState(() => _showName = val),
                    backgroundColor: const Color(0xFFF1F5F9),
                    selectedColor: AppColors.primary.withAlpha(30),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: _showName ? FontWeight.w700 : FontWeight.w500,
                      color: _showName ? AppColors.primary : const Color(0xFF475569),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide.none),
                  ),
                  FilterChip(
                    label: const Text('Price (MRP)'),
                    selected: _showPrice,
                    onSelected: (val) => setState(() => _showPrice = val),
                    backgroundColor: const Color(0xFFF1F5F9),
                    selectedColor: AppColors.primary.withAlpha(30),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: _showPrice ? FontWeight.w700 : FontWeight.w500,
                      color: _showPrice ? AppColors.primary : const Color(0xFF475569),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide.none),
                  ),
                ],
              ),
              const Gap(20),

              // 7. Actions: Direct Print & Save / Share as PDF
              Row(
                children: [
                  // Save / Export as PDF
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: (_isPrinting || _isSharing)
                          ? null
                          : () async {
                              setState(() => _isSharing = true);
                              try {
                                await PrintingService.instance.shareMultiProductBarcodePdf(
                                  items: widget.items,
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
                                    content: Text('Error generating PDF: $e'),
                                    backgroundColor: const Color(0xFFEF4444),
                                  ),
                                );
                              } finally {
                                if (mounted) setState(() => _isSharing = false);
                              }
                            },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary, width: 1.2),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _isSharing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            )
                          : const Icon(LucideIcons.fileDown, size: 16),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _isSharing ? 'Saving...' : 'Save as PDF',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                  const Gap(10),

                  // Print Directly
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (_isPrinting || _isSharing)
                          ? null
                          : () async {
                              setState(() => _isPrinting = true);
                              try {
                                await PrintingService.instance.printMultiProductBarcodeLabels(
                                  items: widget.items,
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _isPrinting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(LucideIcons.printer, size: 16),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _isPrinting ? 'Printing...' : 'Print ($_totalLabels)',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
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

  Widget _buildChoiceChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withAlpha(20) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? AppColors.primary : const Color(0xFF64748B),
            ),
            const Gap(6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.primary : const Color(0xFF475569),
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

