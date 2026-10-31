import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/products/domain/models/product.dart';
import '../utils/money.dart';

enum PrinterPaperSize {
  mm58('58mm Thermal (2 inch)', PdfPageFormat(58 * PdfPageFormat.mm, double.infinity, marginAll: 2 * PdfPageFormat.mm)),
  mm80('80mm Thermal (3 inch)', PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 4 * PdfPageFormat.mm)),
  a4('A4 Standard', PdfPageFormat.a4);

  final String label;
  final PdfPageFormat format;
  const PrinterPaperSize(this.label, this.format);
}

class InvoicePrintData {
  final String invoiceNumber;
  final DateTime date;
  final String? customerName;
  final String? customerPhone;
  final List<InvoiceItemData> items;
  final double subtotal;
  final double discount;
  final double tax;
  final double charges;
  final double grandTotal;
  final String paymentMethod;
  final double? cashReceived;
  final double? changeDue;
  final String? note;

  const InvoicePrintData({
    required this.invoiceNumber,
    required this.date,
    this.customerName,
    this.customerPhone,
    required this.items,
    required this.subtotal,
    this.discount = 0.0,
    this.tax = 0.0,
    this.charges = 0.0,
    required this.grandTotal,
    required this.paymentMethod,
    this.cashReceived,
    this.changeDue,
    this.note,
  });
}

class InvoiceItemData {
  final String name;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double total;

  const InvoiceItemData({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.total,
  });
}

class BarcodePrintItem {
  final Product product;
  final int copies;

  const BarcodePrintItem({
    required this.product,
    required this.copies,
  });
}

class PrintingService extends ChangeNotifier {
  static final PrintingService instance = PrintingService._internal();
  PrintingService._internal();

  String _storeName = 'Kirana Store';
  String _storeAddress = '';
  String _storePhone = '';
  String _panNumber = '';
  String _footerMessage = 'Thank you for shopping with us!\nExchange within 7 days with bill.';
  PrinterPaperSize _paperSize = PrinterPaperSize.mm80;
  bool _autoPrintOnCheckout = false;
  String _selectedPrinterName = 'Default System / Thermal';

  String get storeName => _storeName;
  String get storeAddress => _storeAddress;
  String get storePhone => _storePhone;
  String get panNumber => _panNumber;
  String get footerMessage => _footerMessage;
  PrinterPaperSize get paperSize => _paperSize;
  bool get autoPrintOnCheckout => _autoPrintOnCheckout;
  String get selectedPrinterName => _selectedPrinterName;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('printer_store_name');
    if (savedName != null && savedName.isNotEmpty && savedName != 'KRM Mart & Wholesale') {
      _storeName = savedName;
    }
    final savedAddress = prefs.getString('printer_store_address');
    if (savedAddress != null && savedAddress.isNotEmpty && savedAddress != 'Main Road, Kathmandu, Nepal') {
      _storeAddress = savedAddress;
    }
    final savedPhone = prefs.getString('printer_store_phone');
    if (savedPhone != null && savedPhone.isNotEmpty && savedPhone != '+977 9841234567') {
      _storePhone = savedPhone;
    }
    final savedPan = prefs.getString('printer_pan_number');
    if (savedPan != null && savedPan.isNotEmpty && savedPan != '609823412') {
      _panNumber = savedPan;
    }
    _footerMessage = prefs.getString('printer_footer_message') ?? _footerMessage;
    _autoPrintOnCheckout = prefs.getBool('printer_auto_print') ?? _autoPrintOnCheckout;
    _selectedPrinterName = prefs.getString('printer_selected_device') ?? _selectedPrinterName;

