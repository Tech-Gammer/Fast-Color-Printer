import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../Providers/customerprovider.dart';
import '../Providers/invoicemodel.dart';

class PdfGenerator {
  static Future<File> generateInvoicePDF({
    required Customer customer,
    required Invoice invoice,
  }) async {
    final pdf = pw.Document();

    final logoImage = await rootBundle.load('assets/images/techlogo.png');
    final logo = pw.MemoryImage(logoImage.buffer.asUint8List());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Row(
            children: [
              pw.Image(logo, width: 100, height: 100),
              pw.SizedBox(width: 20),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('FAST COLOR PRINTER',
                      style: pw.TextStyle(
                          fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text('123 Print Street, Lahore',
                      style: pw.TextStyle(fontSize: 14)),
                  pw.Text('Phone: +92 300 1234567',
                      style: pw.TextStyle(fontSize: 14)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Header(
              level: 1,
              child: pw.Text('Invoice ${invoice.formattedInvoiceNumber}')),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Customer: ${customer.name}'),
                  pw.Text('Date: ${invoice.formattedDate}'),
                  pw.Text('Due Date: ${DateFormat('yyyy-MM-dd').format(invoice.dueDate)}'),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            context: context,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headers: ['Item', 'Rate', 'Qty', 'Total'],
            data: invoice.items.map((item) => [
              item['itemName'],
              'PKR ${item['rate'].toStringAsFixed(2)}',
              item['quantity'].toString(),
              'PKR ${(item['rate'] * item['quantity']).toStringAsFixed(2)}'
            ]).toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Subtotal: PKR ${invoice.subtotal.toStringAsFixed(2)}'),
                  pw.Text('Discount: PKR ${invoice.discount.toStringAsFixed(2)}'),
                  pw.Text('Grand Total: PKR ${invoice.grandTotal.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 16)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 40),
          pw.Center(child: pw.Text('Thank you for your business!')),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/invoice_${invoice.invoiceNumber}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }
}