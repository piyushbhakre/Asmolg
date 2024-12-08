import 'dart:collection';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartNotifier extends ValueNotifier<int> {

  CartNotifier() : super(0) {
    _loadCartFromStorage();
  }

  final Set<Map<String, String>> _cartItems = HashSet();

  Future<void> _loadCartFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final storedCart = prefs.getString('cartItems');
    if (storedCart != null) {
      final List<dynamic> decodedCart = jsonDecode(storedCart);
      for (var item in decodedCart) {
        _cartItems.add(Map<String, String>.from(item));
      }
      value = _cartItems.length; // Update the cart count
    }
  }

  Future<void> _saveCartToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, String>> cartList = _cartItems.toList();
    prefs.setString('cartItems', jsonEncode(cartList));
  }


  // Method to remove item by subjectId
  void removeItemById(String subjectId) {
    cartItems.removeWhere((item) => item['subjectId'] == subjectId);
    value = cartItems.length; // Update the cart count
  }

  void addItem(String subjectName, String departmentName, String price, String subjectId) async {
    if (_cartItems.add({
      'subjectName': subjectName,
      'departmentName': departmentName,
      'price': price,
      'subjectId': subjectId, // Store subjectId
    })) {
      value = _cartItems.length;
      await _saveCartToStorage();
    }
  }



  bool isAdded(String subjectId) {
    // Check if an item with the same subjectId already exists in the cart
    return _cartItems.any((item) => item['subjectId'] == subjectId);
  }

  void removeItem(String subjectId) async {
    // Remove item by subjectId
    _cartItems.removeWhere((item) => item['subjectId'] == subjectId);
    value = _cartItems.length;
    await _saveCartToStorage();
  }

  Set<Map<String, String>> get cartItems => _cartItems;
}

final cartNotifier = CartNotifier();
