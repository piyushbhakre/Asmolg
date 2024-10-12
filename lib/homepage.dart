import 'package:asmolg/Support.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For SystemChrome and hiding system UI
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flashy_tab_bar2/flashy_tab_bar2.dart'; // Import flashy_tab_bar2
import 'Profile.dart';
import 'home.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    ProfileApp(),
    SupportPage(),
  ];

  @override
  void initState() {
    super.initState();

    // Hide only the system navigation bar for a true fullscreen experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);

    // Make the status bar transparent
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Transparent status bar
      statusBarIconBrightness: Brightness.light, // Light status bar icons
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Extend body behind the bottom navigation bar
      body: Stack(
        children: [
          // Background gradient for a modern look
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF4A90E2), // Top gradient color
                  Color(0xFF50B2C0), // Bottom gradient color
                ],
              ),
            ),
          ),
          // Page content
          _pages[_currentIndex],
        ],
      ),
      bottomNavigationBar: FlashyTabBar(
        selectedIndex: _currentIndex,
        showElevation: true, // Show a shadow/elevation effect
        onItemSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          FlashyTabBarItem(
            icon: const Icon(FontAwesomeIcons.home),
            title: const Text('Home'),
            activeColor: Colors.blue, // Highlight in blue when active
          ),
          FlashyTabBarItem(
            icon: const Icon(FontAwesomeIcons.userAstronaut),
            title: const Text('Profile'),
            activeColor: Colors.blue, // Highlight in blue when active
          ),
          FlashyTabBarItem(
            icon: const Icon(FontAwesomeIcons.questionCircle),
            title: const Text('Support'),
            activeColor: Colors.blue, // Highlight in blue when active
          ),
        ],
      ),
    );
  }
}
