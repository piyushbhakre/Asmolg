import 'package:asmolg/Authentication/LoginScreen.dart';
import 'package:asmolg/MainScreeens/NotesPage.dart';
import 'package:asmolg/Provider/offline-online_status.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:quickalert/quickalert.dart'; // Import QuickAlert
import 'package:intl/intl.dart'; // Import intl for date formatting
import 'package:shimmer/shimmer.dart';
import '../AptitudeTopicPage.dart';
import '../Provider/expired_subjects_controller.dart';

class ProfileApp extends StatefulWidget {
  @override
  _ProfileAppState createState() => _ProfileAppState();
}

class _ProfileAppState extends State<ProfileApp> {
  final User? user = FirebaseAuth.instance.currentUser; // Fetch current logged-in user
  final ExpiredSubjectsController expiredSubjectsController = Get.find();
  String phone = ''; // Placeholder for phone number
  String fullName = ''; // Placeholder for full name
  bool isLoading = true; // Loading state
  List<Map<String, dynamic>> boughtCourses = []; // List of courses with subject_id

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
    expiredSubjectsController.deleteExpiredSubjects();
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
                  expiredSubjectsController.deleteExpiredSubjects();
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

  void _showSignOutDialog(BuildContext context) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.confirm,
      text: 'Do you want to logout?',
      confirmBtnText: 'Yes',
      cancelBtnText: 'No',
      confirmBtnColor: Colors.black,
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
              OfflineBanner(height: 24.0),
              if (isLoading)
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Shimmer Effect for Profile Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(width: 150, height: 20, color: Colors.white),
                                  SizedBox(height: 5),
                                  Container(width: 200, height: 15, color: Colors.white),
                                  SizedBox(height: 5),
                                  Container(width: 120, height: 15, color: Colors.white),
                                ],
                              ),
                              // Shimmer Effect for Three-dot Menu
                              Container(width: 30, height: 30, color: Colors.white),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Shimmer Effect for Bought Courses Section
                          Container(width: double.infinity, height: 45, color: Colors.white),
                          const SizedBox(height: 10),

                          // Shimmer Effect for Bought Courses List
                          Container(height: 600, color: Colors.transparent),
                        ],
                      ),
                    ),
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
                                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                  ),
                                SizedBox(height: 5),
                                Text(
                                  phone,
                                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
                                  PopupMenuItem<String>(value: 'sign_out', child: Text('Sign Out')),
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
                                  indicatorColor: Colors.black,
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
        // If data is loading, show shimmer effect for the list of cards
        if (isLoading) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!, // Shimmer base color
            highlightColor: Colors.grey[100]!, // Shimmer highlight color
            child: ListView.builder(
              itemCount: 5, // Display 5 shimmer cards while loading
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  height: 100,
                  color: Colors.white,
                  child: ListTile(
                    leading: Container(width: 40, height: 40, color: Colors.white), // Shimmer for icon
                    title: Container(width: 120, height: 16, color: Colors.white), // Shimmer for title
                    subtitle: Column(
                      children: [
                        Container(width: 150, height: 12, color: Colors.white), // Shimmer for subtitle text
                        SizedBox(height: 5),
                        Container(width: 100, height: 12, color: Colors.white), // Shimmer for second subtitle
                      ],
                    ),
                    trailing: Container(width: 30, height: 30, color: Colors.white), // Shimmer for trailing icon
                  ),
                );
              },
            ),
          );
        }

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
                        Get.to(() => NotesPage(
                          subjectName: course['content'],
                          subjectDocId: course['subject_id'], // Pass the subjectId
                          departmentDocId: course['department_name'] ?? 'Unknown',
                        ));

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
                        leading: const Icon(Icons.book, color: Colors.black),
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