    final sizeKey = prefs.getString('printer_paper_size');
    if (sizeKey == '58mm') {
      _paperSize = PrinterPaperSize.mm58;
    } else if (sizeKey == 'a4') {
      _paperSize = PrinterPaperSize.a4;
    } else {
      _paperSize = PrinterPaperSize.mm80;
    }
    notifyListeners();
  }

  /// Automatically synchronize printing header & info from real shop backend record
  Future<void> syncFromShop(Map<String, dynamic> shop) async {
    final name = (shop['name'] as String?)?.trim();
    final address = (shop['address'] as String?)?.trim();
    final phone = (shop['phone'] as String?)?.trim();
    final pan = (shop['pan_vat_number'] as String?)?.trim();
    await updateSettings(
      storeName: (name != null && name.isNotEmpty) ? name : null,
      storeAddress: (address != null && address.isNotEmpty) ? address : null,
      storePhone: (phone != null && phone.isNotEmpty) ? phone : null,
      panNumber: (pan != null && pan.isNotEmpty) ? pan : null,
    );
  }

  Future<void> updateSettings({
    String? storeName,
    String? storeAddress,
    String? storePhone,
    String? panNumber,
    String? footerMessage,
    PrinterPaperSize? paperSize,
    bool? autoPrintOnCheckout,
    String? selectedPrinterName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (storeName != null) {
      _storeName = storeName;
      await prefs.setString('printer_store_name', storeName);
    }
    if (storeAddress != null) {
      _storeAddress = storeAddress;
      await prefs.setString('printer_store_address', storeAddress);
    }
    if (storePhone != null) {
      _storePhone = storePhone;
      await prefs.setString('printer_store_phone', storePhone);
    }
    if (panNumber != null) {
      _panNumber = panNumber;
      await prefs.setString('printer_pan_number', panNumber);
    }
    if (footerMessage != null) {
      _footerMessage = footerMessage;
      await prefs.setString('printer_footer_message', footerMessage);
    }
    if (paperSize != null) {
      _paperSize = paperSize;
      final sizeStr = paperSize == PrinterPaperSize.mm58 ? '58mm' : (paperSize == PrinterPaperSize.a4 ? 'a4' : '80mm');
      await prefs.setString('printer_paper_size', sizeStr);
    }
    if (autoPrintOnCheckout != null) {
      _autoPrintOnCheckout = autoPrintOnCheckout;
      await prefs.setBool('printer_auto_print', autoPrintOnCheckout);
    }
    if (selectedPrinterName != null) {
      _selectedPrinterName = selectedPrinterName;
      await prefs.setString('printer_selected_device', selectedPrinterName);
    }
    notifyListeners();
  }

  /// Generate PDF for Invoice / Receipt
  Future<Uint8List> generateInvoicePdf(InvoicePrintData data) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('yyyy-MM-dd hh:mm a');

    final isThermal = _paperSize != PrinterPaperSize.a4;
    final fontSizeMultiplier = _paperSize == PrinterPaperSize.mm58 ? 0.75 : 1.0;

    pdf.addPage(
      pw.Page(
        pageFormat: _paperSize.format,
        build: (pw.Context context) {
          return pw.Container(
            padding: isThermal ? const pw.EdgeInsets.all(4) : const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Store Header
                pw.Center(
                  child: pw.Text(
                    _storeName,
                    style: pw.TextStyle(
                      fontSize: (isThermal ? 14 : 20) * fontSizeMultiplier,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    _storeAddress,
                    style: pw.TextStyle(fontSize: 8.5 * fontSizeMultiplier),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                if (_storePhone.isNotEmpty)
                  pw.Center(
                    child: pw.Text(
                      'Tel: $_storePhone',
                      style: pw.TextStyle(fontSize: 8.5 * fontSizeMultiplier),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                if (_panNumber.isNotEmpty)
                  pw.Center(
                    child: pw.Text(
                      'PAN / VAT: $_panNumber',
                      style: pw.TextStyle(
                        fontSize: 8.5 * fontSizeMultiplier,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),

                pw.SizedBox(height: 6),
                pw.Divider(borderStyle: pw.BorderStyle.dashed, thickness: 0.8),
                pw.SizedBox(height: 4),

                // Invoice metadata
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Bill No: ${data.invoiceNumber}',
                        style: pw.TextStyle(
                            fontSize: 9 * fontSizeMultiplier,
                            fontWeight: pw.FontWeight.bold)),
                    pw.Text(dateFormat.format(data.date),
                        style: pw.TextStyle(fontSize: 8 * fontSizeMultiplier)),
                  ],
                ),
                if (data.customerName != null && data.customerName!.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text('Customer: ${data.customerName}',
                      style: pw.TextStyle(fontSize: 8.5 * fontSizeMultiplier)),
                  if (data.customerPhone != null && data.customerPhone!.isNotEmpty)
                    pw.Text('Phone: ${data.customerPhone}',
                        style: pw.TextStyle(fontSize: 8 * fontSizeMultiplier)),
                ],

                pw.SizedBox(height: 4),
                pw.Divider(borderStyle: pw.BorderStyle.dashed, thickness: 0.8),
                pw.SizedBox(height: 4),

                // Table Header
                pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 4,
                      child: pw.Text('Item',
                          style: pw.TextStyle(
                              fontSize: 8.5 * fontSizeMultiplier,
                              fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text('Qty',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                              fontSize: 8.5 * fontSizeMultiplier,
                              fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text('Rate',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                              fontSize: 8.5 * fontSizeMultiplier,
                              fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text('Total',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                              fontSize: 8.5 * fontSizeMultiplier,
                              fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                pw.SizedBox(height: 3),
                pw.Divider(borderStyle: pw.BorderStyle.dashed, thickness: 0.5),
                pw.SizedBox(height: 3),

                // Items List
                ...data.items.map((item) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          flex: 4,
                          child: pw.Text(item.name,
                              style: pw.TextStyle(fontSize: 8 * fontSizeMultiplier)),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            item.quantity % 1 == 0
                                ? item.quantity.toInt().toString()
                                : item.quantity.toStringAsFixed(1),
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(fontSize: 8 * fontSizeMultiplier),
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            item.unitPrice.toStringAsFixed(0),
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(fontSize: 8 * fontSizeMultiplier),
                          ),
                        ),
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                            item.total.toStringAsFixed(0),
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                                fontSize: 8 * fontSizeMultiplier,
                                fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                pw.SizedBox(height: 4),
                pw.Divider(borderStyle: pw.BorderStyle.dashed, thickness: 0.8),
                pw.SizedBox(height: 4),

                // Totals
                _buildAmountRow('Subtotal', 'Rs. ${formatAmount(data.subtotal)}', fontSizeMultiplier),
                if (data.discount > 0)
                  _buildAmountRow('Discount', '- Rs. ${formatAmount(data.discount)}', fontSizeMultiplier),
                if (data.tax > 0)
                  _buildAmountRow('Tax / VAT', 'Rs. ${formatAmount(data.tax)}', fontSizeMultiplier),
                if (data.charges > 0)
                  _buildAmountRow('Charges', 'Rs. ${formatAmount(data.charges)}', fontSizeMultiplier),

                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('GRAND TOTAL',
                        style: pw.TextStyle(
                            fontSize: 10 * fontSizeMultiplier,
                            fontWeight: pw.FontWeight.bold)),
                    pw.Text('Rs. ${formatAmount(data.grandTotal)}',
                        style: pw.TextStyle(
                            fontSize: 11 * fontSizeMultiplier,
                            fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 2),
                _buildAmountRow('Payment Method', data.paymentMethod, fontSizeMultiplier),
                if (data.cashReceived != null && data.cashReceived! > 0) ...[
                  _buildAmountRow('Cash Received', 'Rs. ${formatAmount(data.cashReceived!)}', fontSizeMultiplier),
                  if (data.changeDue != null && data.changeDue! > 0)
                    _buildAmountRow('Change Returned', 'Rs. ${formatAmount(data.changeDue!)}', fontSizeMultiplier),
                ],

                pw.SizedBox(height: 8),
                pw.Divider(borderStyle: pw.BorderStyle.dashed, thickness: 0.8),
                pw.SizedBox(height: 6),

                // Barcode / QR Code for Verification
                pw.Center(
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.code128(),
                    data: data.invoiceNumber,
                    width: isThermal ? 140 : 180,
                    height: 35,
                    drawText: false,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Center(
                  child: pw.Text(
                    data.invoiceNumber,
                    style: pw.TextStyle(fontSize: 7 * fontSizeMultiplier),
                  ),
                ),

                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text(
                    _footerMessage,
                    style: pw.TextStyle(
                      fontSize: 7.5 * fontSizeMultiplier,
                      fontStyle: pw.FontStyle.italic,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildAmountRow(String label, String value, double multiplier) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 8.5 * multiplier)),
          pw.Text(value, style: pw.TextStyle(fontSize: 8.5 * multiplier, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  /// Print or preview invoice
  Future<void> printInvoice(InvoicePrintData data) async {
    final pdfBytes = await generateInvoicePdf(data);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Invoice_${data.invoiceNumber}',
    );
  }

  /// Share Invoice as PDF
  Future<void> shareInvoicePdf(InvoicePrintData data) async {
    final pdfBytes = await generateInvoicePdf(data);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Invoice_${data.invoiceNumber}.pdf',
    );
  }

  /// Generate & Print Barcode Labels
  Future<void> printBarcodeLabels({
    required Product product,
    int copies = 1,
    bool isQr = false,
    bool showPrice = true,
    bool showName = true,
    bool showStoreName = true,
    bool isSingleThermal = true,
  }) async {
    final pdf = pw.Document();
    final barcodeData = product.sku.isNotEmpty ? product.sku : product.id;

    if (isSingleThermal) {
      // 50mm x 30mm standard thermal sticker
      final labelFormat = PdfPageFormat(50 * PdfPageFormat.mm, 30 * PdfPageFormat.mm, marginAll: 2 * PdfPageFormat.mm);

      for (int i = 0; i < copies; i++) {
        pdf.addPage(
          pw.Page(
            pageFormat: labelFormat,
            build: (context) {
              return pw.Container(
                alignment: pw.Alignment.center,
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (showStoreName)
                      pw.Text(
                        _storeName,
                        style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
                        maxLines: 1,
                      ),
                    if (showName)
                      pw.Text(
                        product.name,
                        style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold),
                        maxLines: 1,
                        textAlign: pw.TextAlign.center,
                      ),
                    pw.SizedBox(height: 2),
                    if (isQr)
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: barcodeData,
                        width: 32,
                        height: 32,
                      )
                    else
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.code128(),
                        data: barcodeData,
                        width: 100,
                        height: 24,
                        drawText: true,
                      ),
                    if (showPrice) ...[
                      pw.SizedBox(height: 1),
                      pw.Text(
                        'MRP: Rs. ${product.price.toStringAsFixed(0)}',
                        style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      }
    } else {
      // A4 Grid of stickers (3 columns x 8 rows = 24 per sheet)
      const labelsPerPage = 24;
      final pagesCount = (copies / labelsPerPage).ceil();

      for (int page = 0; page < pagesCount; page++) {
        final currentCount = (page == pagesCount - 1) ? (copies - (page * labelsPerPage)) : labelsPerPage;
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(12),
            build: (context) {
              return pw.GridView(
                crossAxisCount: 3,
                childAspectRatio: 2.2,
                children: List.generate(currentCount, (index) {
                  return pw.Container(
                    margin: const pw.EdgeInsets.all(4),
                    padding: const pw.EdgeInsets.all(4),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        if (showName)
                          pw.Text(
                            product.name,
                            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                            maxLines: 1,
                          ),
                        pw.SizedBox(height: 2),
                        pw.BarcodeWidget(
                          barcode: isQr ? pw.Barcode.qrCode() : pw.Barcode.code128(),
                          data: barcodeData,
                          width: isQr ? 35 : 120,
                          height: 26,
                          drawText: !isQr,
                        ),
                        if (showPrice)
                          pw.Text(
                            'Price: Rs. ${product.price.toStringAsFixed(0)}',
                            style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold),
                          ),
                      ],
                    ),
                  );
                }),
              );
            },
          ),
        );
      }
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Barcode_${product.name}',
    );
  }

  /// Generate PDF Document for Multiple Products with Copies
  Future<Uint8List> generateMultiBarcodeLabelsPdf({
    required List<BarcodePrintItem> items,
    bool isQr = false,
    bool showPrice = true,
    bool showName = true,
    bool showStoreName = true,
    bool isSingleThermal = true,
  }) async {
    final pdf = pw.Document();

    if (isSingleThermal) {
      final labelFormat = PdfPageFormat(
        50 * PdfPageFormat.mm,
        30 * PdfPageFormat.mm,
        marginAll: 2 * PdfPageFormat.mm,
      );

      for (final item in items) {
        final barcodeData = item.product.sku.isNotEmpty ? item.product.sku : item.product.id;
        for (int i = 0; i < item.copies; i++) {
          pdf.addPage(
            pw.Page(
              pageFormat: labelFormat,
              build: (context) {
                return pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (showStoreName)
                        pw.Text(
                          _storeName,
                          style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
                          maxLines: 1,
                        ),
                      if (showName)
                        pw.Text(
                          item.product.name,
                          style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold),
                          maxLines: 1,
                          textAlign: pw.TextAlign.center,
                        ),
                      pw.SizedBox(height: 2),
                      if (isQr)
                        pw.BarcodeWidget(
                          barcode: pw.Barcode.qrCode(),
                          data: barcodeData,
                          width: 32,
                          height: 32,
                        )
                      else
                        pw.BarcodeWidget(
                          barcode: pw.Barcode.code128(),
                          data: barcodeData,
                          width: 100,
                          height: 24,
                          drawText: true,
                        ),
                      if (showPrice) ...[
                        pw.SizedBox(height: 1),
                        pw.Text(
                          'MRP: Rs. ${item.product.price.toStringAsFixed(0)}',
                          style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          );
        }
      }
    } else {
      // A4 Sheet: 3 columns x 8 rows = 24 stickers per sheet
      const labelsPerPage = 24;
      final List<Product> flattenedList = [];
      for (final item in items) {
        for (int i = 0; i < item.copies; i++) {
          flattenedList.add(item.product);
        }
      }

      final pagesCount = (flattenedList.length / labelsPerPage).ceil();

      for (int page = 0; page < pagesCount; page++) {
        final startIndex = page * labelsPerPage;
        final endIndex = (startIndex + labelsPerPage < flattenedList.length)
            ? startIndex + labelsPerPage
            : flattenedList.length;
        final pageProducts = flattenedList.sublist(startIndex, endIndex);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(12),
            build: (context) {
              return pw.GridView(
                crossAxisCount: 3,
                childAspectRatio: 2.2,
                children: pageProducts.map((product) {
                  final barcodeData = product.sku.isNotEmpty ? product.sku : product.id;
                  return pw.Container(
                    margin: const pw.EdgeInsets.all(4),
                    padding: const pw.EdgeInsets.all(4),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        if (showStoreName)
                          pw.Text(
                            _storeName,
                            style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                            maxLines: 1,
                          ),
                        if (showName)
                          pw.Text(
                            product.name,
                            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                            maxLines: 1,
                          ),
                        pw.SizedBox(height: 2),
                        pw.BarcodeWidget(
                          barcode: isQr ? pw.Barcode.qrCode() : pw.Barcode.code128(),
                          data: barcodeData,
                          width: isQr ? 35 : 120,
                          height: 26,
                          drawText: !isQr,
                        ),
                        if (showPrice)
                          pw.Text(
                            'Price: Rs. ${product.price.toStringAsFixed(0)}',
                            style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        );
      }
    }

    return pdf.save();
  }

  /// Print Multi-Product Barcode Labels
  Future<void> printMultiProductBarcodeLabels({
    required List<BarcodePrintItem> items,
    bool isQr = false,
    bool showPrice = true,
    bool showName = true,
    bool showStoreName = true,
    bool isSingleThermal = true,
  }) async {
    final pdfBytes = await generateMultiBarcodeLabelsPdf(
      items: items,
      isQr: isQr,
      showPrice: showPrice,
      showName: showName,
      showStoreName: showStoreName,
      isSingleThermal: isSingleThermal,
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Barcode_Labels_Batch',
    );
  }

  /// Share / Save Multi-Product Barcode PDF
  Future<void> shareMultiProductBarcodePdf({
    required List<BarcodePrintItem> items,
    bool isQr = false,
    bool showPrice = true,
    bool showName = true,
    bool showStoreName = true,
    bool isSingleThermal = true,
  }) async {
    final pdfBytes = await generateMultiBarcodeLabelsPdf(
      items: items,
      isQr: isQr,
      showPrice: showPrice,
      showName: showName,
      showStoreName: showStoreName,
      isSingleThermal: isSingleThermal,
    );
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'KRM_Barcode_Labels_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
    );
  }

  /// Test Print to verify printer
  Future<void> testPrint() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: _paperSize.format,
        build: (context) {
          final isThermal = _paperSize != PrinterPaperSize.a4;
          return pw.Container(
            padding: const pw.EdgeInsets.all(10),
            alignment: pw.Alignment.center,
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('=== PRINTER TEST OK ===',
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text(_storeName, style: const pw.TextStyle(fontSize: 10)),
                pw.Text(_storeAddress, style: const pw.TextStyle(fontSize: 8)),
                pw.Text('PAN: $_panNumber', style: const pw.TextStyle(fontSize: 8)),
                pw.SizedBox(height: 6),
                pw.Divider(borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 6),
                pw.Text('Testing receipt printer communication.', style: const pw.TextStyle(fontSize: 8)),
                pw.Text('DateTime: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 7.5)),
                pw.SizedBox(height: 8),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.code128(),
                  data: 'KRM-TEST-12345',
                  width: isThermal ? 130 : 160,
                  height: 30,
                  drawText: true,
                ),
                pw.SizedBox(height: 8),
                pw.Text('✓ Print Success!',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Printer_Test_Page',
    );
  }
}
