import 'package:asmolg/MainScreeens/NotesPage.dart';
import 'package:asmolg/MainScreeens/contentPreview.dart';
import 'package:asmolg/MainScreeens/homepage.dart';
import 'package:asmolg/Provider/NotificationController.dart';
import 'package:asmolg/Provider/offline-online_status.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';
import 'MainScreeens/CartPage.dart';
import 'Provider/CartState.dart';

class SubjectPage extends StatefulWidget {
  final String departmentName;

  const SubjectPage({Key? key, required this.departmentName}) : super(key: key);

  @override
  _SubjectPageState createState() => _SubjectPageState();
}

class _SubjectPageState extends State<SubjectPage> {
  String _searchTerm = ''; // Holds the search term entered by the user
  // Add state for sorting
  String _selectedSort = ''; // To track the selected sorting option
  List<Map<String, dynamic>> _subjects = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Query Firestore to get the subjects subcollection where department matches
    CollectionReference notesCollection =
        FirebaseFirestore.instance.collection('notes');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        bottom: OfflineBanner(),
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
                    fontSize: 18),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // PushReplacement to navigate to Subject() screen and replace the current screen
            Get.offAll(() => HomeScreen());
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search Subjects...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchTerm = value.toLowerCase(); // Update search term
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Filter Icon Dropdown
              PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list, color: Colors.black),
                onSelected: (value) {
                  setState(() {
                    _selectedSort = value;
                    _subjects.sort((a, b) {
                      double priceA =
                          double.tryParse(a['price'].toString()) ?? 0;
                      double priceB =
                          double.tryParse(b['price'].toString()) ?? 0;
                      return _selectedSort == 'Low to High'
                          ? priceA.compareTo(priceB)
                          : priceB.compareTo(priceA);
                    });
                  });
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'Low to High',
                    child: Row(
                      children: [
                        Text('Price: Low to High'),
                        const Spacer(),
                        if (_selectedSort == 'Low to High')
                          const Icon(Icons.check, color: Colors.green),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'High to Low',
                    child: Row(
                      children: [
                        Text('Price: High to Low'),
                        const Spacer(),
                        if (_selectedSort == 'High to Low')
                          const Icon(Icons.check, color: Colors.green),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // FutureBuilder to fetch the subjects
          Expanded(
            child: FutureBuilder<QuerySnapshot>(
              future: notesCollection
                  .where('department', isEqualTo: widget.departmentName)
                  .get(),
              builder: (context, departmentSnapshot) {
                if (departmentSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return _buildShimmerList(); // Show shimmer when department data is loading
                }

                if (departmentSnapshot.hasError) {
                  return Center(
                      child: Text('Error: ${departmentSnapshot.error}'));
                }

                if (departmentSnapshot.hasData &&
                    departmentSnapshot.data != null) {
                  var departmentDoc = departmentSnapshot.data!.docs.first;

                  CollectionReference subjectsRef = notesCollection
                      .doc(departmentDoc.id)
                      .collection('subjects');

                  return FutureBuilder<QuerySnapshot>(
                    future: subjectsRef.get(),
                    builder: (context, subjectsSnapshot) {
                      if (subjectsSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return _buildShimmerList(); // Show shimmer when subjects data is loading
                      }

                      if (subjectsSnapshot.hasError) {
                        return Center(
                            child: Text('Error: ${subjectsSnapshot.error}'));
                      }

                      if (subjectsSnapshot.hasData &&
                          subjectsSnapshot.data != null) {
                        _subjects = subjectsSnapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return {
                            'name': data['subject'] ?? 'Unknown Subject',
                            'professorName': data['name'] ?? 'Team Asmolg',
                            'price': data['price'] ?? 'Free',
                            'subjectId': doc.id,
                          };
                        }).where((subject) {
                          return subject['name']!
                              .toLowerCase()
                              .contains(_searchTerm);
                        }).toList();

                        // Check subscription status and move subscribed subjects to the top
                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser?.email)
                              .get(),
                          builder: (context, userSnapshot) {
                            if (userSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return _buildShimmerList(); // Show shimmer when user subscription data is loading
                            }

                            if (userSnapshot.hasError) {
                              return Center(
                                  child: Text('Error: ${userSnapshot.error}'));
                            }

                            if (userSnapshot.hasData &&
                                userSnapshot.data != null) {
                              List<dynamic> subscribedSubjects =
                                  userSnapshot.data!['bought_content'] ?? [];

                              _subjects.sort((a, b) {
                                bool isSubscribedA = subscribedSubjects.any(
                                    (content) =>
                                        content['subject_id'] ==
                                        a['subjectId']);
                                bool isSubscribedB = subscribedSubjects.any(
                                    (content) =>
                                        content['subject_id'] ==
                                        b['subjectId']);

                                // Subscribed subjects come first
                                if (isSubscribedA && !isSubscribedB) return -1;
                                if (!isSubscribedA && isSubscribedB) return 1;

                                // Apply price sorting if applicable
                                if (_selectedSort.isNotEmpty) {
                                  double priceA =
                                      double.tryParse(a['price'].toString()) ??
                                          0;
                                  double priceB =
                                      double.tryParse(b['price'].toString()) ??
                                          0;
                                  return _selectedSort == 'Low to High'
                                      ? priceA.compareTo(priceB)
                                      : priceB.compareTo(priceA);
                                }

                                return 0; // Otherwise, maintain original order
                              });

                              if (_subjects.isEmpty) {
                                return const Center(
                                    child: Text(
                                        'No subjects found for this department.'));
                              }

                              return ListView.builder(
                                itemCount: _subjects.length,
                                itemBuilder: (context, index) {
                                  final subject = _subjects[index];
                                  return ModernSubjectCard(
                                    subjectName: subject['name']!,
                                    professorName: subject['professorName']!,
                                    price: subject['price']!,
                                    departmentId: widget.departmentName,
                                    subjectId: subject['subjectId']!,
                                  );
                                },
                              );
                            }

                            return const Center(
                                child: Text(
                                    'Unable to fetch user subscription details.'));
                          },
                        );
                      }

                      return const Center(
                          child:
                              Text('No subjects found for this department.'));
                    },
                  );
                }

                return const Center(child: Text('Department not found.'));
              },
            ),
          )
        ]),
      ),
    );
  }
}

