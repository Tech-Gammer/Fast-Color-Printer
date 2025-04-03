import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../Providers/customerprovider.dart';
import '../Providers/invoicemodel.dart';
import '../Providers/itemmodel.dart';
import '../Providers/lanprovider.dart';
import 'invoice list page.dart';

class InvoiceScreen extends StatefulWidget {
  final Customer customer;
  final Invoice? invoice;
  final String? invoiceId;

  const InvoiceScreen({
    super.key,
    required this.customer,
    this.invoice,
    this.invoiceId,
  });

  @override
  _InvoiceScreenState createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  final Map<String, TextEditingController> _quantityControllers = {};
  final Map<String, bool> _selectedItems = {};
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  double _subtotal = 0.0;
  double _discount = 0.0;
  List<CustomerItemAssignment> _items = [];
  DateTime? _dueDate;
  bool _isSaving = false; // Add this line

  // @override
  // void initState() {
  //   super.initState();
  //   _initializeExistingInvoice();
  //   _discountController.addListener(_updateTotals);
  // }
  //
  // void _initializeExistingInvoice() {
  //   if (widget.invoice != null) {
  //     _discountController.text = widget.invoice!.discount.toStringAsFixed(2);
  //     _dueDateController.text = DateFormat('yyyy-MM-dd').format(widget.invoice!.dueDate);
  //     _dueDate = widget.invoice!.dueDate;
  //
  //     for (var item in widget.invoice!.items) {
  //       _selectedItems[item['itemId']] = true;
  //       _quantityControllers[item['itemId']] =
  //           TextEditingController(text: item['quantity'].toString());
  //     }
  //
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       _updateTotals();
  //     });
  //   }
  // }

  @override
  void initState() {
    super.initState();
    _initializeExistingInvoice();
    _discountController.addListener(_updateTotals);
  }

  void _initializeExistingInvoice() {
    if (widget.invoice != null) {
      _discountController.text = widget.invoice!.discount.toStringAsFixed(2);
      _dueDateController.text = DateFormat('yyyy-MM-dd').format(widget.invoice!.dueDate);
      _dueDate = widget.invoice!.dueDate;
    }
  }

