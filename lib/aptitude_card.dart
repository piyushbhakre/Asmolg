import 'package:asmolg/AptitudeTopicPage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'Aptitudetopicpage.dart';

class AptitudeCard extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String price;
  final String description;

  const AptitudeCard({
    Key? key,
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.description,
  }) : super(key: key);

  @override
  _AptitudeCardState createState() => _AptitudeCardState();
}

class _AptitudeCardState extends State<AptitudeCard> {
  late Razorpay razorpay;
  bool _isSubscribed = false; // Track subscription status

  @override
  void initState() {
    super.initState();
    razorpay = Razorpay();
    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlePaymentSuccess);
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, handlePaymentError);
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, handleExternalWallet);

    _checkSubscriptionStatus(); // Check if the user is subscribed
  }

  Future<void> _checkSubscriptionStatus() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String userEmail = user.email ?? '';

      // Fetch subscription data for the user
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userEmail).get();

      // Check if the aptitude is in the user's subscriptions
      if (userDoc.exists) {
        List<dynamic> boughtContent = userDoc['bought_content'];
        for (var content in boughtContent) {
          if (content['course_name'] == widget.title) { // Check by aptitude name
            setState(() {
              _isSubscribed = true; // User is subscribed
            });
            break;
          }
        }
      }
    }
  }

  void handlePaymentSuccess(PaymentSuccessResponse response) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userEmail = user.email ?? '';
      String mobileNo = await _getUserMobileNumber(userEmail);

      await FirebaseFirestore.instance.collection('users').doc(userEmail).set({
        'bought_content': FieldValue.arrayUnion([{
          'course_name': widget.title,
          'price': widget.price,
          'date': DateTime.now().toIso8601String(),
          'mobile_no': mobileNo,
          'payment_id': response.paymentId,
        }]),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection('Subscriptions').doc(userEmail).set({
        'bought_content': FieldValue.arrayUnion([{
          'course_name': widget.title,
          'price': widget.price,
          'date': DateTime.now().toIso8601String(),
          'mobile_no': mobileNo,
          'payment_id': response.paymentId,
        }]),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment Successful! You now have access to the aptitude content.')),
      );

      setState(() {
        _isSubscribed = true; // Mark as subscribed
      });
    }
  }

  void handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response.message}')),
    );
  }

  void handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet Used: ${response.walletName}')),
    );
  }

  void openCheckout() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to make a purchase.')),
      );
      return;
    }

    if (_isSubscribed) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AptitudeTopicPage(
            aptitudeName: widget.title,
          ),
        ),
      );
      return;
    }

    if (widget.price == 'Free') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AptitudeTopicPage(
            aptitudeName: widget.title,
          ),
        ),
      );
      return;
    }

    double amountInDollars = double.parse(widget.price);
    int amountInPaise = (amountInDollars * 100).toInt();

    var options = {
      'key': 'rzp_test_OEmhF25x1IT9oO',
      'amount': amountInPaise.toString(),
      'name': widget.title,
      'description': 'Purchase for ${widget.title}',
      'prefill': {
        'contact': await _getUserMobileNumber(user.email ?? ''),
        'Email': user.email,
      },
      'theme': {'color': '#F37254'},
    };

    try {
      razorpay.open(options);
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<String> _getUserMobileNumber(String Email) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(Email).get();
    return userDoc['MobileNumber'] ?? '0000000000';
  }

  @override
  void dispose() {
    razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        openCheckout(); // Open checkout process on tap
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: Colors.grey.shade300, // Outline color
            width: 1.5, // Outline width
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section with rounded corners at the top
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8.0),
                topRight: Radius.circular(8.0),
              ),
              child: Image.asset(
                widget.imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.fill,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  Text(
                    _isSubscribed
                        ? 'Subscribed'
                        : widget.price == 'Free'
                        ? 'Free'
                        : 'Price: ₹ ${widget.price}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isSubscribed || widget.price == 'Free'
                          ? Colors.green
                          : Colors.blueGrey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
