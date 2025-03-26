// Item Model
class Item {
  final String id;
  final String itemName;  // Keep original field name
  final double salePrice; // Keep original field name

  Item({required this.id, required this.itemName, required this.salePrice});

  factory Item.fromSnapshot(String id, Map<dynamic, dynamic> data) {
    return Item(
      id: id,
      itemName: data['itemName'] ?? '',
      salePrice: double.parse(data['salePrice']?.toString() ?? '0.0'),
    );
  }
}

// Customer Item Assignment Model
class CustomerItemAssignment {
  final String id;
  final String customerId;
  final String itemId;
  final String itemName;
  final double rate;

  CustomerItemAssignment({
    required this.id,
    required this.customerId,
    required this.itemId,
    required this.itemName,
    required this.rate,
  });

  factory CustomerItemAssignment.fromSnapshot(String id, Map<dynamic, dynamic> data) {
    return CustomerItemAssignment(
      id: id,
      customerId: data['customerId'],
      itemId: data['itemId'],
      itemName: data['itemName'],
      rate: double.parse(data['rate']?.toString() ?? '0.0'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'itemId': itemId,
      'itemName': itemName,
      'rate': rate,
    };
  }
}