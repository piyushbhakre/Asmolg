import 'package:asmolg/Authentication/LoginScreen.dart';
import 'package:asmolg/MainScreeens/NotesPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:quickalert/quickalert.dart'; // Import QuickAlert
import 'package:intl/intl.dart'; // Import intl for date formatting
import '../AptitudeTopicPage.dart';

class ProfileApp extends StatefulWidget {
  @override
  _ProfileAppState createState() => _ProfileAppState();
}

class _ProfileAppState extends State<ProfileApp> {
  final User? user = FirebaseAuth.instance.currentUser; // Fetch current logged-in user
  String phone = ''; // Placeholder for phone number
  String fullName = ''; // Placeholder for full name
  bool isLoading = true; // Loading state
  List<Map<String, dynamic>> boughtCourses = []; // List of courses with subject_id

  @override
  void initState() {
    super.initState();
    fetchUserDetails(); // Fetch the phone number and full name when the widget is initialized
  }
// Helper function to strip the time from DateTime and compare just the date part
  bool isExpired(DateTime purchaseDate, int expiryDays) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime expiryDate = purchaseDate.add(Duration(days: expiryDays));
    DateTime expiryStartDate = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);

    return expiryStartDate.isBefore(today) || expiryStartDate.isAtSameMomentAs(today);
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
            fullName = data['FullName'] ?? 'No full name';
            isLoading = false;
          });
        } else {
          setState(() {
            phone = 'No phone number';
            fullName = 'No full name';
            isLoading = false;
          });
        }
      } catch (e) {
        print("Error fetching user details: $e");
        setState(() {
          phone = 'Error fetching phone number';
          fullName = 'Error fetching full name';
          isLoading = false;
        });
      }

      // Fetch Expiry Days from "Expiry days" collection
      int globalExpiryDays = 0;
      try {
        final expiryDoc = await FirebaseFirestore.instance
            .collection('Miscellaneous')
            .doc('Subject expiry')
            .get();
        if (expiryDoc.exists && expiryDoc.data() != null) {
          globalExpiryDays = int.tryParse(expiryDoc.data()!['days'].toString()) ?? 0;
        }
      } catch (e) {
        print("Error fetching global expiry days: $e");
      }

      // Fetch Bought Subjects or Courses for the User
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.email)
            .get();
        if (userDoc.exists && userDoc.data() != null) {
          final boughtContent = userDoc.data() as Map<String, dynamic>;
          List<dynamic> subjects = boughtContent['bought_content'] ?? [];

          // Process the bought subjects or courses
          setState(() {
            boughtCourses = subjects.map((item) {
              DateTime purchaseDate = item['date'] is Timestamp
                  ? (item['date'] as Timestamp).toDate()
                  : DateTime.tryParse(item['date'].toString()) ?? DateTime.now();

              // Use the global expiry days value to calculate expiry date
              DateTime? expiryDate;
              if (globalExpiryDays > 0) {
                expiryDate = purchaseDate.add(Duration(days: globalExpiryDays));
                // Adjusted expiry check
                if (isExpired(purchaseDate, globalExpiryDays)) {
                  _deleteExpiredSubject(item); // Make sure 'item' is the exact map from the array
                }

              }

              return {
                "content": item['course_name'] ?? item['subject_name'] ?? 'Unknown Content',
                "date": item['date'] ?? 'Unknown Date',
                "department_name": item['department_name'] ?? 'Unknown Department',
                "subject_id": item['subject_id'] ?? '',
                "expiry_date": expiryDate,
                "expiry_days": globalExpiryDays,
                "isAptitude": item.containsKey('course_name'),
              };
            }).toList();
          });
        }
      } catch (e) {
        print("Error fetching bought subjects or courses: $e");
      }
    }
  }


  Future<void> _deleteExpiredSubject(Map<String, dynamic> subject) async {
    if (user != null && subject['subject_id'] != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user!.email).update({
          'bought_content': FieldValue.arrayRemove([subject])
        });
        print("Expired subject deleted: ${subject['subject_id']}");
      } catch (e) {
        print("Error deleting expired subject: $e");
      }
    }
  }





  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    // After signing out, navigate to the login screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(), // Your LoginPage widget
      ),
    );
  }

  // Method to show a sign-out confirmation dialog using QuickAlert
  void _showSignOutDialog(BuildContext context) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.confirm,
      text: 'Do you want to logout?',
      confirmBtnText: 'Yes',
      cancelBtnText: 'No',
      confirmBtnColor: Colors.green,
      onConfirmBtnTap: () {
        Navigator.of(context).pop(); // Close the dialog
        _signOut(); // Call sign-out function
      },
      onCancelBtnTap: () {
        Navigator.of(context).pop(); // Close the dialog on cancel
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.grey[100],
        body: SafeArea(
          child: Stack(
            children: [
              if (isLoading)
                Center(
                  child: LoadingAnimationWidget.staggeredDotsWave(
                    color: Colors.blueAccent,
                    size: 50,
                  ),
                ),
              if (!isLoading)
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User Profile Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fullName,
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 5),
                                if (user != null)
                                  Text(
                                    user!.email ?? 'No Email',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                SizedBox(height: 5),
                                Text(
                                  phone,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            // Three-dot menu for sign-out
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'sign_out') {
                                  _showSignOutDialog(context); // Show sign-out confirmation dialog
                                }
                              },
                              itemBuilder: (BuildContext context) {
                                return [
                                  PopupMenuItem<String>(
                                    value: 'sign_out',
                                    child: Text('Sign Out'),
                                  ),
                                ];
                              },
                              icon: Icon(Icons.more_vert), // Three-dot icon
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Bought Courses Tab
                        DefaultTabController(
                          length: 1,
                          child: Column(
                            children: [
                              // "Bought Courses" Section
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: TabBar(
                                  tabs: [
                                    Tab(text: 'Bought Courses'),
                                  ],
                                  indicatorColor: Colors.blueAccent,
                                  labelPadding: EdgeInsets.zero,
                                  labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                                  unselectedLabelColor: Colors.grey,
                                  indicatorWeight: 2.0,
                                ),
                              ),
                              Container(
                                height: 600,
                                color: Colors.transparent,
                                child: TabBarView(
                                  children: [
                                    _buildBoughtCoursesTab(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoughtCoursesTab() {
    String searchQuery = "";

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        // Filter the bought courses based on the search query
        List<Map<String, dynamic>> filteredCourses = boughtCourses
            .where((course) => course['content']!.toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();

        return Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  hintText: 'Search courses...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
                ),
                onChanged: (query) {
                  setState(() {
                    searchQuery = query;
                  });
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                itemCount: filteredCourses.length,
                itemBuilder: (context, index) {
                  final course = filteredCourses[index];

                  // Format the purchase and expiry dates
                  String formattedPurchaseDate = 'Unknown Date';
                  String formattedExpiryDate = 'Lifetime Subscription';

                  if (course['date'] is Timestamp) {
                    formattedPurchaseDate =
                        DateFormat('dd-MM-yyyy').format((course['date'] as Timestamp).toDate());
                  } else if (course['date'] is String) {
                    DateTime parsedDate = DateTime.tryParse(course['date']) ?? DateTime.now();
                    formattedPurchaseDate = DateFormat('dd-MM-yyyy').format(parsedDate);
                  }

                  if (course['expiry_days'] > 0 && course['expiry_date'] != null) {
                    formattedExpiryDate =
                        DateFormat('dd-MM-yyyy').format(course['expiry_date'] as DateTime);
                  }

                  return GestureDetector(
                    onTap: () {
                      // Navigate based on whether it’s an aptitude or a regular subject
                      if (course['isAptitude'] == true) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AptitudeTopicPage(
                              aptitudeName: course['content'], // Pass the aptitude_name
                            ),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotesPage(
                              subjectName: course['content'],
                              subjectDocId: course['subject_id'], // Pass the subjectId
                              departmentDocId: course['department_name'] ?? 'Unknown',
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 8,
                            spreadRadius: 2,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.book, color: Colors.blueAccent),
                        title: Text(
                          course['content'],
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5), // Space between title and purchase date
                            Text(
                              'Purchased: $formattedPurchaseDate',
                              style: const TextStyle(fontSize: 14, color: Colors.black),
                            ),
                            const SizedBox(height: 8), // Space between purchase and expiry date
                            Text(
                              'Expires: $formattedExpiryDate',
                              style: TextStyle(
                                fontSize: 14,
                                color: formattedExpiryDate == 'Lifetime Subscription'
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        );
      },
    );
  }
}