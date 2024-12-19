import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../StateManager/CartState.dart';
import 'Billing Page.dart';

class CartPage extends StatelessWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: Colors.grey[50], // Light grey background
        appBar: AppBar(
          title: const Text(
            "Cart",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 1,
        ),
        body: ValueListenableBuilder<int>(
          valueListenable: cartNotifier,
          builder: (context, cartCount, child) {
            if (cartCount == 0) {
              return const Center(
                child: Text(
                  "Your cart is empty 🛒",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cart items list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80), // Avoid overlap with button
                    itemCount: cartCount,
                    itemBuilder: (context, index) {
                      final item = cartNotifier.cartItems.elementAt(index);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
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

                // Checkout Button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity, // Makes the button take the full width of the parent
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
                        padding: const EdgeInsets.symmetric(vertical: 16), // Removed horizontal padding
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        "Proceed to Checkout",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white, // Solid background color
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subjectName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Department: $departmentName",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Price: $price",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () {
                    cartNotifier.removeItemById(subjectId);

                    // Show FlutterToast
                    Fluttertoast.showToast(
                      msg: "Removed item: $subjectName",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM, // Position of the toast
                      backgroundColor: Colors.black54,
                      textColor: Colors.white,
                      fontSize: 16.0,
                    );
                  },

                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Colors.black, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Remove",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          color: Colors.grey.shade500, // Divider color
        ),
      ],
    );
  }
}



