import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../StateManager/CartState.dart';

class BillingPage extends StatefulWidget {
  const BillingPage({
    Key? key,
    required this.items,
  }) : super(key: key);
  final List<Map<String, String>> items;

  @override
  _BillingPageState createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  final TextEditingController _couponController = TextEditingController();
  double discountPercentage = 0.0; // Discount percentage
  String appliedCoupon = ""; // The applied coupon code, if any
  bool isApplyingCoupon = false; // For showing progress
  double gstRate = 0.0; // GST percentage fetched from Firestore

  @override
  void initState() {
    super.initState();
    _fetchGST();
  }

  Future<void> _fetchGST() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Miscellaneous')
          .doc('GST')
          .get();

      if (doc.exists) {
        setState(() {
          gstRate = doc.data()?['gst'].toDouble() ?? 0.0;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to fetch GST rate.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching GST: $e")),
      );
    }
  }

  Future<void> _applyCoupon() async {
    final enteredCode = _couponController.text.trim();

    if (enteredCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a coupon code.")),
      );
      return;
    }

    setState(() {
      isApplyingCoupon = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Miscellaneous')
          .get();

      bool isValidCoupon = false;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['code'] == enteredCode) {
          setState(() {
            discountPercentage = data['discount'].toDouble();
            appliedCoupon = enteredCode;
          });
          isValidCoupon = true;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Coupon applied! ${discountPercentage.toStringAsFixed(0)}% off.",
              ),
            ),
          );
          break;
        }
      }

      if (!isValidCoupon) {
        setState(() {
          discountPercentage = 0.0;
          appliedCoupon = "";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid coupon code.")),
        );
      } else {
        _couponController.clear(); // Reset coupon field on valid application
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error applying coupon: $e")),
      );
    } finally {
      setState(() {
        isApplyingCoupon = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double subtotal = 0.0;
    for (var item in cartNotifier.cartItems) {
      subtotal += double.parse(item['price']!);
    }

    double gst = subtotal * (gstRate / 100);
    double discount = subtotal * (discountPercentage / 100);

    double total = subtotal + gst - discount;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Billing",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: cartNotifier.cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartNotifier.cartItems.elementAt(index);
                  return ListTile(
                    title: Text(
                      item['subjectName']!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("Department: ${item['departmentName']}"),
                    trailing: Text(
                      "₹ ${item['price']}",
                      style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 15),
                    ),
                  );
                },
              ),
            ),
            const Divider(thickness: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Subtotal", style: TextStyle(fontSize: 16)),
                Text("₹ ${subtotal.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("GST (${gstRate.toStringAsFixed(1)}%)",
                    style: const TextStyle(fontSize: 16)),
                Text("₹ ${gst.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            if (discount > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Discount (${appliedCoupon.isNotEmpty ? appliedCoupon : "Coupon"})",
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text("- ₹ ${discount.toString()}",
                      style: const TextStyle(fontSize: 16, color: Colors.green)),

                ],
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total",
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (discount > 0)
                      Text(
                        "₹ ${(subtotal + gst).toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 14,
                          decoration: TextDecoration.lineThrough,
                          color: Colors.red,
                        ),
                      ),
                    Text(
                      "₹ ${total.toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    decoration: InputDecoration(
                      hintText: "Enter Coupon Code",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isApplyingCoupon ? null : _applyCoupon,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isApplyingCoupon ? Colors.grey : Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isApplyingCoupon
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    "Apply",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Trigger payment logic
                print("Proceeding to payment with total: ₹ ${total.toStringAsFixed(2)}");
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Center(
                child: Text(
                  "Pay Now",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
