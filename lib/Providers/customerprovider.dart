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
      // Also delete related ledger entries if needed
      // await FirebaseDatabase.instance.ref('invoices/$id').remove();
      // await FirebaseDatabase.instance.ref('ledger/$id').remove();
      // await FirebaseDatabase.instance.ref('filled/$id').remove();
      // await FirebaseDatabase.instance.ref('filledledger/$id').remove();
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
      ) async {
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
  async {
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

}
