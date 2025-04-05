import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Providers/customerprovider.dart';
import '../Providers/itemmodel.dart';
import '../Providers/itemprovider.dart';
import '../Providers/lanprovider.dart';
import '../paymentpages/invoiceslist.dart';
import 'actionpage.dart';
import 'addcustomers.dart';

class CustomerList extends StatefulWidget {
  @override
  _CustomerListState createState() => _CustomerListState();
}

class _CustomerListState extends State<CustomerList> {
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  Map<String, double> _customerBalances = {};



  void _loadCustomerBalances() async {
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    await customerProvider.fetchCustomers();

    final Map<String, double> newBalances = {};

    for (var customer in customerProvider.customers) {
      try {
        final invoices = await customerProvider.getInvoicesByCustomerId(customer.id);
        double totalBalance = invoices.fold(0.0, (sum, invoice) {
          return sum + (invoice.grandTotal - invoice.paidAmount);
        });
        newBalances[customer.id] = totalBalance;
      } catch (e) {
        print('Error calculating balance for ${customer.name}: $e');
        newBalances[customer.id] = 0.0;
      }
    }

    setState(() => _customerBalances = newBalances);
  }


  @override
  void initState() {
    super.initState();
    _loadCustomerBalances();
  }


  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          languageProvider.isEnglish ? 'Customer List' : 'کسٹمر کی فہرست',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddCustomer()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: languageProvider.isEnglish
                    ? 'Search Customers'
                    : 'کسٹمر تلاش کریں',
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase(); // Update the search query
                });
              },
            ),
          ),
          Expanded(
            child: Consumer<CustomerProvider>(
              builder: (context, customerProvider, child) {
                return FutureBuilder(
                  future: customerProvider.fetchCustomers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.active ||
                        snapshot.connectionState == ConnectionState.active) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Filter customers based on the search query
                    final filteredCustomers = customerProvider.customers.where((customer) {
                      final name = customer.name.toLowerCase();
                      final phone = customer.phone.toLowerCase();
                      final address = customer.address.toLowerCase();
                      return name.contains(_searchQuery) ||
                          phone.contains(_searchQuery) ||
                          address.contains(_searchQuery);
                    }).toList();

                    if (filteredCustomers.isEmpty) {
                      return Center(
                        child: Text(
                          languageProvider.isEnglish
                              ? 'No customers found.'
                              : 'کوئی کسٹمر موجود نہیں',
                          style: TextStyle(color: Colors.blue.shade600),
                        ),
                      );
                    }

                    // Responsive layout
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 600) {
                          // Web layout (with remaining balance in the table)
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: SingleChildScrollView(
                              child: DataTable(
                                columns: [
                                  const DataColumn(label: Text('#')),
                                  DataColumn(
                                      label: Text(
                                        languageProvider.isEnglish ? 'Name' : 'نام',
                                        style: const TextStyle(fontSize: 20),
                                      )),
                                  DataColumn(
                                      label: Text(
                                        languageProvider.isEnglish ? 'Address' : 'پتہ',
                                        style: const TextStyle(fontSize: 20),
                                      )),
                                  DataColumn(
                                      label: Text(
                                        languageProvider.isEnglish ? 'Phone' : 'فون',
                                        style: const TextStyle(fontSize: 20),
                                      )),
                                  DataColumn(
                                      label: Text(
                                        languageProvider.isEnglish ? 'Balance' : 'بیلنس',
                                        style: const TextStyle(fontSize: 20),
                                      )),
                                  DataColumn(
                                      label: Text(
                                        languageProvider.isEnglish ? 'Actions' : 'عمل',
                                        style: const TextStyle(fontSize: 20),
                                      )),
                                ],
                                rows: filteredCustomers
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  final index = entry.key + 1;
                                  final customer = entry.value;
                                  return DataRow(cells: [
                                    DataCell(Text('$index')),
                                    DataCell(Text(customer.name)),
                                    DataCell(Text(customer.address)),
                                    DataCell(Text(customer.phone)),
                                    // DataCell(
                                    //   Text(
                                    //     'Balance: ${_customerBalances[customer.id]?.toStringAsFixed(2) ?? "0.00"}',
                                    //     style: const TextStyle(color: Colors.blue),
                                    //   ),
                                    // ),
                                    DataCell(
                                      Text(
                                        '${_customerBalances[customer.id]?.toStringAsFixed(2) ?? "0.00"}',
                                        style: TextStyle(color: Colors.blue),
                                      ),
                                    ),
                                    DataCell(Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () {
                                            _showEditDialog(context, customer, customerProvider);
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _showDeleteConfirmationDialog(context, customer, customerProvider),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.receipt, color: Colors.green),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => CustomerActionPage(customer: customer),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    )),
                                  ]);
                                }).toList(),
                              ),
                            ),
                          );
                        } else {
                          // Mobile layout (with remaining balance in the card)
                          return ListView.builder(
                            itemCount: filteredCustomers.length,
                            itemBuilder: (context, index) {
                              final customer = filteredCustomers[index];
                              return Card(
                                elevation: 4,
                                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                color: Colors.blue.shade50,
                                child: ListTile(
                                  onTap: (){
                                    Navigator.push(context, MaterialPageRoute(builder: (context)=>InvoiceListScreen(customer: customer,)));
                                  },
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue.shade400,
                                    child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
                                  ),
                                  title: Text(customer.name, style: TextStyle(color: Colors.blue.shade800)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(customer.address, style: TextStyle(color: Colors.blue.shade600)),
                                      const SizedBox(height: 4),
                                      Text(customer.phone, style: TextStyle(color: Colors.blue.shade600)),
                                      // Text(
                                      //   'Balance: ${_customerBalances[customer.id]?.toStringAsFixed(2) ?? "0.00"}',
                                      //   style: const TextStyle(color: Colors.blue),
                                      // ),
                                      Text(
                                        'Balance: ${_customerBalances[customer.id]?.toStringAsFixed(2) ?? "0.00"}',
                                        style: TextStyle(color: Colors.blue),
                                      ),
                                      // In both desktop and mobile layouts, modify the action buttons:
                                      IconButton(
                                        icon: Icon(Icons.receipt, color: Colors.green),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => CustomerActionPage(customer: customer),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () {
                                          _showEditDialog(context, customer, customerProvider);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _showDeleteConfirmationDialog(context, customer, customerProvider),
                                      ),

                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(
      BuildContext context,
      Customer customer,
      CustomerProvider customerProvider,
      )
  {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageProvider.isEnglish
            ? 'Delete Customer?'
            : 'کسٹمر حذف کریں؟'),
        content: Text(languageProvider.isEnglish
            ? 'Are you sure you want to delete ${customer.name}?'
            : 'کیا آپ واقعی ${customer.name} کو حذف کرنا چاہتے ہیں؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(languageProvider.isEnglish ? 'Cancel' : 'منسوخ کریں'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await customerProvider.deleteCustomer(customer.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(languageProvider.isEnglish
                        ? 'Customer deleted successfully'
                        : 'کسٹمر کامیابی سے حذف ہو گیا'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(languageProvider.isEnglish
                        ? 'Error deleting customer: $e'
                        : 'کسٹمر کو حذف کرنے میں خرابی: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(languageProvider.isEnglish ? 'Delete' : 'حذف کریں'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
      BuildContext context,
      Customer customer,
      CustomerProvider customerProvider,
      )
  {
    final nameController = TextEditingController(text: customer.name);
    final addressController = TextEditingController(text: customer.address);
    final phoneController = TextEditingController(text: customer.phone);
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    Future<void> _showAssignItemDialog() async {
      await itemProvider.fetchItems();
      List<CustomerItemAssignment> assignedItems = await customerProvider.getCustomerAssignments(customer.id);

      String? selectedItemId;
      double rate = 0.0;
      String? errorMessage;

      await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(languageProvider.isEnglish ? 'Assign Item' : 'آئٹم تفویض کریں'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      items: itemProvider.items.map((item) {
                        return DropdownMenuItem(
                          value: item.id,
                          child: Text('${item.itemName} (${item.salePrice})'),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() {
                        selectedItemId = value;
                        errorMessage = null; // Clear error when selecting a new item
                      }),
                      decoration: InputDecoration(
                        labelText: languageProvider.isEnglish ? 'Select Item' : 'آئٹم منتخب کریں',
                      ),
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: languageProvider.isEnglish ? 'Rate' : 'شرح',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => rate = double.tryParse(value) ?? 0.0,
                    ),
                    if (errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          errorMessage!,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(languageProvider.isEnglish ? 'Cancel' : 'منسوخ کریں'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (selectedItemId == null || rate <= 0) return;

                      // Check if item is already assigned to the customer
                      final isAlreadyAssigned = assignedItems.any(
                            (assignment) => assignment.itemId == selectedItemId,
                      );

                      if (isAlreadyAssigned) {
                        setState(() {
                          errorMessage = languageProvider.isEnglish
                              ? 'This item is already assigned to the customer!'
                              : 'یہ آئٹم پہلے ہی کسٹمر کو تفویض کیا جا چکا ہے!';
                        });
                        return;
                      }

                      final item = itemProvider.items
                          .firstWhere((element) => element.id == selectedItemId);

                      customerProvider.assignItemToCustomer(
                        customer.id,
                        selectedItemId!,
                        item.itemName,
                        rate,
                      );

                      Navigator.pop(context);
                    },
                    child: Text(languageProvider.isEnglish ? 'Assign' : 'تفویض کریں'),
                  ),
                ],
              );
            },
          );
        },
      );
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Customer', style: TextStyle(color: Colors.blue.shade800)),
          backgroundColor: Colors.blue.shade50,
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Colors.blue.shade600)),
                ),
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(labelText: 'Address', labelStyle: TextStyle(color: Colors.blue.shade600)),
                ),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(labelText: 'Phone', labelStyle: TextStyle(color: Colors.blue.shade600)),
                  keyboardType: TextInputType.phone,
                ),
                FutureBuilder<List<CustomerItemAssignment>>(
                  future: customerProvider.getCustomerAssignments(customer.id),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return CircularProgressIndicator();
                    final assignments = snapshot.data!;

                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(languageProvider.isEnglish
                                ? 'Assigned Items:'
                                : 'تفویض شدہ آئٹمز:'),
                            IconButton(
                              icon: Icon(Icons.add),
                              onPressed: _showAssignItemDialog,
                            ),
                          ],
                        ),
                        ...assignments.map((assignment) => ListTile(
                          title: Text(assignment.itemName),
                          subtitle: Text('Rate: ${assignment.rate}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () => _showEditRateDialog(
                                  context,
                                  customerProvider,
                                  assignment,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () => customerProvider
                                    .removeCustomerItemAssignment(assignment.id).then((value){
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(languageProvider.isEnglish
                                          ? ' Deleted successfully'
                                          : ' کامیابی سے حذف ہو گیا'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  setState(() {

                                  });
                                })
                              ),
                            ],
                          ),
                        )),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.blue.shade800)),
            ),
            ElevatedButton(
              onPressed: () {
                customerProvider.updateCustomer(
                  customer.id,
                  nameController.text,
                  addressController.text,
                  phoneController.text,
                );
                Navigator.pop(context);
              },
              child: const Text('Save'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade400),
            ),
          ],
        );
      },
    );
  }

  void _showEditRateDialog(
      BuildContext context,
      CustomerProvider customerProvider,
      CustomerItemAssignment assignment,
      )
  {
    TextEditingController rateController =
    TextEditingController(text: assignment.rate.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Rate'),
          content: TextFormField(
            controller: rateController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'New Rate'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newRate = double.tryParse(rateController.text) ?? 0.0;
                if (newRate > 0) {
                  customerProvider.updateCustomerItemAssignment(
                    assignment.id,
                    newRate,
                  );
                  Navigator.pop(context);
                }
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }
}