import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../Customer/quotationlistpage.dart';
import 'invoicemodel.dart';
import 'itemmodel.dart';

class Customer {
  final String id;
  final String name;
  final String address;
  final String phone;

  Customer({required this.id, required this.name, required this.address, required this.phone});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
    };
  }

  static Customer fromSnapshot(String id, Map<dynamic, dynamic> data) {
    return Customer(
      id: id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
    );
  }
}

class CustomerProvider with ChangeNotifier {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('customers');
  List<Customer> _customers = [];
  List<Customer> get customers => _customers;
  final DatabaseReference _customerItemsRef =
  FirebaseDatabase.instance.ref().child('customer_items');
  final DatabaseReference _quotationsRef = FirebaseDatabase.instance.ref().child('quotations');
  final DatabaseReference _metadataRef = FirebaseDatabase.instance.ref('metadata');


  Future<void> fetchCustomers() async {
    final snapshot = await _dbRef.get();
    if (snapshot.exists) {
      _customers = (snapshot.value as Map).entries.map((e) => Customer.fromSnapshot(e.key, e.value)).toList();
      notifyListeners();
    }
  }

  Future<void> addCustomer(String name, String address, String phone) async {
    final newCustomer = _dbRef.push();
    await newCustomer.set({'name': name, 'address': address, 'phone': phone});
    fetchCustomers(); // Refresh customer list
  }

  Future<void> updateCustomer(String id, String name, String address, String phone) async {
    await _dbRef.child(id).update({'name': name, 'address': address, 'phone': phone});
    fetchCustomers(); // Refresh list
  }

  Future<void> deleteCustomer(String id) async {
    try {
      await _dbRef.child(id).remove();

      await fetchCustomers();
    } catch (e) {
      print("Error deleting customer: $e");
      throw e;
    }
  }

  Future<void> assignItemToCustomer(
      String customerId,
      String itemId,
      String itemName,
      double rate,
      )
  async {
    await _customerItemsRef.push().set({
      'customerId': customerId,
      'itemId': itemId,
      'itemName': itemName,
      'rate': rate,
    });
    notifyListeners();
  }

  Future<void> updateCustomerItemAssignment(
      String assignmentId,
      double newRate,
      )
  async {
    await _customerItemsRef.child(assignmentId).update({'rate': newRate});
    notifyListeners();
  }

  Future<void> removeCustomerItemAssignment(String assignmentId) async {
    await _customerItemsRef.child(assignmentId).remove();
    notifyListeners();
  }

  Future<List<CustomerItemAssignment>> getCustomerAssignments(String customerId) async {
    final snapshot = await _customerItemsRef
        .orderByChild('customerId')
        .equalTo(customerId)
        .once();

    if (snapshot.snapshot.value == null) return [];

    return (snapshot.snapshot.value as Map).entries.map((e) {
      return CustomerItemAssignment.fromSnapshot(e.key, e.value);
    }).toList();
  }

  // In CustomerProvider class
  Future<void> saveQuotation({
    required String customerId,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double discount,
    required double grandTotal,
    String? quotationId,
  })
  async {
    try {
      final quotationNumberRef = _metadataRef.child('lastQuotationNumber');
      final quotationsRef = FirebaseDatabase.instance.ref('quotations');

      int quotationNumber;
      DatabaseReference ref;

      if (quotationId == null) {
        // Generate new quotation number
        final transactionResult = await quotationNumberRef.runTransaction((Object? currentData) {
          int currentNumber = (currentData as int?) ?? 0;
          currentNumber++;
          return Transaction.success(currentNumber);
        });

        if (!transactionResult.committed) throw 'Failed to generate quotation number';

        quotationNumber = transactionResult.snapshot.value as int;
        ref = quotationsRef.push();
      } else {
        // Existing quotation
        final snapshot = await quotationsRef.child(quotationId).get();
        if (!snapshot.exists) throw 'Quotation not found';

        final data = snapshot.value as Map<dynamic, dynamic>;
        quotationNumber = data['quotationNumber'] as int;
        ref = quotationsRef.child(quotationId);
      }

      await ref.set({
        'customerId': customerId,
        'items': items,
        'subtotal': subtotal,
        'discount': discount,
        'grandTotal': grandTotal,
        'timestamp': ServerValue.timestamp,
        'quotationNumber': quotationNumber,
      });

      notifyListeners();
    } catch (e) {
      print("Error saving quotation: $e");
      throw e;
    }
  }

