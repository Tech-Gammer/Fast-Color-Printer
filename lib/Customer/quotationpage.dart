import 'package:fast_color_printer/Customer/quotationlistpage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Providers/customerprovider.dart';
import '../Providers/itemmodel.dart';
import '../Providers/lanprovider.dart';

class QuotationScreen extends StatefulWidget {
  final Customer customer;
  final Quotation? quotation; // Add this for editing
  final String? quotationId; // Add this for editing


  // const QuotationScreen({super.key, required this.customer});
  const QuotationScreen({
    super.key,
    required this.customer,
    this.quotation,
    this.quotationId,
  });

  @override
  _QuotationScreenState createState() => _QuotationScreenState();
}

class _QuotationScreenState extends State<QuotationScreen> {
  final Map<String, TextEditingController> _quantityControllers = {};
  final Map<String, bool> _selectedItems = {};
  final TextEditingController _discountController = TextEditingController();
  double _subtotal = 0.0;
  double _discount = 0.0;
  List<CustomerItemAssignment> _items = [];


  @override
  void initState() {
    super.initState();//ss
    _initializeExistingQuotation();
    _discountController.addListener(_updateTotals);
    if (widget.quotation != null) {
      _discountController.text = widget.quotation!.discount.toStringAsFixed(2);
    }
  }

