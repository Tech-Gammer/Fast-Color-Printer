import 'package:intl/intl.dart';

class Invoice {
  final String id;
  final String customerId;
  final List<Map<String, dynamic>> items;
  final double subtotal;
  final double discount;
  final double grandTotal;
  final DateTime timestamp; // Changed to DateTime
  final DateTime dueDate;
  final int invoiceNumber;

  Invoice({
    required this.id,
    required this.customerId,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.grandTotal,
    required this.timestamp,
    required this.dueDate,
    required this.invoiceNumber,
  });

  String get formattedDate {
    return DateFormat('dd MMM yyyy, hh:mm a').format(timestamp);
  }

  String get formattedDueDate {
    return DateFormat('dd MMM yyyy').format(dueDate);
  }

  String get formattedInvoiceNumber {
    return '#${invoiceNumber.toString().padLeft(6, '0')}';
  }

  static Invoice fromSnapshot(String id, Map<dynamic, dynamic> data) {
    return Invoice(
      id: id,
      customerId: data['customerId']?.toString() ?? '',
      items: _parseItems(data['items']),
      subtotal: _toDouble(data['subtotal']),
      discount: _toDouble(data['discount']),
      grandTotal: _toDouble(data['grandTotal']),
      timestamp: DateTime.fromMillisecondsSinceEpoch(_toInt(data['timestamp'])),
      dueDate: DateTime.fromMillisecondsSinceEpoch(_toInt(data['dueDate'])),
      invoiceNumber: _toInt(data['invoiceNumber']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'items': items,
      'subtotal': subtotal,
      'discount': discount,
      'grandTotal': grandTotal,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'invoiceNumber': invoiceNumber,
    };
  }

  static List<Map<String, dynamic>> _parseItems(dynamic itemsData) {
    try {
      if (itemsData == null) return [];

      return (itemsData as List).map<Map<String, dynamic>>((item) {
        return {
          'itemId': item['itemId']?.toString() ?? '',
          'itemName': item['itemName']?.toString() ?? '',
          'rate': _toDouble(item['rate']),
          'quantity': _toDouble(item['quantity']),
        };
      }).toList();
    } catch (e) {
      print('Error parsing items: $e');
      return [];
    }
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