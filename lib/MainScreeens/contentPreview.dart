import 'package:asmolg/MainScreeens/NotesPage.dart';
import 'package:asmolg/MainScreeens/oneSubBillingpage.dart';
import 'package:asmolg/fileViewer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cherry_toast/cherry_toast.dart'; // CherryToast for notifications
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../StateManager/CartState.dart';
import 'CartPage.dart';

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
  final User? user = FirebaseAuth.instance.currentUser; // Fetch current logged-in user
  String phone = ''; // Placeholder for phone number

  late Razorpay _razorpay;
  bool _isLoading = false; // Track loading state

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
          QuerySnapshot subjectSnapshot = await FirebaseFirestore.instance
              .collection('notes')
              .doc(noteDoc.id)
              .collection('subjects')
              .get();

          for (var subjectDoc in subjectSnapshot.docs) {
            if (subjectDoc.id == widget.subjectId) {
              QuerySnapshot contentSnapshot = await FirebaseFirestore.instance
                  .collection('notes')
                  .doc(noteDoc.id)
                  .collection('subjects')
                  .doc(subjectDoc.id)
                  .collection('content')
                  .get();

              for (var contentDoc in contentSnapshot.docs) {
                pdfFiles.add({
                  'content': contentDoc['content'],
                  'fileURL': contentDoc['fileURL'],
                  'isPaid': contentDoc['isPaid'],
                });
              }
              break;
            }
          }
        }
      }
    } catch (e) {
      CherryToast.error(
        title: const Text('Error'),
        displayIcon: true,
        description: Text('Error fetching PDFs: $e'),
        animationDuration: const Duration(milliseconds: 500),
      ).show(context);
    }
    return pdfFiles;
  }

  Future<void> fetchUserDetails() async {
    if (user != null) {
      try {
        // Fetch user details (Phone and Full Name)
        final DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.email)
            .get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            phone = data['MobileNumber'] ?? 'No phone number';
          });
        } else {
          setState(() {
            phone = 'No phone number';
          });
        }
      } catch (e) {
        print("Error fetching user details: $e");
        setState(() {
          phone = 'Error fetching phone number';
        });
      }
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() {
      _isLoading = false; // Hide loading overlay
    });
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userEmail = user.email ?? '';
      String mobileNo = await _getUserMobileNumber(userEmail);

      await FirebaseFirestore.instance.collection('users').doc(userEmail).set({
        'bought_content': FieldValue.arrayUnion([{
          'subject_name': widget.subjectName,
          'subject_id': widget.subjectId,
          'price': widget.price,
          'department_name': widget.departmentName,
          'date': DateTime.now().toIso8601String(),
          'mobile_no': mobileNo,
          'payment_id': response.paymentId,
        }
        ]),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection('Subscriptions').doc(
          userEmail).set({
        'bought_content': FieldValue.arrayUnion([{
          'subject_name': widget.subjectName,
          'subject_id': widget.subjectId,
          'price': widget.price,
          'department_name': widget.departmentName,
          'date': DateTime.now().toIso8601String(),
          'mobile_no': mobileNo,
          'payment_id': response.paymentId,
        }
        ]),
      }, SetOptions(merge: true));

      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 1,
          channelKey: "basic channel",
          title: "Purchase Successful",
          body: "You have successfully purchased the ${widget
              .subjectName} subject!",
          notificationLayout: NotificationLayout.Default,
        ),
      );

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
                departmentDocId: widget.departmentName,
                subjectDocId: widget.subjectId,
                subjectName: widget.subjectName,
              ),
        ),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      _isLoading = false;
    });
    CherryToast.error(
      title: const Text('Payment Failed'),
      displayIcon: true,
      description: Text('Payment Failed: ${response.message}'),
      animationDuration: const Duration(milliseconds: 500),
    ).show(context);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    CherryToast.info(
      title: const Text('External Wallet Used'),
      displayIcon: true,
      description: Text('External Wallet Used: ${response.walletName}'),
      animationDuration: const Duration(milliseconds: 500),
    ).show(context);
  }

  Future<String> _getUserMobileNumber(String email) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection(
        'users').doc(email).get();
    return userDoc['MobileNumber'] ?? '0000000000';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.departmentName,
                    style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis,
                        fontSize: 18
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CartPage()),
                    );
                  },
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      const Icon(Icons.shopping_cart, color: Colors.black),
                      ValueListenableBuilder<int>(
                        valueListenable: cartNotifier,
                        builder: (context, cartCount, child) {
                          return cartCount > 0
                              ? Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red,
                            ),
                            child: Text(
                              '$cartCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                              : const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ],
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 170,
                        child: ElevatedButton(
                          onPressed: () {
                            // Pass the current subject details, including subjectId
                            final singleSubject = [
                              {
                                'subjectName': widget.subjectName,
                                'departmentName': widget.departmentName,
                                'price': widget.price,
                                'subjectId': widget.subjectId
                              }
                            ];

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OneSubBillingPage( // Corrected class name
                                  items: singleSubject,
                                ),
                              ),
                            );
                          },
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

                      const SizedBox(width: 10),
                      SizedBox(
                        width: 170,
                        child: ValueListenableBuilder<int>(
                          valueListenable: cartNotifier,
                          builder: (context, cartCount, child) {
                            final isAdded = cartNotifier.isAdded(widget.subjectName);
                            return ElevatedButton(
                              onPressed: () {
                                if (!isAdded) {
                                  cartNotifier.addItem(
                                    widget.subjectName,
                                    widget.departmentName,
                                    widget.price,
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: isAdded ? Colors.green : Colors.orange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.shopping_cart, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    isAdded ? 'Added' : 'Add to Cart',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
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
                        CherryToast.error(
                          title: const Text('Error'),
                          displayIcon: true,
                          description: const Text('Error loading PDFs'),
                          animationDuration: const Duration(milliseconds: 500),
                        ).show(context);
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
        ),
        // Loading Overlay
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LoadingAnimationWidget.staggeredDotsWave(
                      color: Colors.white,
                      size: 50,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Loading, please wait 🕒. \nThis may take more than a minute ⏳.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
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