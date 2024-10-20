import 'package:asmolg/MainScreeens/NotesPage.dart';
import 'package:asmolg/fileViewer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

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
  bool _isSubscribed = false; // To track if the user is subscribed

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
    _razorpay.clear(); // Disposes the Razorpay instance when page is destroyed
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

  void _openCheckout() async {

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
            departmentDocId: widget.departmentName, // Pass departmentDocId
            subjectDocId: widget.subjectId,       // Pass subjectDocId
            subjectName: widget.subjectName,       // Pass subjectDocId
          ),
        ),
      );
      return;
    }

    var options = {
      'key': 'rzp_test_jA4MkCdY9LRH4j',
      //rzp_live_ibSut8YutP655P
      'amount': (double.parse(widget.price) * 100).toInt().toString(),
      'name': widget.subjectName,
      'description': 'Purchase for ${widget.subjectName}',
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
          'subject_id': widget.subjectId,  // Include the subject ID
          'price': widget.price,
          'department_name': widget.departmentName,
          'date': DateTime.now().toIso8601String(),
          'mobile_no': mobileNo,
          'payment_id': response.paymentId,
        }]),
      }, SetOptions(merge: true));

      // Step 2: Add subscription to the `Subscriptions` collection
      await FirebaseFirestore.instance.collection('Subscriptions').doc(userEmail).set({
        'bought_content': FieldValue.arrayUnion([{
          'subject_name': widget.subjectName,
          'subject_id': widget.subjectId,  // Include the subject ID
          'price': widget.price,
          'department_name': widget.departmentName,
          'date': DateTime.now().toIso8601String(),
          'mobile_no': mobileNo,
          'payment_id': response.paymentId,
        }]),
      }, SetOptions(merge: true));

      // Show a local notification for the successful purchase
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 1, // Unique notification ID
          channelKey: "basic channel", // Channel ID from initialization
          title: "Purchase Successful",
          body: "You have successfully purchased the ${widget.subjectName} subject!",
          notificationLayout: NotificationLayout.Default, // Standard notification layout
        ),
      );

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment Successful! You now have access to topics.')),
      );

      setState(() {
        _isSubscribed = true; // Mark the course as subscribed after successful payment
      });

      // Navigate to the TopicsPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => NotesPage(
            departmentDocId: widget.departmentName, // Pass departmentDocId
            subjectDocId: widget.subjectId,       // Pass subjectDocId
            subjectName: widget.subjectName,       // Pass subjectDocId
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
          widget.departmentName, // Department Name as Title
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject Name instead of total income
            Container(
              width: double.infinity, // Set to take full width of parent
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    widget.subjectName, // Subject Name
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
            // Button with price and Buy tag
            Center(
              child: SizedBox(
                width: 360, // Set fixed width
                child: ElevatedButton(
                  onPressed: _openCheckout, // Trigger payment on button press
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Buy for ₹ ${widget.price}', // Buy tag with price
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
              'Content', // Replaced "My companies" with "Content"
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Fetch and display list of PDFs or content
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchPDFFiles(), // Fetch PDF files from Firestore
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator()); // Show loader while waiting for data
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

// Widget for displaying individual PDF content with lock/unlock logic
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
            isPaid ? Icons.lock : Icons.lock_open, // Show lock icon based on isPaid
            color: isPaid ? Colors.redAccent : Colors.green,
            size: 40,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title, // PDF title
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: isPaid
                ? null // Disable click if content is paid
                : () {
              // Open the PDF viewer page
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