import 'dart:convert';
import 'dart:ui';
import 'package:asmolg/MainScreeens/homepage.dart';
import 'package:asmolg/Provider/CartState.dart';
import 'package:asmolg/Provider/offline-online_status.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:cherry_toast/resources/arrays.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:asmolg/Constant/ApiConstant.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
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
        Fluttertoast.showToast(
          msg: "Failed to fetch GST rate.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error fetching GST: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      setState(() {
        isLoadingGST = false;
      });
    }
  }

  Future<void> _applyCoupon() async {
    final enteredCode = _couponController.text.trim();
    if (enteredCode.isEmpty) {
      CherryToast.info(
        title: const Text("Info"),
        description: const Text("Please enter a coupon code."),
        toastPosition: Position.top,
        animationType: AnimationType.fromTop,
        autoDismiss: true,
      ).show(context);
      return;
    }

    setState(() {
      isApplyingCoupon = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance.collection('Miscellaneous').get();
      bool isValidCoupon = false;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['code'] == enteredCode) {
          setState(() {
            discountPercentage = data['discount'].toDouble();
            appliedCoupon = enteredCode;
          });
          isValidCoupon = true;

          CherryToast.success(
            title: const Text("Success"),
            description: Text("Coupon applied! ${discountPercentage.toStringAsFixed(0)}% off."),
            toastPosition: Position.top,
            animationType: AnimationType.fromTop,
            autoDismiss: true,
          ).show(context);
          break;
        }
      }

      if (!isValidCoupon) {
        setState(() {
          discountPercentage = 0.0;
          appliedCoupon = "";
        });

        CherryToast.error(
          title: const Text("Invalid Coupon"),
          description: const Text("Invalid coupon code."),
          toastPosition: Position.top,
          animationType: AnimationType.fromTop,
          autoDismiss: true,
        ).show(context);
      } else {
        _couponController.clear();
      }
    } catch (e) {
      CherryToast.error(
        title: const Text("Error"),
        description: Text("Error applying coupon: $e"),
        toastPosition: Position.top,
        animationType: AnimationType.fromTop,
        autoDismiss: true,
      ).show(context);
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

    try {
      // Fetch the order ID from the backend or Razorpay API
      final orderId = await _fetchOrderId(total);

      if (orderId.isEmpty) {
        setState(() {
          _isProcessingPayment = false;
        });

        CherryToast.error(
          title: const Text("Payment Initialization Failed"),
          description: const Text("Unable to fetch order ID. Please try again later."),
          animationType: AnimationType.fromTop,
          toastPosition: Position.top,
          autoDismiss: true,
        ).show(context);
        return;
      }

      // Fetch user details
      final User? user = FirebaseAuth.instance.currentUser;
      final String email = user?.email ?? '';
      final String phone = '1234567890'; // Replace with actual logic to fetch user phone

      // Razorpay options
      var options = {
        'key': RAZOR_PAY_LIVE_KEY,
        'amount': (total * 100).toInt(),
        'order_id': orderId,
        'prefill': {'email': email, 'contact': phone},
        'theme': {'color': '#F37254'},
      };

      _razorpay.open(options);
    } catch (e) {
      setState(() {
        _isProcessingPayment = false;
      });

      // Show CherryToast for unexpected errors
      CherryToast.error(
        title: const Text("Payment Error"),
        description: Text("An unexpected error occurred Please check the internet"),
        animationType: AnimationType.fromTop,
        toastPosition: Position.top,
        autoDismiss: true,
      ).show(context);
    }
  }

  Future<String> _getUserMobileNumber(String email) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection(
        'users').doc(email).get();
    return userDoc['MobileNumber'] ?? '0000000000';
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Calculate the total amount paid
    double subtotal = widget.items.fold(0.0, (sum, item) => sum + double.parse(item['price']!));
    double gst = (gstRate ?? 0.00) * subtotal / 100;
    double discount = subtotal * (discountPercentage / 100);
    double total = subtotal + gst - discount;

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String email = user.email ?? '';
      String mobile = await _getUserMobileNumber(email);

      await FirebaseFirestore.instance.collection('users').doc(email).set({
        'bought_content': FieldValue.arrayUnion(widget.items.map((item) {
          return {
            'subjectName': item['subjectName'],
            'department_name': item['departmentName'],
            'price': item['price'],  // Original subject price
            'total_paid': total.toStringAsFixed(2),  // Total amount paid including GST and discounts
            'subject_id': item['subjectId'],
            'mobile_no': mobile,
            'date': DateTime.now().toIso8601String(),
            'paymentId': response.paymentId,
          };
        }).toList())
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection('Subscriptions').doc(email).set({
        'bought_content': FieldValue.arrayUnion(widget.items.map((item) {
          return {
            'subjectName': item['subjectName'],
            'department_name': item['departmentName'],
            'price': item['price'],  // Original subject price
            'total_paid': total.toStringAsFixed(2),  // Total amount paid including GST and discounts
            'subject_id': item['subjectId'],
            'mobile_no': mobile,
            'date': DateTime.now().toIso8601String(),
            'paymentId': response.paymentId,
          };
        }).toList())
      }, SetOptions(merge: true));

      // Remove purchased items from the cart notifier
      for (var item in widget.items) {
        if (item.containsKey('subjectId')) {
          cartNotifier.removeItemById(item['subjectId']!);
        }
      }

      setState(() {
        _isProcessingPayment = false;
      });

      String subjectNames = widget.items.map((item) => item['subjectName']).join(', ');

      CherryToast.success(
        title: const Text('Success'),
        displayIcon: true,
        description: Text('\n Payment Successful! $subjectNames'),
        animationDuration: const Duration(milliseconds: 500),
      ).show(context);

      Get.offAll(() => HomeScreen());
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      _isProcessingPayment = false;
    });


    // Show CherryToast for payment error
    CherryToast.error(
      title: const Text("Payment Failed"),
      description: Text(
        response.message ?? "An unknown error occurred during the payment.",
      ),
      animationType: AnimationType.fromTop,
      toastPosition: Position.top,
      autoDismiss: true,
    ).show(context);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Log for debugging
    print("External Wallet Selected: ${response.walletName}");

    // Show CherryToast for external wallet selection
    CherryToast.info(
      title: const Text("External Wallet"),
      description: Text("You selected: ${response.walletName}"),
      animationType: AnimationType.fromTop,
      toastPosition: Position.top,
      autoDismiss: true,
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    double subtotal = widget.items.fold(0.0, (sum, item) => sum + double.parse(item['price']!));
    double gst = (gstRate ?? 0.00) * subtotal / 100;
    double discount = subtotal * (discountPercentage / 100);
    double total = subtotal + gst - discount;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                AppBar(
                  title: const Text("Billing", style: TextStyle(color: Colors.white)),
                  backgroundColor: Colors.black,
                  iconTheme: const IconThemeData(color: Colors.white),
                  elevation: 1,
                ),
                OfflineBanner(),
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              itemCount: widget.items.length,
                              itemBuilder: (context, index) {
                                final item = widget.items[index];
                                return Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16.0),
                                      color: Colors.white,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${item['subjectName']}",
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            "Department: ${item['departmentName']}",
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Price: ₹ ${item['price']}",
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Divider(
                                      height: 1,
                                      color: Colors.grey.shade300,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const Divider(thickness: 1, color: Colors.black),
                          isLoadingGST
                              ? _shimmerLoadingPlaceholder()
                              : _buildSubtotalRow(
                            "Subtotal", subtotal,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          isLoadingGST
                              ? _shimmerLoadingPlaceholder()
                              : _buildSubtotalRow(
                            "GST (${gstRate?.toStringAsFixed(1) ?? "0"}%)", gst,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              color: Colors.black54,
                            ),
                          ),
                          if (discount > 0)
                            _buildSubtotalRow(
                              "Discount (${appliedCoupon.isNotEmpty ? appliedCoupon : "Coupon"})",
                              -discount,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                                color: Colors.green,
                              ),
                            ),
                          const SizedBox(height: 16),
                          isLoadingGST
                              ? _shimmerLoadingPlaceholder()
                              : _buildTotalRow(
                            "Total", total,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildCouponRow(
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: Colors.blueAccent,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _openCheckout(total),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                "Pay Now",
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isProcessingPayment)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LoadingAnimationWidget.staggeredDotsWave(
                              color: Colors.black,
                              size: 50,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Ready for payment...",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
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

  Widget _buildSubtotalRow(String title, double value, {bool isDiscount = false, required TextStyle style}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: style),
        Text(
          (isDiscount ? "- " : "") + "₹ ${value.toStringAsFixed(2)}",
          style: TextStyle(
            fontSize: 16,
            color: isDiscount ? Colors.green : Colors.black,  // Ensure discount text is green
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(String title, double value, {required TextStyle style}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text("₹ ${value.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCouponRow({required TextStyle style}) {
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
