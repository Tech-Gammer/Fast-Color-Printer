// Create these as new files
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../Providers/customerprovider.dart';


class InvoiceScreen extends StatelessWidget {
  final Customer customer;

  const InvoiceScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Invoice for ${customer.name}'),
      ),
      body: const Center(
        child: Text('Invoice Form'),
      ),
    );
  }
}