  void _updateTotals() {
    setState(() {
      _subtotal = 0.0;
      for (var item in _items) {
        final itemId = item.itemId;
        if (_selectedItems[itemId] ?? false) {
          final quantity = double.tryParse(_quantityControllers[itemId]?.text ?? '0') ?? 0;
          _subtotal += item.rate * quantity;
        }
      }
      _discount = double.tryParse(_discountController.text) ?? 0.0;
    });
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
        _dueDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _saveInvoice() async {

    if (_isSaving) return; // Prevent multiple calls
    setState(() => _isSaving = true);

    final selectedItems = _items.where((item) => _selectedItems[item.itemId] ?? false).toList();

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
            Provider.of<LanguageProvider>(context, listen: false).isEnglish
                ? 'Please select at least one item'
                : 'کم از کم ایک آئٹم منتخب کریں'
        )),
      );
      setState(() => _isSaving = false);
      return;
    }

    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
            Provider.of<LanguageProvider>(context, listen: false).isEnglish
                ? 'Please select a due date'
                : 'آخری تاریخ منتخب کریں'
        )),
      );
      setState(() => _isSaving = false);
      return;
    }

    final List<Map<String, dynamic>> invoiceItems = [];

    for (var item in selectedItems) {
      final quantity = double.tryParse(_quantityControllers[item.itemId]?.text ?? '0') ?? 0.0;
      invoiceItems.add({
        'itemId': item.itemId,
        'itemName': item.itemName,
        'rate': item.rate,
        'quantity': quantity,
      });
    }

    try {
      await Provider.of<CustomerProvider>(context, listen: false).saveInvoice(
        customerId: widget.customer.id,
        items: invoiceItems,
        subtotal: _subtotal,
        discount: _discount,
        grandTotal: _subtotal - _discount,
        dueDate: _dueDate!,
        invoiceId: widget.invoiceId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
              Provider.of<LanguageProvider>(context, listen: false).isEnglish
                  ? widget.invoice == null
                  ? 'Invoice saved successfully!'
                  : 'Invoice updated successfully!'
                  : widget.invoice == null
                  ? 'بل محفوظ ہو گیا'
                  : 'بل اپ ڈیٹ ہو گیا'
          )),
        );
        // Navigator.pop(context);
      }
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => InvoiceListScreen(customer: widget.customer),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
              Provider.of<LanguageProvider>(context, listen: false).isEnglish
                  ? 'Failed to save invoice: ${e.toString()}'
                  : 'بل محفوظ کرنے میں ناکام: ${e.toString()}'
          )),
        );
      }
    }
    finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildSaveButton(LanguageProvider languageProvider) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveInvoice, // Disable when saving
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.white) // Show loader
            : Text(
          languageProvider.isEnglish
              ? widget.invoice == null
              ? 'Create Invoice'
              : 'Update Invoice'
              : widget.invoice == null
              ? 'بل بنائیں'
              : 'بل اپ ڈیٹ کریں',
          style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = Provider.of<CustomerProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        // title: Text(
        //   languageProvider.isEnglish
        //       ? 'Invoice for ${widget.customer.name}'
        //       : '${widget.customer.name} کا بل',
        // ),
        title: Text(
          languageProvider.isEnglish
              ? widget.invoice == null
              ? 'New Invoice - ${widget.customer.name}'
              : 'Invoice ${widget.invoice?.formattedInvoiceNumber}'
              : widget.invoice == null
              ? 'نیا بل - ${widget.customer.name}'
              : 'بل ${widget.invoice?.formattedInvoiceNumber}',
        ),
        titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        elevation: 5,
      ),
      body: FutureBuilder<List<CustomerItemAssignment>>(
        future: customerProvider.getCustomerAssignments(widget.customer.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          _items = snapshot.data ?? [];


          // Initialize controllers and selected items
          for (var item in _items) {
            final itemId = item.itemId;
            _quantityControllers.putIfAbsent(itemId, () {
              final invoiceItem = widget.invoice?.items.firstWhere(
                    (i) => i['itemId'] == itemId,
                orElse: () => <String, dynamic>{},
              );
              return TextEditingController(
                text: (invoiceItem != null && invoiceItem.isNotEmpty)
                    ? invoiceItem['quantity'].toString()
                    : '0',
              );
            });

            _selectedItems.putIfAbsent(itemId, () {
              return widget.invoice?.items.any((i) => i['itemId'] == itemId) ?? false;
            });
          }

          // Trigger subtotal calculation after initializing data
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _updateTotals();
            }
          });

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (widget.invoice != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          languageProvider.isEnglish
                              ? 'Invoice Number: ${widget.invoice!.formattedInvoiceNumber}'
                              : 'بل نمبر: ${widget.invoice!.formattedInvoiceNumber}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView(
                    children: [
                      // Due Date Picker
                      TextFormField(
                        controller: _dueDateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: languageProvider.isEnglish
                              ? 'Due Date'
                              : 'آخری تاریخ',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () => _selectDueDate(context),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Items List
                      ..._items.map((item) {
                        final itemId = item.itemId;
                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(item.itemName,
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Checkbox(
                                      value: _selectedItems[itemId] ?? false,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedItems[itemId] = value!;
                                          if (!value) {
                                            _quantityControllers[itemId]?.text = '0';
                                          }
                                        });
                                        _updateTotals();
                                      },
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${item.rate.toStringAsFixed(2)}'),
                                    SizedBox(
                                      width: 100,
                                      child: TextFormField(
                                        controller: _quantityControllers[itemId],
                                        keyboardType: TextInputType.number,
                                        enabled: _selectedItems[itemId] ?? false,
                                        decoration: InputDecoration(
                                          labelText: languageProvider.isEnglish
                                              ? 'Quantity'
                                              : 'مقدار',
                                          border: const OutlineInputBorder(),
                                        ),
                                        onChanged: (value) => _updateTotals(),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                _buildTotalSection(context),
                const SizedBox(height: 10),
                _buildSaveButton(languageProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTotalSection(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final grandTotal = _subtotal - _discount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        children: [
          _buildTotalRow(
              languageProvider.isEnglish ? 'Subtotal:' : 'سب ٹوٹل:', _subtotal),
          const SizedBox(height: 10),
          _buildTotalRow(languageProvider.isEnglish ? 'Discount:' : 'ڈسکاؤنٹ:',
              _discount, isDiscount: true),
          const Divider(height: 20),
          _buildTotalRow(
              languageProvider.isEnglish ? 'Grand Total:' : 'کل مجموعی:',
              grandTotal,
              isBold: true),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double value,
      {bool isBold = false, bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: isBold ? 18 : 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        isDiscount
            ? SizedBox(
          width: 100,
          child: TextField(
            controller: _discountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        )
            : Text(value.toStringAsFixed(2),
            style: TextStyle(
                fontSize: isBold ? 18 : 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  @override
  void dispose() {
    _discountController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }
}