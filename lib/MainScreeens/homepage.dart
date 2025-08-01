import 'package:asmolg/Support.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flashy_tab_bar2/flashy_tab_bar2.dart';
import 'Profile.dart';
import 'DashboardScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    DashboardScreen(),
    ProfileApp(),
    SupportPage(),
  ];

  @override
  void initState() {
    super.initState();

    // Hide the system navigation bar for fullscreen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);

    // Make the status bar transparent
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background gradient for a modern educational look
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black, // Deep blue at the top
                  Colors.black, // Light blue at the bottom
                ],
              ),
            ),
          ),
          // Subtle overlay for better contrast
          Container(
            color: Colors.black.withOpacity(0.04),
          ),
          // Page content based on selected index
          _pages[_currentIndex],
        ],
      ),
      bottomNavigationBar: FlashyTabBar(
        selectedIndex: _currentIndex,
        showElevation: true,
        animationDuration: Duration(milliseconds: 300),
        onItemSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          FlashyTabBarItem(
            icon: const Icon(FontAwesomeIcons.bookReader),
            title: const Text('Courses'),
            activeColor: Colors.black, // Educational color theme
          ),
          FlashyTabBarItem(
            icon: const Icon(FontAwesomeIcons.userGraduate),
            title: const Text('Profile'),
            activeColor: Colors.black,
          ),
          FlashyTabBarItem(
            icon: const Icon(FontAwesomeIcons.headset),
            title: const Text('Support'),
            activeColor: Colors.black,
          ),
        ],
      ),
    );
  }
}
