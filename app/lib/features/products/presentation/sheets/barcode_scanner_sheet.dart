import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/theme/theme.dart';

/// Modal bottom sheet with real camera barcode / QR code scanner and manual entry fallback.
class BarcodeScannerSheet extends StatefulWidget {
  const BarcodeScannerSheet({super.key});

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const BarcodeScannerSheet(),
    );
  }

  @override
  State<BarcodeScannerSheet> createState() => _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends State<BarcodeScannerSheet> {
  final _manualController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  bool _hasScanned = false;
  bool _isTorchOn = false;

  @override
  void dispose() {
    _manualController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode != null && barcode.trim().isNotEmpty) {
      _hasScanned = true;
      HapticFeedback.mediumImpact();
      Navigator.pop(context, barcode.trim());
    }
  }

  void _submitManual() {
    final code = _manualController.text.trim();
    if (code.isNotEmpty) {
      HapticFeedback.lightImpact();
      Navigator.pop(context, code);
    }
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Drag Handle
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Gap(14),

              // Title and Flashlight Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.scanLine,
                            size: 20, color: Color(0xFF0284C7)),
                      ),
                      const Gap(10),
                      Text(
                        'Scan Barcode / QR',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: colors.darkText,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () async {
                          await _scannerController.toggleTorch();
                          setState(() => _isTorchOn = !_isTorchOn);
                        },
                        icon: Icon(
                          _isTorchOn ? LucideIcons.zap : LucideIcons.zapOff,
                          size: 20,
                          color: _isTorchOn ? const Color(0xFFF59E0B) : const Color(0xFF64748B),
                        ),
                        tooltip: 'Toggle Flashlight',
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(LucideIcons.x, size: 20, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
              const Gap(14),

              // Camera Viewfinder Box with MobileScanner
              Container(
                width: double.infinity,
                height: 240,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      MobileScanner(
                        controller: _scannerController,
                        onDetect: _onBarcodeDetected,
                        errorBuilder: (context, error) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.cameraOff, color: Colors.white60, size: 36),
                                  const Gap(8),
                                  Text(
                                    'Camera not available on this device.\nPlease enter barcode manually below.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      // Reticle target box
                      Container(
                        width: 200,
                        height: 140,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF0284C7), width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),

                      // Scanning line guide
                      Positioned(
                        child: Container(
                          width: 190,
                          height: 2,
                          color: const Color(0xFF2563EB),
                        ),
                      ),

                      // Bottom hint
                      Positioned(
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Point camera at barcode or QR code',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(16),

              // Divider with 'OR'
              Row(
                children: [
                  const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'OR ENTER MANUALLY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colors.inputLabel,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                ],
              ),
              const Gap(14),

              // Manual Input Field
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _manualController,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submitManual(),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'Enter barcode or SKU number',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: colors.inputLabel.withValues(alpha: 0.7),
                        ),
                        prefixIcon: Icon(
                          LucideIcons.barcode,
                          size: 18,
                          color: colors.inputLabel,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const Gap(10),
                  FilledButton(
                    onPressed: _submitManual,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
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
