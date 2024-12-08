import 'package:asmolg/Authentication/AuthWrapper.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore for dynamic data
import 'dart:async';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  String companyName = ""; // Default values
  String tagline = "";
  bool isDataFetched = false;

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    // Initialize Animation Controller for looping animation
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);

    // Fetch data dynamically from Firestore
    _fetchSplashData();

    // Show splash screen for 3 seconds before fetching data
    Timer(Duration(seconds: 3), () {
      // Navigate to AuthWrapper after 3 seconds
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthWrapper()),
      );
    });
  }

  Future<void> _fetchSplashData() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Miscellaneous')
          .doc('DynamicSplash')
          .get();

      if (snapshot.exists) {
        setState(() {
          companyName = snapshot.data()?['CompanyName'] ?? "";
          tagline = snapshot.data()?['Tagline'] ?? "";
          isDataFetched = true; // Indicate data is fetched
        });
      } else {
        print("Document does not exist");
      }
    } catch (e) {
      print("Error fetching splash data: $e");
      setState(() {
        companyName = "Error";
        tagline = "Unable to load data.";
        isDataFetched = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set background to white
      body: Stack(
        children: [
          // Centered Logo with animation
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1 + (_controller.value * 0.1), // Slight pulsing effect
                  child: Image.asset(
                    'assets/logo.png', // Add your logo image in the assets folder
                    height: 150, // Increased logo size
                    width: 150,
                  ),
                );
              },
            ),
          ),
          // Align tagline and company name at bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40.0), // Adjust spacing at the bottom
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tagline
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0), // Adjust spacing between tagline and company name
                    child: Text(
                      tagline,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.black, // Black text on white background
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w300,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis, // Ensure text doesn't overflow
                      maxLines: 2, // Limit the number of lines
                    ),
                  ),
                  // Company Name
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0), // Padding at the bottom
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Text(
                          companyName,
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.black, // Black text on white background
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis, // Add ellipsis for overflow
                          maxLines: 2, // Limit number of lines
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}