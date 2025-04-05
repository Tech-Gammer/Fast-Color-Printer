import 'dart:io';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../Providers/customerprovider.dart';
import '../Providers/invoicemodel.dart';
import '../Providers/lanprovider.dart';

class InvoicePaymentScreen extends StatefulWidget {
  final Customer customer;
  final Invoice invoice;
  final Map<String, dynamic>? payment; // Add this line

  const InvoicePaymentScreen({
    super.key,
    required this.customer,
    required this.invoice,
    this.payment, // Add this line

  });

  @override
  _InvoicePaymentScreenState createState() => _InvoicePaymentScreenState();
}

class _InvoicePaymentScreenState extends State<InvoicePaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  DateTime _paymentDate = DateTime.now();
  String? _paymentMethod = 'cash';
  final _descriptionController = TextEditingController();
  String? _base64Image;
  double _remainingAmount = 0.0;
  String? _paymentId; // Declare _paymentId

  @override
  void initState() {
    super.initState();
    _remainingAmount = widget.invoice.grandTotal - widget.invoice.paidAmount;
    if (widget.payment != null) {
      _amountController.text = (widget.payment!['amount'] as num).toString();
      _paymentDate = DateTime.fromMillisecondsSinceEpoch(
          widget.payment!['date'] ?? widget.payment!['timestamp']
      );
      _paymentMethod = widget.payment!['method']?.toString() ?? 'cash';
      _descriptionController.text = widget.payment!['description']?.toString() ?? '';
      _base64Image = widget.payment!['image']?.toString();

      // Adjust remaining amount for editing
      _remainingAmount += (widget.payment!['amount'] as num).toDouble();

      // Ensure the payment ID is correctly passed to the save function
      _paymentId = widget.payment!['id'];  // <-- Add this line to store the payment ID
    }

  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();
      setState(() {
        _base64Image = base64Encode(bytes);
      });
    }
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;

    final paymentData = {
      'id': _paymentId,  // <-- Include payment ID here
      'amount': double.parse(_amountController.text),
      'method': _paymentMethod,
      'date': _paymentDate.millisecondsSinceEpoch,
      'description': _descriptionController.text,
      'image': _base64Image,
      'timestamp': ServerValue.timestamp,
      if (widget.payment != null) 'id': widget.payment!['id'],  // Ensure the ID is set correctly
    };


    try {
      final customerProvider = Provider.of<CustomerProvider>(context, listen: false);

      if (widget.payment == null) {
        await customerProvider.addPayment(
          widget.customer.id,
          widget.invoice.id,
          paymentData,
        );
      } else {
        await customerProvider.updatePayment(
          widget.customer.id,
          widget.invoice.id,
          paymentData,
        );
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.isEnglish ? 'Record Payment' : 'ادائیگی درج کریں'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: languageProvider.isEnglish ? 'Amount' : 'رقم',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return languageProvider.isEnglish
                        ? 'Please enter amount'
                        : 'رقم درج کریں';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                items: ['cash', 'check', 'online'].map((method) {
                  return DropdownMenuItem(
                    value: method,
                    child: Text(method.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _paymentMethod = value),
                decoration: InputDecoration(
                  labelText: languageProvider.isEnglish ? 'Method' : 'طریقہ',
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(DateFormat('yyyy-MM-dd HH:mm').format(_paymentDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _paymentDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _paymentDate = date);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: languageProvider.isEnglish ? 'Description' : 'تفصیل',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickImage,
                child: Text(languageProvider.isEnglish ? 'Upload Receipt' : 'رسید اپ لوڈ کریں'),
              ),
              if (_base64Image != null)
                Image.memory(base64Decode(_base64Image!),height: 100),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _savePayment,
                child: Text(languageProvider.isEnglish ? 'Save Payment' : 'ادائیگی محفوظ کریں'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}