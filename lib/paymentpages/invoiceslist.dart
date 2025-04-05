import 'package:fast_color_printer/paymentpages/paymentdetails.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../Providers/customerprovider.dart';
import '../Providers/invoicemodel.dart';
import '../Providers/lanprovider.dart';
import 'invoicepaymentscreen.dart';

class InvoiceListScreen extends StatelessWidget {
  final Customer customer;

  const InvoiceListScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final customerProvider = Provider.of<CustomerProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          languageProvider.isEnglish
              ? 'Invoices - ${customer.name}'
              : 'بلز - ${customer.name}',
        ),
      ),
      body: FutureBuilder<List<Invoice>>(
        future: customerProvider.getInvoicesByCustomerId(customer.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(languageProvider.isEnglish
                  ? 'No invoices found'
                  : 'کوئی بل موجود نہیں'),
            );
          }
          final invoices = snapshot.data!;
          return ListView.builder(
            itemCount: invoices.length,
            itemBuilder: (context, index) {
              final invoice = invoices[index];
              final remainingAmount = invoice.grandTotal - invoice.paidAmount;
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  onTap: (){
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentDetailsPage(
                          invoice: invoice,
                          customer: customer,
                        ),
                      ),
                    );
                  },
                  title: Text(
                    languageProvider.isEnglish
                        ? 'Invoice ${invoice.formattedInvoiceNumber}'
                        : 'بل نمبر ${invoice.formattedInvoiceNumber}',
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${languageProvider.isEnglish ? 'Total:' : 'کل:'} ${invoice.grandTotal.toStringAsFixed(2)}',
                      ),
                      Text(
                        '${languageProvider.isEnglish ? 'Paid:' : 'ادا شدہ:'} ${invoice.paidAmount.toStringAsFixed(2)}',
                      ),
                      Text(
                        '${languageProvider.isEnglish ? 'Remaining:' : 'باقی:'} ${remainingAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: remainingAmount > 0 ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.payment),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InvoicePaymentScreen(
                            customer: customer,
                            invoice: invoice,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}