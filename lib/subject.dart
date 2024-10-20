import 'package:asmolg/MainScreeens/NotesPage.dart';
import 'package:asmolg/MainScreeens/contentPreview.dart';
import 'package:asmolg/NotificationController.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubjectPage extends StatefulWidget {
  final String departmentName;

  const SubjectPage({Key? key, required this.departmentName}) : super(key: key);

  @override
  _SubjectPageState createState() => _SubjectPageState();
}

class _SubjectPageState extends State<SubjectPage> {
  String _searchTerm = ''; // Holds the search term entered by the user
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Query Firestore to get the subjects subcollection where department matches
    CollectionReference notesCollection = FirebaseFirestore.instance.collection('notes');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('${widget.departmentName}'),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar TextField
            TextField(
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
            const SizedBox(height: 16),

            // FutureBuilder to fetch the subjects
            Expanded(
              child: FutureBuilder<QuerySnapshot>(
                // Fetch the department document first, then get the subjects subcollection
                future: notesCollection.where('department', isEqualTo: widget.departmentName).get(),
                builder: (context, departmentSnapshot) {
                  // Show a loading indicator while waiting for the data
                  if (departmentSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Handle errors
                  if (departmentSnapshot.hasError) {
                    return Center(child: Text('Error: ${departmentSnapshot.error}'));
                  }

                  // If the department document is found, query the subjects subcollection
                  if (departmentSnapshot.hasData && departmentSnapshot.data != null) {
                    var departmentDoc = departmentSnapshot.data!.docs.first;

                    CollectionReference subjectsRef = notesCollection
                        .doc(departmentDoc.id)
                        .collection('subjects'); // Reference to subjects subcollection

                    return FutureBuilder<QuerySnapshot>(
                      future: subjectsRef.get(),
                      builder: (context, subjectsSnapshot) {
                        // Show a loading indicator while waiting for the data
                        if (subjectsSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        // Handle errors
                        if (subjectsSnapshot.hasError) {
                          return Center(child: Text('Error: ${subjectsSnapshot.error}'));
                        }

                        // If data is available, display the list of subjects
                        if (subjectsSnapshot.hasData && subjectsSnapshot.data != null) {
                          final subjects = subjectsSnapshot.data!.docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final String subjectId = doc.id; // Get the subject ID

                            // Check if 'name' exists, if not, default to 'Team Asmolg'
                            final String professorName = data.containsKey('name') ? data['name'] : 'Team Asmolg';

                            return {
                              'name': data['subject'] ?? 'Unknown Subject',
                              'professorName': professorName, // Store the professor name or default value
                              'price': data['price'] ?? 'Free',
                              'subjectId': subjectId, // Store the subject ID
                            };
                          }).where((subject) {
                            // Filter subjects based on the search term
                            return subject['name']!
                                .toLowerCase()
                                .contains(_searchTerm); // Case-insensitive search
                          }).toList();

                          if (subjects.isEmpty) {
                            return const Center(child: Text('No subjects found for this department.'));
                          }

                          return ListView.builder(
                            itemCount: subjects.length,
                            itemBuilder: (context, index) {
                              final subject = subjects[index];
                              return ModernSubjectCard(
                                subjectName: subject['name']!,
                                professorName: subject['professorName']!,
                                price: subject['price']!,
                                departmentId: widget.departmentName, // Pass the department ID
                                subjectId: subject['subjectId']!, // Pass the subject ID
                              );
                            },
                          );
                        }

                        // If no data, show a message
                        return const Center(child: Text('No subjects found for this department.'));
                      },
                    );
                  }

                  // If no department found
                  return const Center(child: Text('Department not found.'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ModernSubjectCard extends StatefulWidget {
  final String subjectName;
  final String professorName; // Add the professorName parameter
  final String price;
  final String departmentId;
  final String subjectId; // Add the subjectId parameter

  const ModernSubjectCard({
    Key? key,
    required this.subjectName,
    required this.professorName, // Mark professorName as required
    required this.price,
    required this.departmentId,
    required this.subjectId, // Mark subjectId as required
  }) : super(key: key);

  @override
  _ModernSubjectCardState createState() => _ModernSubjectCardState();
}

class _ModernSubjectCardState extends State<ModernSubjectCard> {
  late Razorpay razorpay;
  bool _isSubscribed = false; // To track if the user is subscribed

  @override
  void initState() {
    super.initState();

    AwesomeNotifications().setListeners(onActionReceivedMethod: NotificationController.onActionReceivedMethod,
        onNotificationCreatedMethod: NotificationController.onNotificationCreatedMethod,
        onNotificationDisplayedMethod: NotificationController.onNotificationDisplayedMethod,
        onDismissActionReceivedMethod: NotificationController.onDismissActionReceivedMethod);

    razorpay = Razorpay();
    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlePaymentSuccess);
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, handlePaymentError);
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, handleExternalWallet);

    _checkSubscriptionStatus(); // Check if the user is already subscribed
  }

  Future<void> _checkSubscriptionStatus() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String userEmail = user.email ?? '';

      // Fetch subscription data for the user
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userEmail).get();

      // Check if the course is in the user's subscriptions
      if (userDoc.exists) {
        List<dynamic> boughtContent = userDoc['bought_content'];
        for (var content in boughtContent) {
          if (content['subject_id'] == widget.subjectId) { // Use subjectId for comparison
            setState(() {
              _isSubscribed = true; // Set to true if the user is subscribed to this course
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

      // Add `subject_id` in Subscriptions collection
      await FirebaseFirestore.instance.collection('users').doc(userEmail).set({
        'bought_content': FieldValue.arrayUnion([{
          'subject_name': widget.subjectName,
          'subject_id': widget.subjectId,  // Include the subject ID
          'price': widget.price,
          'department_name': widget.departmentId,
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
          'department_name': widget.departmentId,
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
            departmentDocId: widget.departmentId, // Pass departmentDocId
            subjectDocId: widget.subjectId,       // Pass subjectDocId
            subjectName: widget.subjectName,       // Pass subjectDocId
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
            departmentDocId: widget.departmentId, // Pass departmentDocId
            subjectDocId: widget.subjectId,       // Pass subjectDocId
            subjectName: widget.subjectName,       // Pass subjectDocId
          ),
        ),
      );
      return;
    }

    // If not subscribed, redirect to ContentPreviewPage with data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContentPreviewPage(
          departmentName: widget.departmentId,
          subjectName: widget.subjectName,
          subjectId: widget.subjectId,
          price: widget.price,
        ),
      ),
    );
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
        if (!_isSubscribed) {
          openCheckout(); // Only open checkout if not subscribed
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NotesPage(
                departmentDocId: widget.departmentId, // Pass departmentDocId
                subjectDocId: widget.subjectId,       // Pass subjectDocId
                subjectName: widget.subjectName,       // Pass subjectDocId
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 5,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // First row: Subject Name
              Row(
                children: [
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

              // Second row: Professor Name
              Row(
                children: [
                  const FaIcon(
                    FontAwesomeIcons.user,
                    color: Colors.blueAccent,
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

              // Third row: Notes Icon and Price or "Subscribed"
              Row(
                children: [
                  const FaIcon(
                    FontAwesomeIcons.moneyBill,
                    color: Colors.blueAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isSubscribed ? "Subscribed" : "Price: ₹ ${widget.price}",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _isSubscribed ? Colors.green : Colors.blueAccent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
