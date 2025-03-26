import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../Customer/quotationlistpage.dart';
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
      ) async {
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

  Future<void> saveQuotation({
    required String customerId,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double discount,
    required double grandTotal,
    String? quotationId,
  }) async {
    try {
      final ref = quotationId != null
          ? _quotationsRef.child(quotationId)
          : _quotationsRef.push();

      await ref.set({
        'customerId': customerId,
        'items': items,
        'subtotal': subtotal,
        'discount': discount,
        'grandTotal': grandTotal,
        'timestamp': quotationId != null
            ? ServerValue.timestamp
            : DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print("Error saving quotation: $e");
      throw e;
    }
  }


// Add to CustomerProvider
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



}
