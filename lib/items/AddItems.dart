import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';

import '../Providers/lanprovider.dart';


class RegisterItemPage extends StatefulWidget {
  final Map<String, dynamic>? itemData;

  RegisterItemPage({this.itemData});

  @override
  _RegisterItemPageState createState() => _RegisterItemPageState();
}

class _RegisterItemPageState extends State<RegisterItemPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _itemNameController;
  late TextEditingController _costPriceController;
  late TextEditingController _salePriceController;
  late TextEditingController _qtyOnHandController;
  final TextEditingController _vendorsearchController = TextEditingController();
  final TextEditingController _unitSearchController = TextEditingController();
  final TextEditingController _categorySearchController = TextEditingController();

  String? _selectedUnit;
  String? _selectedVendor;
  String? _selectedCategory;

  List<String> _units = ['Kg','Pcs'];
  List<String> _vendors = [];
  List<String> _categories = [];
  bool _isLoadingVendors = false;
  List<String> _filteredVendors = [];
  List<String> _filteredCategories = [];

  @override
  void initState() {
    super.initState();
    _itemNameController = TextEditingController(text: widget.itemData?['itemName'] ?? '');
    _costPriceController = TextEditingController(text: widget.itemData?['costPrice']?.toString() ?? '');
    _salePriceController = TextEditingController(text: widget.itemData?['salePrice']?.toString() ?? '');
    _qtyOnHandController = TextEditingController(text: widget.itemData?['qtyOnHand']?.toString() ?? '');
    _selectedUnit = widget.itemData?['unit'];
    _selectedVendor = widget.itemData?['vendor'];
    _selectedCategory = widget.itemData?['category'];
// Listen for vendor search input changes
    _vendorsearchController.addListener(() {
      _filterVendors(_vendorsearchController.text);
    });


    _categorySearchController.addListener(() {
      _filterCategories(_categorySearchController.text);
    });
    fetchDropdownData();
  }

  void _filterVendors(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredVendors = List.from(_vendors);
      } else {
        _filteredVendors = _vendors
            .where((vendor) => vendor.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _filterCategories(String query) {
    setState(() {
      _filteredCategories = query.isEmpty
          ? List.from(_categories)
          : _categories.where((category) => category.toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  Future<void> fetchDropdownData() async {
    final DatabaseReference database = FirebaseDatabase.instance.ref();

    // Fetch units
    database.child('units').onValue.listen((event) {
      final Map? data = event.snapshot.value as Map?;
      if (data != null) {
        setState(() {
          _units = data.values
              .map<String>((value) => (value as Map)['name']?.toString() ?? '')
              .toList();
        });
      }
    });

    // Fetch vendors
    // database.child('vendors').onValue.listen((event) {
    //   final Map? data = event.snapshot.value as Map?;
    //   if (data != null) {
    //     setState(() {
    //       _vendors = data.values
    //           .map<String>((value) => (value as Map)['name']?.toString() ?? '')
    //           .toList();
    //     });
    //   }
    // });
    setState(() {
      _isLoadingVendors = true;
    });

    try {
      final snapshot = await database.child('vendors').get();
      if (snapshot.exists) {
        final Map<dynamic, dynamic> vendorData = snapshot.value as Map<dynamic, dynamic>;

        setState(() {
          _vendors = vendorData.entries.map((entry) => entry.value['name'] as String).toList();
          _filteredVendors = List.from(_vendors); // Initialize filtered vendors
        });
      }
    } catch (e) {
      print('Error fetching vendors: $e');
    } finally {
      setState(() {
        _isLoadingVendors = false;
      });
    }

    // Fetch categories
    database.child('category').onValue.listen((event) {
      final Map? data = event.snapshot.value as Map?;
      if (data != null) {
        setState(() {
          _categories = data.values
              .map<String>((value) => (value as Map)['name']?.toString() ?? '')
              .toList();
        });
      }
    });
  }

  Future<bool> checkIfItemExists(String itemName) async {
    final DatabaseReference database = FirebaseDatabase.instance.ref();
    final snapshot = await database.child('items').get();

    if (snapshot.exists && snapshot.value is Map) {
      Map<dynamic, dynamic> items = snapshot.value as Map<dynamic, dynamic>;

      for (var key in items.keys) {
        if (items[key]['itemName'].toString().toLowerCase() == itemName.toLowerCase()) {
          return true; // Case-insensitive match found
        }
      }
    }
    return false;
  }

// Method to clear form fields
  void _clearFormFields() {
    setState(() {
      _itemNameController.clear();
      _costPriceController.clear();
      _salePriceController.clear();
      _qtyOnHandController.clear();
      _selectedUnit = null;
      _selectedVendor = null;
      _selectedCategory = null;
    });
  }

  void saveOrUpdateItem() async {
    if (_formKey.currentState!.validate()) {
      final itemName = _itemNameController.text;

      // Check if item already exists in the database (only for new items)
      if (widget.itemData == null) {
        bool itemExists = await checkIfItemExists(itemName);
        if (itemExists) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Item with this name already exists!')),
          );
          return;
        }
      }

      final DatabaseReference database = FirebaseDatabase.instance.ref();

      final newItem = {
        'itemName': itemName,
        'unit': _selectedUnit,
        'costPrice': double.tryParse(_costPriceController.text) ?? 0.0,
        'salePrice': double.tryParse(_salePriceController.text) ?? 0.0,
        'qtyOnHand': int.tryParse(_qtyOnHandController.text) ?? 0,
        'vendor': _selectedVendor,
        'category': _selectedCategory,
      };

      if (widget.itemData == null) {
        // New item
        database.child('items').push().set(newItem).then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Item registered successfully!')),
          );
          _clearFormFields();
        }).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to register item: $error')),
          );
        });
      } else {
        // Update existing item
        database.child('items/${widget.itemData!['key']}').set(newItem).then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Item updated successfully!')),
          );
          // Navigator.push(context, MaterialPageRoute(builder: (context)=>ItemsListPage()));
        }).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update item: $error')),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          // 'Register Item',
          languageProvider.isEnglish ? 'Register Item' : 'آئٹم ایڈ کریں',
          style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  TextFormField(
                    controller: _itemNameController,
                    decoration: InputDecoration(
                      labelText: languageProvider.isEnglish ? 'Item Name' : 'آئٹم کا نام',
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return languageProvider.isEnglish ? 'Please enter the item name' : 'براہ کرم آئٹم کا نام درج کریں۔';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    decoration: InputDecoration(
                      labelText: languageProvider.isEnglish ? 'Unit' : 'یونٹ',
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                    items: _units.map((unit) {
                      return DropdownMenuItem(
                        value: unit,
                        child: Text(unit),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedUnit = value;
                      });
                    },
                    validator: (value) => value == null ?
                    languageProvider.isEnglish ? 'Please select a unit' : 'براہ کرم ایک یونٹ منتخب کریں۔'
                        : null,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _costPriceController,
                    decoration: InputDecoration(
                      labelText: languageProvider.isEnglish ? 'Cost Price' : 'لاگت کی قیمت',
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    // validator: (value) {
                    //   if (value == null || value.isEmpty) {
                    //     return 'Please enter the cost price';
                    //   }
                    //   return null;
                    // },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _salePriceController,
                    decoration: InputDecoration(
                      labelText: languageProvider.isEnglish ? 'Sale Price' : 'فروخت کی قیمت',
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    // validator: (value) {
                    //   if (value == null || value.isEmpty) {
                    //     return 'Please enter the sale price';
                    //   }
                    //   return null;
                    // },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _qtyOnHandController,
                    decoration: InputDecoration(
                      labelText: languageProvider.isEnglish ? 'Quantity on Hand' : 'موجود مقدار',
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    readOnly: widget.itemData != null, // Make it read-only if itemData is not null
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return languageProvider.isEnglish ? 'Please enter the quantity on hand' : 'براہ کرم ہاتھ میں مقدار درج کریں۔';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  if (_isLoadingVendors)
                    const Center(child: CircularProgressIndicator())
                  else if (_vendors.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          languageProvider.isEnglish ? 'Search Vendor' : 'وینڈر تلاش کریں',                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _vendorsearchController,
                          decoration: InputDecoration(
                            hintText: languageProvider.isEnglish ? 'Type to search vendors...' : 'وینڈرز کو تلاش کرنے کے لیے ٹائپ کریں...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.search),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Show suggestions only when there is input in the search field
                        if (_vendorsearchController.text.isNotEmpty)
                          Container(
                            height: 200, // Adjust height as needed
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListView.builder(
                              itemCount: _filteredVendors.length,
                              itemBuilder: (context, index) {
                                final vendor = _filteredVendors[index];
                                return ListTile(
                                  title: Text(vendor),
                                  onTap: () {
                                    setState(() {
                                      _selectedVendor = vendor;
                                      _vendorsearchController.clear(); // Clear search input
                                      _filteredVendors = List.from(_vendors); // Reset suggestions
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(
                                          languageProvider.isEnglish ? 'Selected Vendor:' : 'منتخب فروش:'
                                              '$vendor')),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 20),
                        if (_selectedVendor != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.blue),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    languageProvider.isEnglish ? 'Selected Vendor:' : 'منتخب فروش:' '$_selectedVendor',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: saveOrUpdateItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      languageProvider.isEnglish ? 'Register Item' : 'آئٹم ایڈ کریں',
                      style: TextStyle(color: Colors.white),),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
