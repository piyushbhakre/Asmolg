import 'package:asmolg/Provider/offline-online_status.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../Provider/CartState.dart';
import 'Billing Page.dart';

class CartPage extends StatelessWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Refined background color
      appBar: AppBar(
        title: const Text(
          "My Cart",
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        bottom: OfflineBanner(),
        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF2C3E50)),
        elevation: 0, // Removed shadow for modern look
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: cartNotifier,
        builder: (context, cartCount, child) {
          if (cartCount == 0) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Your cart is empty",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Add items to get started",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFFBDC3C7),
                    ),
                  ),
                ],
              ),
            );
          }

          // Calculate total price
          double totalPrice = 0;
          for (var item in cartNotifier.cartItems) {
            totalPrice += double.parse(item['price']!.replaceAll('\$', ''));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with item count
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Text(
                  "$cartCount ${cartCount == 1 ? 'Item' : 'Items'} in your cart",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF34495E),
                  ),
                ),
              ),

              // Cart items list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100), // More space at bottom
                  itemCount: cartCount,
                  itemBuilder: (context, index) {
                    final item = cartNotifier.cartItems.elementAt(index);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16),
                      child: CartCard(
                        subjectId: item['subjectId']!,
                        subjectName: item['subjectName']!,
                        departmentName: item['departmentName']!,
                        price: item['price']!,
                      ),
                    );
                  },
                ),
              ),

              // Order summary container
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(20, 25, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order summary title
                    const Text(
                      "Order Summary",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Order details
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Subtotal",
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF7F8C8D),
                          ),
                        ),
                        Text(
                          "\₹${totalPrice.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Checkout button
                    SizedBox(
                      width: double.infinity,
                      height: 55, // Taller button
                      child: ElevatedButton(
                        onPressed: () {
                          // Pass the cart items (with subjectId) to the BillingPage
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BillingPage(
                                items: cartNotifier.cartItems.map((item) {
                                  return {
                                    'subjectId': item['subjectId']!,
                                    'subjectName': item['subjectName']!,
                                    'departmentName': item['departmentName']!,
                                    'price': item['price']!,
                                  };
                                }).toList(),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black, // Modern blue color
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Proceed to Checkout",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 10),
                            Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CartCard extends StatelessWidget {
  final String subjectId;
  final String subjectName;
  final String departmentName;
  final String price;

  const CartCard({
    Key? key,
    required this.subjectId,
    required this.subjectName,
    required this.departmentName,
    required this.price,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Course icon circle
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFEBF5FB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.book,
                  color: Colors.black,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 15),

            // Middle: Course details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subjectName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    departmentName,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            // Right: Remove button
            SizedBox(
              height: 36,
              width: 36,
              child: Material(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    cartNotifier.removeItemById(subjectId);

                    // Show FlutterToast
                    Fluttertoast.showToast(
                      msg: "Removed from cart",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      backgroundColor: const Color(0xFF34495E),
                      textColor: Colors.white,
                      fontSize: 16.0,
                    );
                  },
                  child: const Center(
                    child: Icon(
                      Icons.delete_outline,
                      color: Color(0xFFE74C3C),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}