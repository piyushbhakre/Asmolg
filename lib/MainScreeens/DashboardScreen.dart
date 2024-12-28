import 'package:asmolg/MainScreeens/CartPage.dart';
import 'package:asmolg/Provider/CartState.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:marquee/marquee.dart';
import 'package:shimmer/shimmer.dart';
import '../Provider/offline-online_status.dart';
import '../SeeAllPage.dart';
import '../aptitude_card.dart';
import '../department_card.dart';

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
  final DocumentReference _offerDocument = FirebaseFirestore.instance.collection('Miscellaneous').doc('SaleOffer');


  late List<AptitudeCard> aptitudeCourses = [];
  List<DepartmentCard> departmentCards = [];
  List<String> carouselImages = [];


  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
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
        final String departmentName = data?['department'] ??
            'Unknown Department';

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

        const String defaultImagePath = 'assets/tp.png';
        final String title = data?['course_name'] ?? 'Unknown Course';
        final String price = data?['price']?.toString() ?? 'Free';
        final String description = data?['description'] ??
            'No description available.';

        return AptitudeCard(
          imageUrl: defaultImagePath, // Always use asset image path
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        bottom: OfflineBanner(),
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'ASMOLG',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
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
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sale Title with Marquee Animation
            _isLoading
                ? _buildShimmerStrip() // Shimmer for the Sale Title
                : StreamBuilder<DocumentSnapshot>(
              stream: _offerDocument.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == null) {
                  return const SizedBox.shrink();
                }
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                final String? saleTitle = data?['Saletitle'];
                final bool status = data?['status'] ?? false;

                if (saleTitle == null || !status) {
                  return const SizedBox.shrink();
                }

                return Container(
                  color: Colors.black,
                  height: 50,
                  child: Marquee(
                    text: saleTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                    scrollAxis: Axis.horizontal,
                  ),
                );
              },
            ),

            // Carousel Section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: _isLoading
                  ? _buildShimmerCarousel() // Shimmer for Carousel
                  : CarouselSlider(
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
                        margin: const EdgeInsets.symmetric(horizontal: 1.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15.0),
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
            _isLoading
                ? _buildShimmerGrid() // Shimmer for department cards
                : _buildHorizontalList(departmentCards, () {
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

            // Placement Material Section
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
            _isLoading
                ? _buildShimmerGrid() // Shimmer for aptitude cards
                : _buildHorizontalList(aptitudeCourses, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SeeAllPage(
                    title: 'Placement Material',
                    items: aptitudeCourses,
                  ),
                ),
              );
            }),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }


  Widget _buildShimmerStrip() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 50,
        color: Colors.grey.shade300,
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: List.generate(3, (index) {
          return Expanded(
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                margin: const EdgeInsets.only(right: 16.0),
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }


  Widget _buildShimmerCarousel() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(15.0),
        ),
      ),
    );
  }

  Padding _buildSectionHeader(
      {required String title, required IconData icon, required VoidCallback onSeeAllPressed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.black),
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
              style: TextStyle(color: Colors.black),
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
                backgroundColor: Colors.black,
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