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

  void addItem(String subjectName, String departmentName, String price) async {
    if (_cartItems.add({
      'subjectName': subjectName,
      'departmentName': departmentName,
      'price': price,
    })) {
      value = _cartItems.length;
      await _saveCartToStorage();
    }
  }

  bool isAdded(String subjectName) {
    return _cartItems.any((item) => item['subjectName'] == subjectName);
  }

  void removeItem(String subjectName) async {
    _cartItems.removeWhere((item) => item['subjectName'] == subjectName);
    value = _cartItems.length;
    await _saveCartToStorage();
  }

  Set<Map<String, String>> get cartItems => _cartItems;
}

final cartNotifier = CartNotifier();
