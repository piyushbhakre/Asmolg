import 'dart:collection';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartNotifier extends ValueNotifier<int> {
  CartNotifier() : super(0) {
    _loadCartFromStorage();
  }

  final Set<Map<String, String>> _cartItems = HashSet();

  // Load cart from SharedPreferences
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

  // Save cart to SharedPreferences
  Future<void> _saveCartToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, String>> cartList = _cartItems.toList();
    prefs.setString('cartItems', jsonEncode(cartList));
  }

  // Method to remove item by subjectId and update SharedPreferences
  void removeItemById(String subjectId) async {
    // Remove the item from the cart
    _cartItems.removeWhere((item) => item['subjectId'] == subjectId);
    value = _cartItems.length; // Update the cart count

    // Save the updated cart to SharedPreferences
    await _saveCartToStorage();
  }

  // Method to add item to cart and save it to SharedPreferences
  void addItem(String subjectName, String departmentName, String price, String subjectId) async {
    if (_cartItems.add({
      'subjectName': subjectName,
      'departmentName': departmentName,
      'price': price,
      'subjectId': subjectId, // Store subjectId
    })) {
      value = _cartItems.length;
      await _saveCartToStorage(); // Save cart to SharedPreferences
    }
  }

  // Check if an item is already in the cart
  bool isAdded(String subjectId) {
    return _cartItems.any((item) => item['subjectId'] == subjectId);
  }

  // Get all the items in the cart
  Set<Map<String, String>> get cartItems => _cartItems;
}

final cartNotifier = CartNotifier();
