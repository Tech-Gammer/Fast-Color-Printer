import 'package:fast_color_printer/Customer/quotationlistpage.dart';
import 'package:fast_color_printer/Customer/quotationpage.dart';
import 'package:fast_color_printer/Customer/invoicepage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Providers/customerprovider.dart';
import '../Providers/lanprovider.dart';
import 'invoice list page.dart';

class CustomerActionPage extends StatelessWidget {
  final Customer customer;

  const CustomerActionPage({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            _buildActionButton(
              context,
              icon: Icons.description,
              label: languageProvider.isEnglish
                  ? 'Quotations'
                  : 'کوٹیشن',
              color: Colors.blue,
              onPressed: () {
                // Navigate to quotation screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuotationListScreen(customer: customer),
                  ),
                );
              },
            ),
            const SizedBox(height: 25),
            _buildActionButton(
              context,
              icon: Icons.assignment,
              label: languageProvider.isEnglish
                  ? 'Invoices'
                  : 'انوائس',
              color: Colors.green,
              onPressed: () {
                // Navigate to invoice screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InvoiceListScreen(customer: customer),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context, {
        required IconData icon,
        required String label,
        required Color color,
        required VoidCallback onPressed,
      }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: Icon(icon, size: 30, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold
        ),
      ),
      onPressed: onPressed,
    );
  }
}