  Future<List<Quotation>> getQuotationsByCustomerId(String customerId) async {
    try {
      final snapshot = await _quotationsRef
          .orderByChild('customerId')
          .equalTo(customerId)
          .once();

      if (snapshot.snapshot.value == null) return [];

      final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
      return data.entries.map((entry) {
        final key = entry.key.toString();
        final value = entry.value as Map<dynamic, dynamic>;
        return Quotation.fromSnapshot(key, value);
      }).toList();
    } catch (e) {
      print("Error fetching quotations: $e");
      throw e;
    }
  }

  Future<void> deleteQuotation(String quotationId) async {
    try {
      await _quotationsRef.child(quotationId).remove();
    } catch (e) {
      print("Error deleting quotation: $e");
      throw e;
    }
  }

  Future<void> saveInvoice({
    required String customerId,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double discount,
    required double grandTotal,
    required DateTime dueDate,
    String? invoiceId,
  })
  async   {
    try {
      final databaseRef = FirebaseDatabase.instance.ref('customers/$customerId/invoices');
      final invoiceNumberRef = _metadataRef.child('lastInvoiceNumber');

      int invoiceNumber;
      DatabaseReference invoiceRef;

      if (invoiceId == null) {
        // Generate new invoice number
        final transactionResult = await invoiceNumberRef.runTransaction((Object? currentData) {
          int currentNumber = (currentData as int?) ?? 0;
          currentNumber++;
          return Transaction.success(currentNumber);
        });

        if (!transactionResult.committed) throw 'Failed to generate invoice number';

        invoiceNumber = transactionResult.snapshot.value as int;
        invoiceRef = databaseRef.push(); // Create new reference
      } else {
        // Existing invoice
        final snapshot = await databaseRef.child(invoiceId).get();
        if (!snapshot.exists) throw 'Invoice not found';

        final data = snapshot.value as Map<dynamic, dynamic>;
        invoiceNumber = data['invoiceNumber'] as int;
        invoiceRef = databaseRef.child(invoiceId);
      }
      final invoiceData = {
        'customerId': customerId,
        'items': items,
        'subtotal': subtotal,
        'discount': discount,
        'grandTotal': grandTotal,
        'timestamp': ServerValue.timestamp,
        'dueDate': dueDate.millisecondsSinceEpoch,
        'invoiceNumber': invoiceNumber, // Include the invoice number

      };

      if (invoiceId == null) {
        await databaseRef.push().set(invoiceData);
        notifyListeners(); // Add this to trigger UI updates
      } else {
        await databaseRef.child(invoiceId).update(invoiceData);
      }
    } catch (e) {
      throw 'Error saving invoice: $e';
    }
  }

// Add to CustomerProvider
  Future<List<Invoice>> getInvoicesByCustomerId(String customerId) async {
    try {
      final databaseRef = FirebaseDatabase.instance.ref('customers/$customerId/invoices');
      final snapshot = await databaseRef.get();

      if (!snapshot.exists) return [];

      final Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;
      return values.entries.map((entry) {
        return Invoice.fromSnapshot(
          entry.key.toString(),
          entry.value as Map<dynamic, dynamic>,
        );
      }).toList();
    } catch (e) {
      throw 'Error fetching invoices: $e';
    }
  }

  Future<void> deleteInvoice(String customerId, String invoiceId) async {
    try {
      await FirebaseDatabase.instance
          .ref('customers/$customerId/invoices/$invoiceId')
          .remove();
    } catch (e) {
      throw 'Error deleting invoice: $e';
    }
  }

