import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';

import 'itemmodel.dart';

class ItemProvider with ChangeNotifier {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('items');
  List<Item> _items = [];

  List<Item> get items => _items;

  Future<void> fetchItems() async {
    try {
      final snapshot = await _dbRef.get();
      if (snapshot.exists) {
        _items = (snapshot.value as Map).entries.map((e) {
          return Item.fromSnapshot(e.key, e.value);
        }).toList();
        notifyListeners(); // Ensure this is called to update listeners
      }
    } catch (e) {
      print("Error fetching items: $e");
    }
  }
}