  void _initializeUIAfterDataLoad(List<CustomerItemAssignment> items) {
    _items = items;
    for (var item in _items) {
      final itemId = item.itemId;
      final quoteItem = widget.quotation?.items.firstWhere(
            (i) => i['itemId'] == itemId,
        orElse: () => <String, dynamic>{},
      );

      _selectedItems[itemId] = quoteItem?.isNotEmpty ?? false;
      _quantityControllers.putIfAbsent(itemId, () => TextEditingController(
        text: quoteItem?['quantity']?.toString() ?? '0',
      ));
    }

    // Calculate totals after initializing data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateTotals();
    });
  }

  void _initializeExistingQuotation() {
    if (widget.quotation != null) {
      // Initialize discount
      _discountController.text = widget.quotation!.discount.toStringAsFixed(2);

      // Initialize selected items and quantities
      for (var item in widget.quotation!.items) {
        _selectedItems[item['itemId']] = true;
        _quantityControllers[item['itemId']] =
            TextEditingController(text: item['quantity'].toString());
      }

      // Delay updating totals until UI has been built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateTotals();
      });
    }
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  void _updateTotals() {
    setState(() {
      _subtotal = 0.0;
      for (var item in _items) {
        final itemId = item.itemId;
        if (_selectedItems[itemId] ?? false) {
          // final quantity = double.tryParse(_quantityControllers[itemId]!.text) ?? 0;
          final quantity = double.tryParse(_quantityControllers[itemId]?.text ?? '0') ?? 0;
          _subtotal += item.rate * quantity;
        }
      }
      _discount = double.tryParse(_discountController.text) ?? 0.0;
    });
  }

  // Modify the save button onPressed handler
  void _saveQuotation() async {
    final selectedItems = _items.where((item)
    => _selectedItems[item.itemId] ?? false).toList();

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
            Provider.of<LanguageProvider>(context, listen: false).isEnglish
                ? 'Please select at least one item'
                : 'کم از کم ایک آئٹم منتخب کریں'
        )),
      );
      return;
    }

    final List<Map<String, dynamic>> quotationItems = [];

    for (var item in selectedItems) {
      final quantity = double.tryParse(
          _quantityControllers[item.itemId]?.text ?? '0'
      ) ?? 0.0;


      quotationItems.add({
        'itemId': item.itemId,
        'itemName': item.itemName,
        'rate': item.rate,
        'quantity': quantity,
      });
    }

    try {
      await Provider.of<CustomerProvider>(context, listen: false).saveQuotation(
        customerId: widget.customer.id,
        items: quotationItems,
        subtotal: _subtotal,
        discount: _discount,
        grandTotal: _subtotal - _discount,
        quotationId: widget.quotationId, // Pass existing ID for updates
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
              Provider.of<LanguageProvider>(context, listen: false).isEnglish
                  ? widget.quotation == null
                  ? 'Quotation saved successfully!'
                  : 'Quotation updated successfully!'
                  : widget.quotation == null
                  ? 'کوٹیشن محفوظ ہو گیا'
                  : 'کوٹیشن اپ ڈیٹ ہو گیا'
          )),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
              Provider.of<LanguageProvider>(context, listen: false).isEnglish
                  ? 'Failed to save quotation: ${e.toString()}'
                  : 'کوٹیشن محفوظ کرنے میں ناکام: ${e.toString()}'
          )),
        );
      }
    }
  }

  // Update the button text
  Widget _buildSaveButton(LanguageProvider languageProvider) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _saveQuotation,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          languageProvider.isEnglish
              ? widget.quotation == null
              ? 'Create Quotation'
              : 'Update Quotation'
              : widget.quotation == null
              ? 'کوٹیشن بنائیں'
              : 'کوٹیشن اپ ڈیٹ کریں',
          style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold
          ),
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
        title: Text(
          languageProvider.isEnglish
              ? 'Quotation for ${widget.customer.name}'
              : '${widget.customer.name} کا کوٹیشن',
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
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

          final items = snapshot.data ?? [];
          if (widget.quotation != null) {
            _initializeUIAfterDataLoad(items);
          } else {
            _items = items;
          }

          _items = snapshot.data ?? [];
          for (var item in _items) {
            final itemId = item.itemId;
            // Only initialize if not already set
            _quantityControllers.putIfAbsent(itemId, () {
              // Check if this item exists in the quotation
              final quoteItem = widget.quotation?.items.firstWhere(
                    (i) => i['itemId'] == itemId,
                orElse: () => <String, dynamic>{}, // ✅ Return empty map
              );
              return TextEditingController(
                // text: quoteItem!.isNotEmpty ? quoteItem['quantity'].toString() : '0',
                text: (quoteItem != null && quoteItem.isNotEmpty) ? quoteItem['quantity'].toString() : '0',
              );
            });

            _selectedItems.putIfAbsent(itemId, () {
              return widget.quotation?.items.any((i) => i['itemId'] == itemId) ?? false;
            });
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final itemId = item.itemId;
                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item.itemName,
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
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
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    languageProvider.isEnglish
                                        ? 'Rate: ${item.rate.toStringAsFixed(2)}'
                                        : 'شرح: ${item.rate.toStringAsFixed(2)}',
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
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
                                        contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 8),
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
                    },
                  ),
                ),
                _buildTotalSection(context),
                const SizedBox(height: 10),
                _buildSaveButton(languageProvider),
                // SizedBox(
                //   width: double.infinity,
                //   height: 50,
                //   child: ElevatedButton(
                //     // In QuotationScreen's ElevatedButton
                //     onPressed: () async {
                //       final selectedItems = _items.where((item)
                //       => _selectedItems[item.itemId] ?? false).toList();
                //
                //       if (selectedItems.isEmpty) {
                //         ScaffoldMessenger.of(context).showSnackBar(
                //           SnackBar(content: Text(
                //               Provider.of<LanguageProvider>(context, listen: false).isEnglish
                //                   ? 'Please select at least one item'
                //                   : 'کم از کم ایک آئٹم منتخب کریں'
                //           )),
                //         );
                //         return;
                //       }
                //
                //       final List<Map<String, dynamic>> quotationItems = [];
                //
                //       for (var item in selectedItems) {
                //         final quantity = double.tryParse(
                //             _quantityControllers[item.itemId]!.text
                //         ) ?? 0.0;
                //
                //         quotationItems.add({
                //           'itemId': item.itemId,
                //           'itemName': item.itemName,
                //           'rate': item.rate,
                //           'quantity': quantity,
                //         });
                //       }
                //
                //       try {
                //         await Provider.of<CustomerProvider>(context, listen: false).saveQuotation(
                //           customerId: widget.customer.id,
                //           items: quotationItems,
                //           subtotal: _subtotal,
                //           discount: _discount,
                //           grandTotal: _subtotal - _discount,
                //         );
                //
                //         if (mounted) {
                //           ScaffoldMessenger.of(context).showSnackBar(
                //             SnackBar(content: Text(
                //                 Provider.of<LanguageProvider>(context, listen: false).isEnglish
                //                     ? 'Quotation saved successfully!'
                //                     : 'کوٹیشن محفوظ ہو گیا'
                //             )),
                //           );
                //           Navigator.pop(context);
                //         }
                //       } catch (e) {
                //         if (mounted) {
                //           ScaffoldMessenger.of(context).showSnackBar(
                //             SnackBar(content: Text(
                //                 Provider.of<LanguageProvider>(context, listen: false).isEnglish
                //                     ? 'Failed to save quotation: ${e.toString()}'
                //                     : 'کوٹیشن محفوظ کرنے میں ناکام: ${e.toString()}'
                //             )),
                //           );
                //         }
                //       }
                //     },
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: Colors.blueAccent,
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(10),
                //       ),
                //     ),
                //     child: Text(
                //       languageProvider.isEnglish
                //           ? 'Create Quotation'
                //           : 'کوٹیشن بنائیں',
                //       style: const TextStyle(
                //           fontSize: 18, fontWeight: FontWeight.bold),
                //     ),
                //   ),
                // ),
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
}