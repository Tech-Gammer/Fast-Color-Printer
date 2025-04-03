import 'package:fast_color_printer/Customer/quotationpage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../Providers/customerprovider.dart';
import '../Providers/lanprovider.dart';

class Quotation {
  final String id;
  final String customerId;
  final List<Map<String, dynamic>> items;
  final double subtotal;
  final double discount;
  final double grandTotal;
  final int timestamp;
  final int quotationNumber;

  Quotation({
    required this.id,
    required this.customerId,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.grandTotal,
    required this.timestamp,
    required this.quotationNumber,

  });


  String get formattedDate {
    if (timestamp == 0) return 'No date';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  String get formattedQuotationNumber {
    return '#${quotationNumber.toString().padLeft(6, '0')}';
  }

  static Quotation fromSnapshot(String id, Map<dynamic, dynamic> data) {
    return Quotation(
      id: id,
      customerId: data['customerId']?.toString() ?? '',
      items: _parseItems(data['items']),
      subtotal: _toDouble(data['subtotal']),
      discount: _toDouble(data['discount']),
      grandTotal: _toDouble(data['grandTotal']),
      timestamp: _toInt(data['timestamp']),
      quotationNumber: _toInt(data['quotationNumber']),
    );
  }

  static List<Map<String, dynamic>> _parseItems(dynamic itemsData) {
    if (itemsData is! List) return [];
    return itemsData.map<Map<String, dynamic>>((item) {
      if (item is Map) {
        return {
          'itemId': item['itemId']?.toString() ?? '',
          'itemName': item['itemName']?.toString() ?? '',
          'rate': _toDouble(item['rate']),
          'quantity': _toDouble(item['quantity']),
        };
      }
      return {};
    }).toList();
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class QuotationListScreen extends StatelessWidget {
  final Customer customer;

  const QuotationListScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          languageProvider.isEnglish
              ? 'Quotations - ${customer.name}'
              : '${customer.name} - کوٹیشنز',
        ),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      actions: [
        IconButton(onPressed: (){
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuotationScreen(customer: customer),
            ),
          );
        }, icon: Icon(Icons.add,color: Colors.white,))
      ],
      ),
      body: FutureBuilder<List<Quotation>>(
        future: Provider.of<CustomerProvider>(context, listen: false)
            .getQuotationsByCustomerId(customer.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(languageProvider.isEnglish
                  ? 'Error loading quotations'
                  : 'کوٹیشنز لوڈ کرنے میں خرابی'),
            );
          }

          final quotations = snapshot.data ?? [];

          if (quotations.isEmpty) {
            return Center(
              child: Text(
                languageProvider.isEnglish
                    ? 'No quotations found'
                    : 'کوئی کوٹیشن نہیں ملا',
                style: const TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: quotations.length,
            itemBuilder: (context, index) {
              final quote = quotations[index];
              return _buildQuotationCard(context, quote, customer); // Pass customer here
            },
          );
        },
      ),
    );
  }

  Widget _buildQuotationCard(BuildContext context, Quotation quotation, Customer customer) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final formatter = NumberFormat.currency(locale: 'en_US', symbol: 'PKR ');

    return GestureDetector(
      // In _buildQuotationCard
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuotationScreen(
            customer: customer, // Pass customer directly
            quotation: quotation,
            quotationId: quotation.id,
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
                    quotation.formattedQuotationNumber,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    quotation.formattedDate,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteQuotation(context, quotation.id),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    languageProvider.isEnglish ? 'Items:' : 'اشیاء:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${quotation.items.length} ${languageProvider.isEnglish ? 'items' : 'اشیاء'}',
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
                    formatter.format(quotation.grandTotal),
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

  void _deleteQuotation(BuildContext context, String quotationId) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageProvider.isEnglish
            ? 'Delete Quotation'
            : 'کوٹیشن حذف کریں'),
        content: Text(languageProvider.isEnglish
            ? 'Are you sure you want to delete this quotation?'
            : 'کیا آپ واقعی یہ کوٹیشن حذف کرنا چاہتے ہیں؟'),
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
            .deleteQuotation(quotationId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.isEnglish
                ? 'Quotation deleted'
                : 'کوٹیشن حذف ہو گیا'),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.isEnglish
                ? 'Failed to delete quotation'
                : 'کوٹیشن حذف کرنے میں ناکام'),
          ),
        );
      }
    }
  }
}