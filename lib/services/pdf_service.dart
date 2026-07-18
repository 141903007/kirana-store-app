import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/sale_model.dart';
import '../models/store_settings_model.dart';
import '../repository/sale_repository.dart';
import '../utils/formatters.dart';

/// Builds the printable/shareable invoice PDF for a completed sale. Kept
/// deliberately simple for v1: one table, a totals block, no logo.
class PdfService {
  /// Devanagari glyphs aren't in the `pdf` package's default font — when
  /// [languageCode] is 'mr' the whole document's font is swapped to a
  /// bundled Noto Sans Devanagari, rather than detecting per string.
  static Future<Uint8List> buildInvoiceBytes({
    required SaleModel sale,
    required List<SaleItemDetail> items,
    required StoreSettingsModel settings,
    required String languageCode,
    String? customerName,
  }) async {
    final document = pw.Document();
    final theme = await _themeFor(languageCode);

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (settings.storeName != null)
                pw.Text(settings.storeName!,
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              if (settings.storeAddress != null) pw.Text(settings.storeAddress!),
              if (settings.storePhone != null) pw.Text(settings.storePhone!),
              if (settings.storeGstNumber != null) pw.Text('GSTIN: ${settings.storeGstNumber}'),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Invoice No: ${sale.invoiceNumber}'),
                  pw.Text('Date: ${Formatters.date(DateTime.parse(sale.saleDate))}'),
                ],
              ),
              pw.Text('Customer: ${customerName ?? 'Walk-in Customer'}'),
              pw.SizedBox(height: 16),
              pw.TableHelper.fromTextArray(
                headers: ['Item', 'Unit', 'Qty', 'Price', 'GST%', 'Total'],
                data: [
                  for (final detail in items)
                    [
                      detail.productName,
                      detail.item.variantLabel,
                      detail.item.quantity.toStringAsFixed(2),
                      Formatters.currency(detail.item.unitSellingPrice),
                      detail.item.gstPercent.toStringAsFixed(0),
                      Formatters.currency(detail.item.lineTotal),
                    ],
                ],
                cellAlignment: pw.Alignment.centerLeft,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 16),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _totalRow('Subtotal', sale.subtotal),
                    _totalRow('Discount', sale.discountAmount),
                    _totalRow('GST', sale.gstAmount),
                    pw.SizedBox(height: 4),
                    _totalRow('Total', sale.totalAmount, bold: true),
                  ],
                ),
              ),
              pw.SizedBox(height: 32),
              pw.Center(child: pw.Text('Thank you for shopping with us!')),
            ],
          );
        },
      ),
    );

    return document.save();
  }

  /// A generic tabular report (Purchase/Customer/Stock/Product/Sales
  /// reports all share this — one table, an optional total row, no
  /// per-report custom layout needed for v1).
  static Future<Uint8List> buildSimpleReportBytes({
    required String title,
    required List<String> columns,
    required List<List<String>> rows,
    required String languageCode,
    String? subtitle,
    String? totalLabel,
    String? totalValue,
  }) async {
    final document = pw.Document();
    final theme = await _themeFor(languageCode);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        build: (context) {
          return [
            pw.Text(title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            if (subtitle != null) pw.Text(subtitle),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: columns,
              data: rows,
              cellAlignment: pw.Alignment.centerLeft,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            if (totalLabel != null && totalValue != null) ...[
              pw.SizedBox(height: 12),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  '$totalLabel: $totalValue',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ];
        },
      ),
    );

    return document.save();
  }

  static Future<pw.ThemeData?> _themeFor(String languageCode) async {
    if (languageCode != 'mr') return null;
    final fontData = await rootBundle.load('assets/fonts/NotoSansDevanagari-Regular.ttf');
    final font = pw.Font.ttf(fontData);
    return pw.ThemeData.withFont(base: font, bold: font);
  }

  static pw.Widget _totalRow(String label, double value, {bool bold = false}) {
    final style = bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14) : null;
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Text('$label: ${Formatters.currency(value)}', style: style),
    );
  }
}
