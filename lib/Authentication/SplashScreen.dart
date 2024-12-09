import 'dart:io';
import 'package:asmolg/Authentication/AuthWrapper.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
  @override
  void initState() {
    super.initState();
    // Move the async tasks to a separate method.
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize Animation Controller for looping animation
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    )..repeat(reverse: true);

    // Fetch data dynamically from Firestore
    await _fetchSplashData();

    // Set up Firebase Messaging and handle messages
    await setupFirebaseMessaging();
    await _storeFcmToken();
    await deleteExpiredSubjects();

    // Show splash screen for 3 seconds before navigating
    Timer(Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthWrapper()),
      );
    });
  }

  Future<void> setupFirebaseMessaging() async {
    await Firebase.initializeApp();  // Ensure Firebase is initialized before using it.
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request notification permissions on iOS (not necessary for Android)
    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Register Firebase Messaging token
    String? token = await messaging.getToken();
    print("Firebase Messaging Token: $token");

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received message in foreground: ${message.notification?.title}');
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          channelKey: 'basic_channel',
          title: message.notification?.title,
          body: message.notification?.body,
        ),
      );
    });

    // Handle when the user taps on the notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification clicked: ${message.notification?.title}');
    });

    // Check if the app was opened from a notification
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print('App opened from notification: ${initialMessage.notification?.title}');
    }
  }


  Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    // Initialize Firebase if it hasn’t been already
    await Firebase.initializeApp();
    print("Handling a background message: ${message.messageId}");
  }

// Daily task: Delete expired subjects
  Future<void> deleteExpiredSubjects() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Fetch expiry days
        int globalExpiryDays = 0;
        final expiryDoc = await FirebaseFirestore.instance
            .collection('Expiry days')
            .doc('Subject expiry')
            .get();
        if (expiryDoc.exists && expiryDoc.data() != null) {
          globalExpiryDays = int.tryParse(expiryDoc.data()!['days'].toString()) ?? 0;
        }

        // Fetch user's bought content
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.email)
            .get();
        if (userDoc.exists && userDoc.data() != null) {
          final boughtContent = userDoc.data() as Map<String, dynamic>;
          List<dynamic> subjects = boughtContent['bought_content'] ?? [];

          for (var item in subjects) {
            DateTime purchaseDate = item['date'] is Timestamp
                ? (item['date'] as Timestamp).toDate()
                : DateTime.tryParse(item['date'].toString()) ?? DateTime.now();

            if (globalExpiryDays > 0) {
              bool expired = isExpired(purchaseDate, globalExpiryDays);
              if (expired) {
                // Delete expired subject
                await FirebaseFirestore.instance.collection('users').doc(user.email).update({
                  'bought_content': FieldValue.arrayRemove([item])
                });
                print("Deleted expired subject: ${item['subject_id']}");
              }
            }
          }
        }
      }
    } catch (e) {
      print("Error in deleting expired subjects: $e");
    }
  }

// Helper function to check if a subject is expired
  bool isExpired(DateTime purchaseDate, int expiryDays) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime expiryDate = purchaseDate.add(Duration(days: expiryDays));
    DateTime expiryStartDate = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);

    return expiryStartDate.isBefore(today) || expiryStartDate.isAtSameMomentAs(today);
  }


// Store FCM token, device name in Firestore
  Future<void> _storeFcmToken() async {
    try {
      // Get the FCM token
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) {
        print("Unable to fetch FCM token.");
        return;
      }

      // Get the device name
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      String deviceName = "Unknown Device";
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceName = androidInfo.model;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceName = iosInfo.utsname.machine;
      }

      // Reference to the document in the fcmtoken collection
      DocumentReference docRef = FirebaseFirestore.instance.collection('fcmtoken').doc(deviceName);

      // Check if the document exists
      DocumentSnapshot docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        // Document exists, check the token
        final data = docSnapshot.data() as Map<String, dynamic>?; // Cast to Map<String, dynamic>
        String? existingToken = data?['token']; // Safely access 'token'

        if (existingToken == fcmToken) {
          print("FCM token already matches the stored token for $deviceName. No update needed.");
          return;
        } else {
          // Update the token if it is different or missing
          print("Updating FCM token for $deviceName.");
          await docRef.update({'token': fcmToken});
        }
      } else {
        // Document does not exist, create a new one
        print("No document found for $deviceName. Creating a new document.");
        await docRef.set({'token': fcmToken});
      }

      print("FCM token stored successfully for $deviceName.");
    } catch (e) {
      print("Error storing FCM token: $e");
    }
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