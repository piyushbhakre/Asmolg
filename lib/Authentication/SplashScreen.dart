import 'dart:async';
import 'package:asmolg/Authentication/AuthWrapper.dart';
import 'package:asmolg/Provider/DevelopermodeDectector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Provider/expired_subjects_controller.dart';
import '../Provider/fcm_controller.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String companyName = "";
  String tagline = "";
  bool isDataFetched = false;

  final FcmController fcmController = Get.put(FcmController());
  final ExpiredSubjectsController expiredSubjectsController = Get.put(ExpiredSubjectsController());

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // await _fetchSplashData();

    // Perform FCM token storage and expired subject deletion
    await fcmController.storeFcmToken();
    await expiredSubjectsController.deleteExpiredSubjects();

    // //------------------REMOVE IT FOR DEBUGGING-------------------------//
    //
    // final detection = DeveloperModeDetection();
    // await detection.checkDeveloperModeAndExit();
    //
    // //-----------------COMMENT ABOVE CODE WHILE DEBUGGING----------------//


    // Navigate to AuthWrapper after 3 seconds
    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthWrapper()),
      );
    });
  }

  // Future<void> _fetchSplashData() async {
  //   try {
  //     final snapshot = await FirebaseFirestore.instance
  //         .collection('Miscellaneous')
  //         .doc('DynamicSplash')
  //         .get();
  //
  //     if (snapshot.exists) {
  //       setState(() {
  //         companyName = snapshot.data()?['CompanyName'] ?? "";
  //         tagline = snapshot.data()?['Tagline'] ?? "";
  //         isDataFetched = true;
  //       });
  //     } else {
  //       print("Document does not exist");
  //     }
  //   } catch (e) {
  //     print("Error fetching splash data: $e");
  //     setState(() {
  //       companyName = "Error";
  //       tagline = "Unable to load data.";
  //       isDataFetched = true;
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: Image.asset(
              'assets/logo.png',
              height: 150,
              width: 150,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'Offered by',
                      style: GoogleFonts.alata(
                        fontSize: 18,
                        color: Colors.black,
                        fontWeight: FontWeight.w300,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      'Triroop Education Pvt Ltd',
                      style: GoogleFonts.alata(
                        fontSize: 20,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
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
