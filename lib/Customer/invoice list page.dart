import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../Providers/customerprovider.dart';
import '../Providers/invoicemodel.dart';
import '../Providers/lanprovider.dart';
import 'invoicepage.dart';

class InvoiceListScreen extends StatelessWidget {
  final Customer customer;

  const InvoiceListScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          languageProvider.isEnglish
              ? 'Invoices - ${customer.name}'
              : '${customer.name} - بل',
        ),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InvoiceScreen(customer: customer),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Invoice>>(
        future: Provider.of<CustomerProvider>(context, listen: false)
            .getInvoicesByCustomerId(customer.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(languageProvider.isEnglish
                  ? 'Error loading invoices'
                  : 'بل لوڈ کرنے میں خرابی'),
            );
          }

          final invoices = snapshot.data ?? [];

          if (invoices.isEmpty) {
            return Center(
              child: Text(
                languageProvider.isEnglish
                    ? 'No invoices found'
                    : 'کوئی بل نہیں ملا',
                style: const TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: invoices.length,
            itemBuilder: (context, index) {
              final invoice = invoices[index];
              return _buildInvoiceCard(context, invoice, customer);
            },
          );
        },
      ),
    );
  }

  Widget _buildInvoiceCard(BuildContext context, Invoice invoice, Customer customer) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final formatter = NumberFormat.currency(locale: 'en_US', symbol: 'PKR ');
    final dateFormatter = DateFormat('dd MMM yyyy');

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InvoiceScreen(
            customer: customer,
            invoice: invoice,
            invoiceId: invoice.id,
          ),
        ),
      ),
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateFormatter.format(DateTime.fromMillisecondsSinceEpoch(invoice.timestamp)),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteInvoice(context, invoice.id),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    languageProvider.isEnglish ? 'Due Date:' : 'آخری تاریخ:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    dateFormatter.format(invoice.dueDate),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    languageProvider.isEnglish ? 'Items:' : 'اشیاء:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${invoice.items.length} ${languageProvider.isEnglish ? 'items' : 'اشیاء'}',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    languageProvider.isEnglish ? 'Grand Total:' : 'کل رقم:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    formatter.format(invoice.grandTotal),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
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

  void _deleteInvoice(BuildContext context, String invoiceId) async {
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageProvider.isEnglish
            ? 'Delete Invoice'
            : 'بل حذف کریں'),
        content: Text(languageProvider.isEnglish
            ? 'Are you sure you want to delete this invoice?'
            : 'کیا آپ واقعی یہ بل حذف کرنا چاہتے ہیں؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(languageProvider.isEnglish ? 'Cancel' : 'منسوخ کریں'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              languageProvider.isEnglish ? 'Delete' : 'حذف کریں',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        await Provider.of<CustomerProvider>(context, listen: false)
            .deleteInvoice(customer.id, invoiceId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.isEnglish
                ? 'Invoice deleted'
                : 'بل حذف ہو گیا'),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.isEnglish
                ? 'Failed to delete invoice'
                : 'بل حذف کرنے میں ناکام'),
          ),
        );
      }
    }
  }
}