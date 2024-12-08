import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:screen_protector/screen_protector.dart';

import '../SeeAllPage.dart';
import '../aptitude_card.dart';
import '../department_card.dart';
import 'CartPage.dart';
import 'contentPreview.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final CollectionReference _departmentCollection = FirebaseFirestore.instance
      .collection('notes');
  final CollectionReference _carouselCollection = FirebaseFirestore.instance
      .collection('Carousel Ads');
  final CollectionReference _aptitudeCoursesCollection = FirebaseFirestore
      .instance.collection('aptitude');

  late List<AptitudeCard> aptitudeCourses = [];
  List<DepartmentCard> departmentCards = [];
  List<String> carouselImages = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    ScreenProtector.preventScreenshotOn();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    setState(() {
      _isLoading = true;
    });
    await Future.wait([
      fetchDepartments(),
      fetchAptitudeCourses(),
      fetchCarouselAds(),
    ]);
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> fetchDepartments() async {
    try {
      final QuerySnapshot snapshot = await _departmentCollection.get();
      final List<DepartmentCard> departments = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        final String? imageUrl = data?['bannerUrl'];
        final String departmentName =
            data?['department'] ?? 'Unknown Department';

        return DepartmentCard(
          imageUrl: imageUrl ?? 'https://via.placeholder.com/150',
          departmentName: departmentName,
        );
      }).toList();

      setState(() {
        departmentCards = departments;
      });
    } catch (e) {
      print("Error fetching departments: $e");
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

        const String defaultImagePath = 'assets/tp.png';
        final String title = data?['course_name'] ?? 'Unknown Course';
        final String price = data?['price']?.toString() ?? 'Free';
        final String description =
            data?['description'] ?? 'No description available.';

        return AptitudeCard(
          imageUrl: defaultImagePath, // Always use asset image path
          title: title,
          price: price,
          description: description,
        );
      }).toList();

      setState(() {
        aptitudeCourses = courses;
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
            elevation: 0,
            backgroundColor: Colors.white,
            title: const Text(
              'Home',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartPage()),
                  );
                },
                child: Stack(
                  children: [
                    // Cart Icon with slight padding to adjust its position
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0), // Move the cart icon slightly to the left
                      child: const Icon(Icons.shopping_cart, color: Colors.black),
                    ),
                    // Cart Badge at the top-right corner of the cart icon
                    Positioned(
                      right: 0,
                      bottom: 8,
                      child: ValueListenableBuilder<int>(
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
                              : const SizedBox.shrink(); // No badge when cartCount is 0
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          body: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: RefreshIndicator(
              onRefresh: _fetchAllData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                                margin:
                                const EdgeInsets.symmetric(horizontal: 1.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15.0),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                      ),
                                    ],
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
                      title: 'Engineering',
                      icon: Icons.school,
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
                    _buildHorizontalList(departmentCards, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SeeAllPage(
                            title: 'Engineering Departments',
                            items: departmentCards,
                          ),
                        ),
                      );
                    }),

                    // Aptitude Courses Section
                    _buildSectionHeader(
                      title: 'Placement Material',
                      icon: Icons.lightbulb,
                      onSeeAllPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SeeAllPage(
                              title: 'Placement Material',
                              items: aptitudeCourses,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildHorizontalList(aptitudeCourses, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SeeAllPage(
                            title: 'Aptitude Courses',
                            items: aptitudeCourses,
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.white.withOpacity(0.8),
            child: Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
                color: Colors.blueAccent,
                size: 50,
              ),
            ),
          ),
      ],
    );
  }

  Padding _buildSectionHeader({
    required String title,
    required IconData icon,
    required VoidCallback onSeeAllPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blueAccent),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: onSeeAllPressed,
            child: const Text(
              'See All',
              style: TextStyle(color: Colors.blueAccent),
            ),
          ),
        ],
      ),
    );
  }

  Container _buildHorizontalList(List<dynamic> items,
      VoidCallback onSeeAllPressed) {
    return Container(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: items.length > 5 ? 6 : items.length,
        // Show only 5 items + "See All" button if more than 5 items
        itemBuilder: (context, index) {
          if (index == 5) {
            // Display "See All" button after 5 items
            return GestureDetector(
              onTap: onSeeAllPressed,
              child: CircleAvatar(
                backgroundColor: Colors.blueAccent,
                radius: 30,
                child: const Icon(Icons.arrow_forward, color: Colors.white),
              ),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: items[index] as Widget,
            );
          }
        },
      ),
    );
  }
}
