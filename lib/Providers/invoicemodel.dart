import 'package:intl/intl.dart';

class Invoice {
  final String id;
  final String customerId;
  final List<Map<String, dynamic>> items;
  final double subtotal;
  final double discount;
  final double grandTotal;
  final int timestamp;
  final DateTime dueDate;

  Invoice({
    required this.id,
    required this.customerId,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.grandTotal,
    required this.timestamp,
    required this.dueDate,
  });

  String get formattedDate {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  String get formattedDueDate {
    return DateFormat('dd MMM yyyy').format(dueDate);
  }

  static Invoice fromSnapshot(String id, Map<dynamic, dynamic> data) {
    return Invoice(
      id: id,
      customerId: data['customerId']?.toString() ?? '',
      items: _parseItems(data['items']),
      subtotal: _toDouble(data['subtotal']),
      discount: _toDouble(data['discount']),
      grandTotal: _toDouble(data['grandTotal']),
      timestamp: _toInt(data['timestamp']),
      dueDate: DateTime.fromMillisecondsSinceEpoch(_toInt(data['dueDate'])),
    );
  }

  static List<Map<String, dynamic>> _parseItems(dynamic itemsData) {
    try {
      if (itemsData == null) return [];

      // Handle both Map and List formats
      final itemsList = itemsData is Map
          ? itemsData.values.toList()
          : itemsData is List
          ? itemsData
          : [];

      return itemsList.map<Map<String, dynamic>>((item) {
        final dynamicItem = item as Map<dynamic, dynamic>;
        return {
          'itemId': dynamicItem['itemId']?.toString() ?? '',
          'itemName': dynamicItem['itemName']?.toString() ?? '',
          'rate': _toDouble(dynamicItem['rate']),
          'quantity': _toDouble(dynamicItem['quantity']),
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