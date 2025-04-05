import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../Providers/customerprovider.dart';
import '../Providers/invoicemodel.dart';
import '../Providers/lanprovider.dart';
import 'invoicepaymentscreen.dart';

class PaymentDetailsPage extends StatelessWidget {
  final Invoice invoice;
  final Customer customer;

  const PaymentDetailsPage({
    super.key,
    required this.invoice,
    required this.customer,
  });

  @override
  Widget build(BuildContext context) {
    final customerProvider = Provider.of<CustomerProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
            languageProvider.isEnglish
                ? 'Payment History - ${invoice.formattedInvoiceNumber}'
                : 'ادائیگی کی تاریخ - ${invoice.formattedInvoiceNumber}'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: customerProvider.getPayments(customer.id, invoice.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                languageProvider.isEnglish
                    ? 'Error loading payments'
                    : 'ادائیگیوں کو لوڈ کرنے میں خرابی',
              ),
            );
          }

          final payments = snapshot.data ?? [];
          final remainingAmount = invoice.grandTotal - invoice.paidAmount;

          return Column(
            children: [
              // Invoice Summary Card
              Card(
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languageProvider.isEnglish
                            ? 'Invoice ${invoice.formattedInvoiceNumber}'
                            : 'بل ${invoice.formattedInvoiceNumber}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(languageProvider.isEnglish
                              ? 'Total Amount:'
                              : 'کل رقم:'),
                          Text(
                            invoice.grandTotal.toStringAsFixed(2),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(languageProvider.isEnglish
                              ? 'Paid Amount:'
                              : 'ادا شدہ رقم:'),
                          Text(
                            invoice.paidAmount.toStringAsFixed(2),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(languageProvider.isEnglish
                              ? 'Remaining:'
                              : 'باقی:'),
                          Text(
                            remainingAmount.toStringAsFixed(2),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: remainingAmount > 0
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Payments List
              Expanded(
                child: payments.isEmpty
                    ? Center(
                  child: Text(
                    languageProvider.isEnglish
                        ? 'No payments recorded'
                        : 'کوئی ادائیگی درج نہیں ہوئی',
                  ),
                )
                    : ListView.builder(
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    return _buildPaymentCard(context, payment);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, Map<String, dynamic> payment) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final date = DateTime.fromMillisecondsSinceEpoch(payment['date'] ?? 0);
    final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
    final method = payment['method']?.toString() ?? 'cash';
    final description = payment['description']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    DateFormat('dd MMM yyyy, hh:mm a').format(date),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Row(
                  children: [
                    Chip(
                      label: Text(
                        method.toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: _getMethodColor(method),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InvoicePaymentScreen(
                            customer: customer,
                            invoice: invoice,
                            payment: payment,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  languageProvider.isEnglish ? 'Amount:' : 'رقم:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  amount.toStringAsFixed(2),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                languageProvider.isEnglish ? 'Notes:' : 'نوٹس:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(description),
            ],
            if (payment['image'] != null) ...[
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _showReceiptImage(context, payment['image']),
                child: Text(languageProvider.isEnglish
                    ? 'View Receipt'
                    : 'رسید دیکھیں'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getMethodColor(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Colors.blue;
      case 'check':
        return Colors.orange;
      case 'online':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showReceiptImage(BuildContext context, String base64Image) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Image.memory(base64Decode(base64Image)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}