import 'dart:convert';
import 'package:asmolg/MainScreeens/NotesPage.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:http/http.dart' as http;
import 'package:asmolg/Constant/ApiConstant.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shimmer/shimmer.dart';

class OneSubBillingPage extends StatefulWidget {
  const OneSubBillingPage({
    Key? key,
    required this.items,
  }) : super(key: key);

  final List<Map<String, String>> items;


  @override
  _OneSubBillingPageState createState() => _OneSubBillingPageState();
}

class _OneSubBillingPageState extends State<OneSubBillingPage> {
  late Map<String, String> subject;

    final TextEditingController _couponController = TextEditingController();
  double discountPercentage = 0.0;
  double subtotal = 0.0;
  String appliedCoupon = "";
  bool isApplyingCoupon = false;
  double? gstRate;
  bool isLoadingGST = true;

  late Razorpay _razorpay;
  bool _isProcessingPayment = false;

  @override
  void initState() {
    // Initialize 'subject' after widget is fully constructed
    subject = widget.items.isNotEmpty ? widget.items[0] : {};
    super.initState();
    _fetchGST();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _fetchGST() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Miscellaneous')
          .doc('GST')
          .get();

      if (doc.exists) {
        setState(() {
          gstRate = doc.data()?['gst'].toDouble() ?? 0.00;
          isLoadingGST = false;
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
      setState(() {
        isLoadingGST = false;
      });
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
        _couponController.clear();
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

  Future<String> _fetchOrderId(double total) async {
    try {
      final response = await http.post(
        Uri.parse(BASE_URL + CREATE_ORDER_ID),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': (total * 100).toInt()}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['id'] ?? '';
      } else {
        return '';
      }
    } catch (e) {
      return '';
    }
  }

  Future<void> _openCheckout(double total) async {
    setState(() {
      _isProcessingPayment = true;
    });

    final orderId = await _fetchOrderId(total);
    if (orderId.isEmpty) {
      setState(() {
        _isProcessingPayment = false;
      });
      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;
    final String email = user?.email ?? '';
    final String phone = '1234567890'; // Replace with actual logic to fetch user phone

    var options = {
      'key': 'rzp_live_ibSut8YutP655P',
      'amount': (total * 100).toInt(),
      'order_id': orderId,
      'prefill': {'email': email, 'contact': phone},
      'theme': {'color': '#F37254'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      setState(() {
        _isProcessingPayment = false;
      });
    }
  }



  Future<String> _getUserMobileNumber(String email) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection(
        'users').doc(email).get();
    return userDoc['MobileNumber'] ?? '0000000000';
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {

    String sub = subtotal.toString();

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String email = user.email ?? '';
      String mobile = await _getUserMobileNumber(email);

    await FirebaseFirestore.instance.collection('users').doc(email).set({
      'bought_content': FieldValue.arrayUnion(widget.items.map((item) {
        return {
          'subjectName': item['subjectName'],
          'department_name': item['departmentName'],
          'price': item['price'],
          'subject_id': item['subjectId'],
          'mobile_no': mobile,
          'price': sub,
          'date': DateTime.now().toIso8601String(),
          'paymentId': response.paymentId,
        };
      }).toList())
    }, SetOptions(merge: true));

    await FirebaseFirestore.instance.collection('Subscriptions').doc(
        email).set({
      'bought_content': FieldValue.arrayUnion(widget.items.map((item) {
        return {
          'subjectName': item['subjectName'],
          'price': item['price'],
          'department_name': item['departmentName'],
          'subject_id': item['subjectId'],
          'mobile_no': mobile,
          'price': sub,
          'date': DateTime.now().toIso8601String(),
          'paymentId': response.paymentId,
        };
      }).toList())
    }, SetOptions(merge: true));

    setState(() {
      _isProcessingPayment = false;
    });

    CherryToast.success(
      title: const Text('Success'),
      displayIcon: true,
      description: const Text(
          'Payment Successful! You now have access to topics.'),
      animationDuration: const Duration(milliseconds: 500),
    ).show(context);

    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              NotesPage(
                departmentDocId: "${subject['departmentName']}",
                subjectDocId: "${subject['subjectId']}",
                subjectName: "${subject['subjectName']}",
              ),
        ),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      _isProcessingPayment = false;
    });
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  @override
  Widget build(BuildContext context) {
    //double subtotal = widget.items.fold(0.0, (sum, item) => sum + double.parse(item['price']!));
    double subtotal = widget.items.fold(0.0, (sum, item) => sum + 1.00);
    double gst = (gstRate ?? 0.00) * subtotal / 100;
    double discount = subtotal * (discountPercentage / 100);
    double total = subtotal + gst - discount;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Billing", style: TextStyle(color: Colors.black)),
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
                itemCount: widget.items.length,
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Subject: ${item['subjectName']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text("Department: ${item['departmentName']}"),
                          const SizedBox(height: 4),
                          Text("Subject ID: ${item['subjectId']}", style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text("Price: ₹ ${item['price']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(thickness: 1),
            isLoadingGST
                ? _shimmerLoadingPlaceholder()
                : _buildSubtotalRow("Subtotal", subtotal),
            isLoadingGST
                ? _shimmerLoadingPlaceholder()
                : _buildSubtotalRow("GST (${gstRate?.toStringAsFixed(1) ?? "0"}%)", gst),
            if (discount > 0)
              _buildSubtotalRow("Discount (${appliedCoupon.isNotEmpty ? appliedCoupon : "Coupon"})", -discount, isDiscount: true),
            const SizedBox(height: 16),
            isLoadingGST ? _shimmerLoadingPlaceholder() : _buildTotalRow("Total", total),
            const SizedBox(height: 16),
            _buildCouponRow(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isProcessingPayment ? null : () => _openCheckout(total),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isProcessingPayment
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Pay Now", style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerLoadingPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 20,
        color: Colors.grey[300],
        margin: const EdgeInsets.symmetric(vertical: 4),
      ),
    );
  }

  Widget _buildSubtotalRow(String title, double value, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16)),
        Text(
          (isDiscount ? "- " : "") + "₹ ${value.toStringAsFixed(2)}",
          style: TextStyle(fontSize: 16, color: isDiscount ? Colors.green : Colors.black),
        ),
      ],
    );
  }

  Widget _buildTotalRow(String title, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text("₹ ${value.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCouponRow() {
    return Row(
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
              : const Text("Apply", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