  Future<void> addPayment(
      String customerId,
      String invoiceId,
      Map<String, dynamic> payment,
      )
  async {
    try {
      if (customerId.isEmpty) throw 'Invalid customer ID';
      if (invoiceId.isEmpty) throw 'Invalid invoice ID';

      final amount = payment['amount'];
      if (amount == null || (amount is! num && amount is! String)) {
        throw 'Invalid payment amount';
      }

      final parsedAmount = amount is String ? double.tryParse(amount) : amount.toDouble();
      if (parsedAmount == null || parsedAmount <= 0) {
        throw 'Payment amount must be a positive number';
      }

      final database = FirebaseDatabase.instance;
      final invoiceRef = database.ref('customers/$customerId/invoices/$invoiceId');
      final paymentRef = database.ref('customers/$customerId/invoices/$invoiceId/payments');

      final snapshot = await invoiceRef.get();
      if (!snapshot.exists) throw 'Invoice not found';

      final invoiceData = snapshot.value as Map<dynamic, dynamic>;
      final currentPaid = _parsePaymentAmount(invoiceData['paidAmount']);
      final grandTotal = _parsePaymentAmount(invoiceData['grandTotal']);
      final newPaid = currentPaid + parsedAmount;

      if (newPaid > grandTotal * 1.5) {
        throw 'Payment amount exceeds maximum allowed overpayment';
      }

      // Perform the update in a transaction
      await invoiceRef.runTransaction((currentData) {
        // currentData might be null or not a Map, so handle that safely.
        final current = currentData is Map
            ? Map<String, dynamic>.from(currentData)
            : <String, dynamic>{};

        final updatedData = {
          ...current,
          'paidAmount': newPaid,
          if (newPaid >= grandTotal) 'paymentDate': ServerValue.timestamp,
        };

        // Return the new data directly.
        return Transaction.success(updatedData);
      });






      // Record the payment separately
      await paymentRef.push().set({
        'amount': parsedAmount,
        'method': payment['method']?.toString() ?? 'cash',
        'date': payment['date'] ?? ServerValue.timestamp,
        'description': payment['description']?.toString() ?? '',
        'image': payment['image']?.toString(),
        'timestamp': ServerValue.timestamp,
      });

      notifyListeners();
    } on FirebaseException catch (e) {
      throw 'Database error: ${e.message}';
    } catch (e) {
      throw 'Payment processing error: ${e.toString()}';
    }
  }

  double _parsePaymentAmount(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Future<List<Map<String, dynamic>>> getPayments(
      String customerId,
      String invoiceId
      )
  async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('customers/$customerId/invoices/$invoiceId/payments')
          .orderByChild('timestamp')
          .get();

      if (!snapshot.exists) return [];

      final payments = <Map<String, dynamic>>[];
      snapshot.children.forEach((child) {
        final payment = child.value as Map<dynamic, dynamic>;
        payments.add({
          'key': child.key,
          'amount': payment['amount'],
          'method': payment['method'],
          'date': payment['date'] ?? payment['timestamp'],
          'description': payment['description'],
          'image': payment['image'],
        });
      });

      // Sort by date descending
      payments.sort((a, b) => (b['date'] as int).compareTo(a['date'] as int));

      return payments;
    } catch (e) {
      throw 'Failed to load payments: ${e.toString()}';
    }
  }

  Future<void> updatePayment(
      String customerId,
      String invoiceId,
      Map<String, dynamic> updatedPayment,
      ) async {
    try {
      final paymentId = updatedPayment['id'];
      if (paymentId == null) throw 'Invalid payment ID';

      // Get references to Firebase nodes
      final paymentRef = FirebaseDatabase.instance
          .ref('customers/$customerId/invoices/$invoiceId/payments/$paymentId');

      final invoiceRef = FirebaseDatabase.instance
          .ref('customers/$customerId/invoices/$invoiceId');

      // Get existing payment data
      final paymentSnapshot = await paymentRef.get();
      if (!paymentSnapshot.exists) throw 'Payment not found';

      // Calculate amount difference
      final oldAmount = _parsePaymentAmount(paymentSnapshot.child('amount').value);
      final newAmount = _parsePaymentAmount(updatedPayment['amount']);
      final amountDifference = newAmount - oldAmount;

      // Update payment data
      await paymentRef.update({
        'amount': newAmount,
        'method': updatedPayment['method'],
        'date': updatedPayment['date'],
        'description': updatedPayment['description'],
        'image': updatedPayment['image'],
      });

      // Update invoice paid amount in transaction
      await invoiceRef.runTransaction((currentData) {
        if (currentData == null) throw 'Invoice not found';

        final Map<String, dynamic> data = currentData as Map<String, dynamic>;
        final currentPaid = _parsePaymentAmount(data['paidAmount']);
        final newPaid = currentPaid + amountDifference;
        final grandTotal = _parsePaymentAmount(data['grandTotal']);

        // Validate new paid amount
        if (newPaid < 0) throw 'Paid amount cannot be negative';
        if (newPaid > grandTotal * 1.5) throw 'Payment exceeds maximum allowed';

        data['paidAmount'] = newPaid;
        if (newPaid >= grandTotal) {
          data['paymentDate'] = ServerValue.timestamp;
        }

        return Transaction.success(data);  // Return Transaction.success
      });

      notifyListeners();
    } on FirebaseException catch (e) {
      throw 'Database error: ${e.message}';
    } catch (e) {
      throw 'Payment update failed: ${e.toString()}';
    }
  }




}
