import 'package:asmolg/MainScreeens/NotesPage.dart';
import 'package:asmolg/fileViewer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import HTTP package
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'dart:convert'; // For JSON encoding/decoding

class ContentPreviewPage extends StatefulWidget {
  final String departmentName;
  final String subjectName;
  final String subjectId;
  final String price;

  const ContentPreviewPage({
    Key? key,
    required this.departmentName,
    required this.subjectName,
    required this.subjectId,
    required this.price,
  }) : super(key: key);

  @override
  State<ContentPreviewPage> createState() => _ContentPreviewPageState();
}

class _ContentPreviewPageState extends State<ContentPreviewPage> {
  late Razorpay _razorpay;
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();
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

  Future<List<Map<String, dynamic>>> _fetchPDFFiles() async {
    List<Map<String, dynamic>> pdfFiles = [];
    try {
      QuerySnapshot notesSnapshot = await FirebaseFirestore.instance
          .collection('notes')
          .where('department', isEqualTo: widget.departmentName)
          .get();

      if (notesSnapshot.docs.isNotEmpty) {
        for (var noteDoc in notesSnapshot.docs) {
          // Navigate to the subjects sub-collection
          QuerySnapshot subjectSnapshot = await FirebaseFirestore.instance
              .collection('notes')
              .doc(noteDoc.id)
              .collection('subjects')
              .get();

          for (var subjectDoc in subjectSnapshot.docs) {
            if (subjectDoc.id == widget.subjectId) {
              // Navigate to the content sub-collection
              QuerySnapshot contentSnapshot = await FirebaseFirestore.instance
                  .collection('notes')
                  .doc(noteDoc.id)
                  .collection('subjects')
                  .doc(subjectDoc.id)
                  .collection('content')
                  .get();

              for (var contentDoc in contentSnapshot.docs) {
                pdfFiles.add({
                  'content': contentDoc['content'], // Title of the PDF
                  'fileURL': contentDoc['fileURL'], // URL of the PDF
                  'isPaid': contentDoc['isPaid'], // Boolean flag for payment status
                });
              }
              break;
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching PDFs: $e');
    }

    return pdfFiles;
  }

  Future<void> _openCheckout() async {
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
          builder: (context) => NotesPage(
            departmentDocId: widget.departmentName,
            subjectDocId: widget.subjectId,
            subjectName: widget.subjectName,
          ),
        ),
      );
      return;
    }

    // Fetch order ID from backend before opening checkout
    String orderId = await _fetchOrderId();
    if (orderId.isEmpty) {
      // Handle the case where order ID could not be retrieved
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create order.')),
      );
      return;
    }

    var options = {
      'key': 'rzp_live_ibSut8YutP655P',
      'amount': (double.parse(widget.price) * 100).toInt().toString(),
      'name': widget.subjectName,
      'description': 'Purchase for ${widget.subjectName}',
      'order_id': orderId, // Set order ID here
      'prefill': {
        'contact': '', // Add the user's contact information here
        'email': '', // Add the user's email here
      },
      'theme': {'color': '#F37254'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<String> _fetchOrderId() async {
    try {
      final response = await http.post(
        Uri.parse('https://razorpay-integration-o5dn.onrender.com/create-order'), // Replace with your server URL
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, dynamic>{
          'amount': (double.parse(widget.price) * 100).toInt(), // Price in paise
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['orderId']; // Return the order ID
      } else {
        print('Failed to create order: ${response.body}');
        return '';
      }
    } catch (e) {
      print('Error fetching order ID: $e');
      return '';
    }
  }

  Future<String> _getUserMobileNumber(String Email) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(Email).get();
    return userDoc['MobileNumber'] ?? '0000000000';
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userEmail = user.email ?? '';
      String mobileNo = await _getUserMobileNumber(userEmail);

      // Add `subject_id` in Subscriptions collection
      await FirebaseFirestore.instance.collection('users').doc(userEmail).set({
        'bought_content': FieldValue.arrayUnion([{
          'subject_name': widget.subjectName,
          'subject_id': widget.subjectId,
          'price': widget.price,
          'department_name': widget.departmentName,
          'date': DateTime.now().toIso8601String(),
          'mobile_no': mobileNo,
          'payment_id': response.paymentId,
        }]),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection('Subscriptions').doc(userEmail).set({
        'bought_content': FieldValue.arrayUnion([{
          'subject_name': widget.subjectName,
          'subject_id': widget.subjectId,
          'price': widget.price,
          'department_name': widget.departmentName,
          'date': DateTime.now().toIso8601String(),
          'mobile_no': mobileNo,
          'payment_id': response.paymentId,
        }]),
      }, SetOptions(merge: true));

      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 1,
          channelKey: "basic channel",
          title: "Purchase Successful",
          body: "You have successfully purchased the ${widget.subjectName} subject!",
          notificationLayout: NotificationLayout.Default,
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment Successful! You now have access to topics.')),
      );

      setState(() {
        _isSubscribed = true; // Mark the course as subscribed after successful payment
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => NotesPage(
            departmentDocId: widget.departmentName,
            subjectDocId: widget.subjectId,
            subjectName: widget.subjectName,
          ),
        ),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response.message}')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet Used: ${response.walletName}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.departmentName,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    widget.subjectName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: 360,
                child: ElevatedButton(
                  onPressed: _openCheckout,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Buy for ₹ ${widget.price}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Content',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchPDFFiles(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading PDFs'));
                  }

                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    List<Map<String, dynamic>> pdfFiles = snapshot.data!;

                    return ListView.builder(
                      itemCount: pdfFiles.length,
                      itemBuilder: (context, index) {
                        final pdfFile = pdfFiles[index];
                        return PDFCard(
                          title: pdfFile['content'],
                          fileURL: pdfFile['fileURL'],
                          isPaid: pdfFile['isPaid'],
                        );
                      },
                    );
                  } else {
                    return const Center(child: Text('No PDFs available'));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// PDFCard Widget remains unchanged
class PDFCard extends StatelessWidget {
  final String title;
  final String fileURL;
  final bool isPaid;

  const PDFCard({
    Key? key,
    required this.title,
    required this.fileURL,
    required this.isPaid,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            isPaid ? Icons.lock : Icons.lock_open,
            color: isPaid ? Colors.redAccent : Colors.green,
            size: 40,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: isPaid
                ? null
                : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FileViewerPage(fileUrl: fileURL),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
