import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/services/printing_service.dart';
import '../../../../core/widgets/app_top_bar.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  late TextEditingController _storeNameController;
  late TextEditingController _storeAddressController;
  late TextEditingController _storePhoneController;
  late TextEditingController _panNumberController;
  late TextEditingController _footerController;
  late PrinterPaperSize _selectedPaperSize;
  late bool _autoPrint;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    final service = PrintingService.instance;
    _storeNameController = TextEditingController(text: service.storeName);
    _storeAddressController = TextEditingController(text: service.storeAddress);
    _storePhoneController = TextEditingController(text: service.storePhone);
    _panNumberController = TextEditingController(text: service.panNumber);
    _footerController = TextEditingController(text: service.footerMessage);
    _selectedPaperSize = service.paperSize;
    _autoPrint = service.autoPrintOnCheckout;
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _storeAddressController.dispose();
    _storePhoneController.dispose();
    _panNumberController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    await PrintingService.instance.updateSettings(
      storeName: _storeNameController.text.trim(),
      storeAddress: _storeAddressController.text.trim(),
      storePhone: _storePhoneController.text.trim(),
      panNumber: _panNumberController.text.trim(),
      footerMessage: _footerController.text.trim(),
      paperSize: _selectedPaperSize,
      autoPrintOnCheckout: _autoPrint,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Printer settings saved successfully'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _runTestPrint() async {
    setState(() => _isTesting = true);
    try {
      await PrintingService.instance.testPrint();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test print failed: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: AppTopBar(
          title: 'Printer & Receipt Settings',
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, size: 20, color: Color(0xFF0F172A)),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            TextButton(
              onPressed: _saveSettings,
              child: const Text(
                'Save',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Printer Hardware Status Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(LucideIcons.printer, color: Color(0xFF0284C7), size: 22),
                        ),
                        const Gap(12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Thermal / System Printer',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            const Gap(2),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const Gap(6),
                                const Text(
                                  'Ready to print (ESC/POS & PDF)',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const Gap(16),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const Gap(14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isTesting ? null : _runTestPrint,
                        icon: _isTesting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(LucideIcons.playCircle, size: 16),
                        label: Text(_isTesting ? 'Printing...' : 'Test Print'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                          side: const BorderSide(color: Color(0xFFBFDBFE)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Gap(16),

          // Paper Size Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Paper Format',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const Gap(4),
                const Text(
                  'Select the default roll or page size of your receipt printer',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const Gap(12),
                ...PrinterPaperSize.values.map((size) {
                  final isSelected = _selectedPaperSize == size;
                  return InkWell(
                    onTap: () => setState(() => _selectedPaperSize = size),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                size == PrinterPaperSize.a4 ? LucideIcons.fileText : LucideIcons.receipt,
                                size: 18,
                                color: isSelected ? const Color(0xFF10B981) : const Color(0xFF64748B),
                              ),
                              const Gap(12),
                              Text(
                                size.label,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? const Color(0xFF065F46) : const Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          if (isSelected)
                            const Icon(LucideIcons.checkCircle2, size: 18, color: Color(0xFF10B981)),
                        ],
                      ),
                    ),
                  );
                }),
                const Gap(8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _autoPrint,
                  activeThumbColor: const Color(0xFF0284C7),
                  title: const Text(
                    'Auto-Print Bill after Checkout',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                  subtitle: const Text(
                    'Immediately launch print dialog when a sale is completed',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                  onChanged: (val) => setState(() => _autoPrint = val),
                ),
              ],
            ),
          ),
          const Gap(16),

          // Business Receipt Header & Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Receipt Header & Tax Info',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const Gap(14),
                _buildTextField('Shop / Business Name', _storeNameController, LucideIcons.store),
                const Gap(12),
                _buildTextField('Shop Address', _storeAddressController, LucideIcons.mapPin),
                const Gap(12),
                _buildTextField('Contact Phone', _storePhoneController, LucideIcons.phone),
                const Gap(12),
                _buildTextField('PAN / VAT Registration No', _panNumberController, LucideIcons.fileCheck),
                const Gap(12),
                _buildTextField('Footer Note / Return Policy', _footerController, LucideIcons.messageSquare, maxLines: 2),
              ],
            ),
          ),
          const Gap(24),

          // Save Button
          FilledButton(
            onPressed: _saveSettings,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save Printer Settings', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
        ),
        const Gap(6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13.5),
          decoration: InputDecoration(
            prefixIcon: maxLines == 1 ? Icon(icon, size: 16, color: const Color(0xFF94A3B8)) : null,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