// Shimmer Placeholder
Widget _buildShimmerList() {
  return ListView.builder(
    itemCount: 8, // Number of shimmer placeholders
    itemBuilder: (context, index) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            height: 90,
            width: 110,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
      );
    },
  );
}

class ModernSubjectCard extends StatefulWidget {
  final String subjectName;
  final String professorName;
  final String price; // Original price
  final String departmentId;
  final String subjectId;

  const ModernSubjectCard({
    Key? key,
    required this.subjectName,
    required this.professorName,
    required this.price,
    required this.departmentId,
    required this.subjectId,
  }) : super(key: key);

  @override
  _ModernSubjectCardState createState() => _ModernSubjectCardState();
}

class _ModernSubjectCardState extends State<ModernSubjectCard> {
  late Razorpay razorpay;
  bool _isSubscribed = false; // Tracks if the user is subscribed
  String? _offerPrice; // Holds the real-time fetched offer price
  String? _offerTagline; // Holds the real-time fetched tagline

  @override
  void initState() {
    super.initState();
    AwesomeNotifications().setListeners(
        onActionReceivedMethod: NotificationController.onActionReceivedMethod,
        onNotificationCreatedMethod:
            NotificationController.onNotificationCreatedMethod,
        onNotificationDisplayedMethod:
            NotificationController.onNotificationDisplayedMethod,
        onDismissActionReceivedMethod:
            NotificationController.onDismissActionReceivedMethod);

    razorpay = Razorpay();
    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlePaymentSuccess);
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, handlePaymentError);
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, handleExternalWallet);

    _checkSubscriptionStatus(); // Check subscription status
  }

  Future<void> _checkSubscriptionStatus() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String userEmail = user.email ?? '';

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .get();

      if (userDoc.exists) {
        List<dynamic> boughtContent = userDoc['bought_content'];
        for (var content in boughtContent) {
          if (content['subject_id'] == widget.subjectId) {
            setState(() {
              _isSubscribed = true;
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

      String priceToStore =
          _offerPrice ?? widget.price; // Use offer price if available

      // Store subscription data
      await FirebaseFirestore.instance.collection('users').doc(userEmail).set({
        'bought_content': FieldValue.arrayUnion([
          {
            'subject_name': widget.subjectName,
            'subject_id': widget.subjectId,
            'price': priceToStore,
            'department_name': widget.departmentId,
            'date': DateTime.now().toIso8601String(),
            'mobile_no': mobileNo,
            'payment_id': response.paymentId,
          }
        ]),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment Successful!')),
      );

      setState(() {
        _isSubscribed = true;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => NotesPage(
            departmentDocId: widget.departmentId,
            subjectDocId: widget.subjectId,
            subjectName: widget.subjectName,
          ),
        ),
      );
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

  Future<String> _getUserMobileNumber(String email) async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(email).get();
    return userDoc['MobileNumber'] ?? '0000000000';
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
          builder: (context) => NotesPage(
            departmentDocId: widget.departmentId,
            subjectDocId: widget.subjectId,
            subjectName: widget.subjectName,
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContentPreviewPage(
          departmentName: widget.departmentId,
          subjectName: widget.subjectName,
          subjectId: widget.subjectId,
          price: _offerPrice ?? widget.price, // Pass offer price if available
        ),
      ),
    );
  }

  @override
  void dispose() {
    razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Miscellaneous')
          .doc('offer 1')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          _offerPrice =
              data['price']?.toString(); // Update the offer price in real-time
          _offerTagline = data['tagline']?.toString();
        } else {
          _offerPrice = null; // Reset if the document is deleted
          _offerTagline = null;
        }

        // Subscribed subjects displayed first
        return GestureDetector(
          onTap: () {
            if (!_isSubscribed) {
              openCheckout(); // Only open checkout if not subscribed
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotesPage(
                    departmentDocId: widget.departmentId,
                    subjectDocId: widget.subjectId,
                    subjectName: widget.subjectName,
                  ),
                ),
              );
            }
          },
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white, // Removed the green background tint
                        border: Border(
                          bottom: BorderSide(
                              color: Colors.black,
                              width: 1), // Divider line
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16.0, horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Subject Name
                            Row(
                              children: [
                                const FaIcon(
                                  FontAwesomeIcons.bookOpen,
                                  color: Colors.black,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.subjectName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Professor Name
                            Row(
                              children: [
                                const FaIcon(
                                  FontAwesomeIcons.userTie,
                                  color: Colors.black,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.professorName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Price Row
                            if (!_isSubscribed) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      if (_offerPrice != null)
                                        Row(
                                          children: [
                                            Text(
                                              "₹${widget.price}",
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey,
                                                decoration:
                                                TextDecoration.lineThrough,
                                              ),
                                            ),
                                          ],
                                        ),
                                      if (_offerPrice != null)
                                        const SizedBox(width: 10),
                                      Row(
                                        children: [
                                          const FaIcon(
                                            FontAwesomeIcons.moneyBill,
                                            color: Colors.black,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _offerPrice != null
                                                ? "₹$_offerPrice"
                                                : "₹${widget.price}",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (_offerTagline != null)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: Colors.orange,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const FaIcon(
                                                FontAwesomeIcons.tags,
                                                color: Colors.white,
                                                size: 12,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                _offerTagline!,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                            if (_isSubscribed) ...[
                              // No need for Positioned here
                            ],
                          ],
                        ),
                      ),
                    ),
                    // Move Positioned here, directly inside Stack
                    if (_isSubscribed) Positioned(
                      top: 0.5,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Subscribed",
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )

        );
      },
    );
  }
}
