import 'package:flutter/material.dart';
import '../StateManager/CartState.dart';
import 'Billing Page.dart';

class CartPage extends StatelessWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Cart",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: cartNotifier,
        builder: (context, cartCount, child) {
          if (cartCount == 0) {
            return const Center(
              child: Text(
                "Your cart is empty 🛒",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartNotifier.value,
                  itemBuilder: (context, index) {
                    final item = cartNotifier.cartItems.elementAt(index);
                    return CartCard(
                      subjectId: item['subjectId']!,  // Passing the subjectId
                      subjectName: item['subjectName']!,
                      departmentName: item['departmentName']!,
                      price: item['price']!,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
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
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 15),
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Proceed to Checkout",
                    style: TextStyle(color: Colors.white, fontSize: 16),
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subjectName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text("Department: $departmentName"),
          const SizedBox(height: 8),
          Text("Price: $price"),
          const SizedBox(height: 8),
          Text("Subject ID: $subjectId"), // Display subjectId
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: () {
                // Remove item based on subjectId
                cartNotifier.removeItemById(subjectId);
                print("Removed item with Subject ID: $subjectId");
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
    );
  }
}

