import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'AptitudeTopicPage.dart';
import 'NotificationController.dart';
import 'TopicsPage.dart';
import 'LoginPage.dart'; // Import your LoginPage here

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

  Future<void> fetchUserDetails() async {
    if (user != null) {
      try {
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

      // Fetch bought subjects or courses
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
              return {
                "content": item['aptitude_name'] ?? item['subject_name'] ?? 'Unknown Content',
                "date": item['date'] ?? 'Unknown Date',
                "department_name": item['department_name'] ?? 'Unknown Department',
                "subject_id": item['subject_id'] ?? '', // Store the subject_id here
                "isAptitude": item.containsKey('aptitude_name'), // Determine if it's an aptitude
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
        builder: (context) => LoginPage(), // Your LoginPage widget
      ),
    );
  }

  // Method to show a sign-out confirmation dialog
  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Sign Out"),
          content: const Text("Are you sure you want to sign out?"),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text("Sign Out"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _signOut(); // Call sign-out function
              },
            ),
          ],
        );
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
                            // Three-dot menu
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
                              icon: Icon(Icons.more_vert),
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
                padding: const EdgeInsets.symmetric( vertical: 8.0),
                itemCount: filteredCourses.length,
                itemBuilder: (context, index) {
                  final course = filteredCourses[index];
                  return GestureDetector(
                    onTap: () {
                      // Check if the course is an aptitude or a regular subject
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
                            builder: (context) => TopicsPage(
                              subjectName: course['content'],
                              subjectId: course['subject_id'], // Pass the subjectId
                              departmentName: course['department_name'] ?? 'Unknown',
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
                        subtitle: Text('Purchased on: ${course['date']}'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 40),

          ],
        );
      },
    );
  }
}
