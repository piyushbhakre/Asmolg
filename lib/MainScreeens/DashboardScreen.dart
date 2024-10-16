import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:screen_protector/screen_protector.dart';

import '../SeeAllPage.dart';
import '../aptitude_card.dart';
import '../department_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final CollectionReference _departmentCollection = FirebaseFirestore.instance.collection('notes');
  final CollectionReference _carouselCollection = FirebaseFirestore.instance.collection('Carousel Ads');
  final CollectionReference _aptitudeCoursesCollection = FirebaseFirestore.instance.collection('Aptitude');

  late List<AptitudeCard> aptitudeCourses = [];
  List<DepartmentCard> departmentCards = [];
  List<String> carouselImages = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Prevent screenshots when the app is running
    ScreenProtector.preventScreenshotOn();
    fetchDepartments();
    fetchAptitudeCourses();
    fetchCarouselAds();
  }

  Future<void> fetchDepartments() async {
    try {
      final QuerySnapshot snapshot = await _departmentCollection.get();
      final List<DepartmentCard> departments = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        final String? imageUrl = data?['bannerUrl'];
        final String departmentName = data?['department'] ?? 'Unknown Department';

        return DepartmentCard(
          imageUrl: imageUrl ?? 'https://via.placeholder.com/150',
          departmentName: departmentName,
        );
      }).toList();

      setState(() {
        departmentCards = departments;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching departments: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> fetchCarouselAds() async {
    try {
      final QuerySnapshot snapshot = await _carouselCollection.get();
      final List<String> ads = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        final String? imageUrl = data?['image'];
        return imageUrl ?? 'https://via.placeholder.com/350x150';
      }).toList();

      setState(() {
        carouselImages = ads;
      });
    } catch (e) {
      print("Error fetching carousel ads: $e");
    }
  }

  Future<void> fetchAptitudeCourses() async {
    try {
      final QuerySnapshot snapshot = await _aptitudeCoursesCollection.get();
      final List<AptitudeCard> courses = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        final String? bannerUrl = data?['bannerUrl'];
        final String title = data?['course_name'] ?? 'Unknown Course';
        final String price = data?['price'] ?? 'Free';
        final String description = data?['description'] ?? 'No description available.';

        return AptitudeCard(
          imageUrl: bannerUrl ?? 'https://via.placeholder.com/150',
          title: title,
          price: price,
          description: description,
        );
      }).toList();

      setState(() {
        aptitudeCourses = courses;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching aptitude courses: $e");
    }
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
            title: const Text(
              'Home',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              // IconButton(
              //   icon: const Icon(
              //     Icons.notifications,
              //     color: Colors.black,
              //   ),
              //   onPressed: () {
              //     ScaffoldMessenger.of(context).showSnackBar(
              //       const SnackBar(content: Text('Notifications clicked')),
              //     );
              //   },
              // ),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: CircleAvatar(
                  backgroundImage: AssetImage('assets/logo.png'),
                  radius: 20,
                ),
              ),
            ],
          ),
          body: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Carousel Section
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: CarouselSlider(
                      options: CarouselOptions(
                        height: 200.0,
                        autoPlay: true,
                        enlargeCenterPage: true,
                        enableInfiniteScroll: true,
                        autoPlayInterval: const Duration(seconds: 3),
                      ),
                      items: carouselImages.map((imageUrl) {
                        return Builder(
                          builder: (BuildContext context) {
                            return Container(
                              width: MediaQuery.of(context).size.width,
                              margin: const EdgeInsets.symmetric(horizontal: 10.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 4,
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15.0),
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),

                  // Departments Section
                  _buildSectionHeader(
                    title: 'Engineering Departments',
                    onSeeAllPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SeeAllPage(
                            title: 'Engineering Departments',
                            items: departmentCards,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildHorizontalList(departmentCards),

                  // Aptitude Courses Section
                  _buildSectionHeader(
                    title: 'Aptitude Courses',
                    onSeeAllPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SeeAllPage(
                            title: 'Aptitude Courses',
                            items: aptitudeCourses,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildHorizontalList(aptitudeCourses),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.white.withOpacity(0.8),
            child: Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
                color: Colors.blue,
                size: 50,
              ),
            ),
          ),
      ],
    );
  }

  Padding _buildSectionHeader({required String title, required VoidCallback onSeeAllPressed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          TextButton(
            onPressed: onSeeAllPressed,
            child: const Text(
              'See All',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Container _buildHorizontalList(List<dynamic> items) {
    return Container(
      height: 200,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        children: items.cast<Widget>(), // Casting items to List<Widget>
      ),
    );
  }
}
