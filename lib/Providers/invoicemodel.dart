import 'package:intl/intl.dart';

// class Invoice {
//   final String id;
//   final String customerId;
//   final List<Map<String, dynamic>> items;
//   final double subtotal;
//   final double discount;
//   final double grandTotal;
//   final DateTime timestamp; // Changed to DateTime
//   final DateTime dueDate; // Ensure this is DateTime type
//   final int invoiceNumber;
//
//   Invoice({
//     required this.id,
//     required this.customerId,
//     required this.items,
//     required this.subtotal,
//     required this.discount,
//     required this.grandTotal,
//     required this.timestamp,
//     required this.dueDate, // Should be DateTime
//     required this.invoiceNumber,
//   });
//
//   String get formattedDate {
//     return DateFormat('dd MMM yyyy, hh:mm a').format(timestamp);
//   }
//
//   String get formattedDueDate {
//     return DateFormat('dd MMM yyyy').format(dueDate);
//   }
//
//   String get formattedInvoiceNumber {
//     return '#${invoiceNumber.toString().padLeft(6, '0')}';
//   }
//
//   static Invoice fromSnapshot(String id, Map<dynamic, dynamic> data) {
//     return Invoice(
//       id: id,
//       customerId: data['customerId']?.toString() ?? '',
//       items: _parseItems(data['items']),
//       subtotal: _toDouble(data['subtotal']),
//       discount: _toDouble(data['discount']),
//       grandTotal: _toDouble(data['grandTotal']),
//       timestamp: DateTime.fromMillisecondsSinceEpoch(_toInt(data['timestamp'])),
//       dueDate: DateTime.fromMillisecondsSinceEpoch(_toInt(data['dueDate'])),
//       invoiceNumber: _toInt(data['invoiceNumber']),
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'customerId': customerId,
//       'items': items,
//       'subtotal': subtotal,
//       'discount': discount,
//       'grandTotal': grandTotal,
//       'timestamp': timestamp.millisecondsSinceEpoch,
//       'dueDate': dueDate.millisecondsSinceEpoch,
//       'invoiceNumber': invoiceNumber,
//     };
//   }
//
//   static List<Map<String, dynamic>> _parseItems(dynamic itemsData) {
//     try {
//       if (itemsData == null) return [];
//
//       return (itemsData as List).map<Map<String, dynamic>>((item) {
//         return {
//           'itemId': item['itemId']?.toString() ?? '',
//           'itemName': item['itemName']?.toString() ?? '',
//           'rate': _toDouble(item['rate']),
//           'quantity': _toDouble(item['quantity']),
//         };
//       }).toList();
//     } catch (e) {
//       print('Error parsing items: $e');
//       return [];
//     }
//   }
//
//   static double _toDouble(dynamic value) {
//     if (value is double) return value;
//     if (value is int) return value.toDouble();
//     if (value is String) return double.tryParse(value) ?? 0.0;
//     return 0.0;
//   }
//
//   static int _toInt(dynamic value) {
//     if (value is int) return value;
//     if (value is double) return value.toInt();
//     if (value is String) return int.tryParse(value) ?? 0;
//     return 0;
//   }
// }

import 'package:intl/intl.dart';

class Invoice {
  // Core invoice properties
  final String id;
  final String customerId;
  final List<Map<String, dynamic>> items;
  final double subtotal;
  final double discount;
  final double grandTotal;
  final DateTime timestamp;
  final DateTime dueDate;
  final int invoiceNumber;

  // Payment tracking properties
  final double paidAmount;
  final DateTime? paymentDate;
  final List<Map<String, dynamic>>? payments;

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
    this.paidAmount = 0.0,
    this.paymentDate,
    this.payments,
  });

  // ====================
  // FORMATTED PROPERTIES
  // ====================

  String get formattedDate => DateFormat('dd MMM yyyy, hh:mm a').format(timestamp);
  String get formattedDueDate => DateFormat('dd MMM yyyy').format(dueDate);
  String get formattedPaymentDate => paymentDate != null
      ? DateFormat('dd MMM yyyy').format(paymentDate!)
      : 'Not Paid';
  String get formattedInvoiceNumber => '#${invoiceNumber.toString().padLeft(6, '0')}';

  // =================
  // PAYMENT STATUS
  // =================

  double get remainingAmount => (grandTotal - paidAmount).clamp(0, double.infinity);
  bool get isFullyPaid => remainingAmount <= 0;
  bool get isPartiallyPaid => paidAmount > 0 && !isFullyPaid;
  bool get isOverdue => DateTime.now().isAfter(dueDate) && !isFullyPaid;
  String get paymentStatus {
    if (isFullyPaid) return 'Paid';
    if (isOverdue) return 'Overdue';
    if (isPartiallyPaid) return 'Partial';
    return 'Pending';
  }

  // =================
  // SERIALIZATION
  // =================

  factory Invoice.fromSnapshot(String id, Map<dynamic, dynamic> data) {
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
      paidAmount: _toDouble(data['paidAmount']),
      paymentDate: data['paymentDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(_toInt(data['paymentDate']))
          : null,
      payments: _parsePayments(data['payments']),
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
      'paidAmount': paidAmount,
      'paymentDate': paymentDate?.millisecondsSinceEpoch,
      'payments': payments?.map((p) => {
        'amount': p['amount'],
        'method': p['method'],
        'date': p['date'],
        'description': p['description'],
        'image': p['image'],
      }).toList(),
    };
  }

  // =================
  // HELPER METHODS
  // =================

  static List<Map<String, dynamic>> _parseItems(dynamic itemsData) {
    try {
      return (itemsData as List?)?.map<Map<String, dynamic>>((item) {
        final rate = _toDouble(item['rate']);
        final quantity = _toDouble(item['quantity']);
        return {
          'itemId': item['itemId']?.toString() ?? '',
          'itemName': item['itemName']?.toString() ?? '',
          'rate': rate,
          'quantity': quantity,
          'total': rate * quantity,
        };
      }).toList() ?? [];
    } catch (e) {
      print('Error parsing items: $e');
      return [];
    }
  }

  static List<Map<String, dynamic>>? _parsePayments(dynamic paymentsData) {
    if (paymentsData == null) return null;
    try {
      return (paymentsData as Map).entries.map((entry) {
        return {
          'id': entry.key,
          'amount': _toDouble(entry.value['amount']),
          'method': entry.value['method']?.toString() ?? 'cash',
          'date': _toInt(entry.value['date'] ?? entry.value['timestamp']),
          'description': entry.value['description']?.toString(),
          'image': entry.value['image']?.toString(),
        };
      }).toList();
    } catch (e) {
      print('Error parsing payments: $e');
      return null;
    }
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // =================
  // BUSINESS METHODS
  // =================

  Invoice copyWith({
    String? id,
    String? customerId,
    List<Map<String, dynamic>>? items,
    double? subtotal,
    double? discount,
    double? grandTotal,
    DateTime? timestamp,
    DateTime? dueDate,
    int? invoiceNumber,
    double? paidAmount,
    DateTime? paymentDate,
    List<Map<String, dynamic>>? payments,
  }) {
    return Invoice(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      grandTotal: grandTotal ?? this.grandTotal,
      timestamp: timestamp ?? this.timestamp,
      dueDate: dueDate ?? this.dueDate,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      paidAmount: paidAmount ?? this.paidAmount,
      paymentDate: paymentDate ?? this.paymentDate,
      payments: payments ?? this.payments,
    );
  }
}
