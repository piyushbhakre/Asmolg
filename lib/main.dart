import 'dart:io';
import 'dart:ui';
import 'package:asmolg/Authentication/AuthWrapper.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_wrapper/connectivity_wrapper.dart';
import 'package:once/once.dart';
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

const String deleteExpiredSubjectsTask = "deleteExpiredSubjects";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize Firebase Messaging
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Awesome Notifications
  await AwesomeNotifications().initialize(
    null, // Custom icon path
    [
      NotificationChannel(
        channelGroupKey: "basic_channel_group_key",
        channelKey: "basic_channel",
        channelName: "Basic Notifications",
        channelDescription: "Notification channel for basic tests",
        defaultColor: Color(0xFF9D50DD),
        ledColor: Colors.white,
        importance: NotificationImportance.High,
        playSound: true,
        enableVibration: true,
      )
    ],
    channelGroups: [
      NotificationChannelGroup(
        channelGroupKey: "basic_channel_group_key",
        channelGroupName: "Basic Group",
      )
    ],
    debug: true,
  );

  // Request notification permissions
  bool isAllowedToSendNotification = await AwesomeNotifications().isNotificationAllowed();
  if (!isAllowedToSendNotification) {
    AwesomeNotifications().requestPermissionToSendNotifications();
  }

  // Set up Firebase Messaging and handle messages
  await setupFirebaseMessaging();

  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  await _storeFcmToken();
  // Run tasks every 12 hours
  await Once.runEvery12Hours(deleteExpiredSubjectsTask, callback: deleteExpiredSubjects);

  runApp(const MyApp());
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

Future<void> setupFirebaseMessaging() async {
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
    // Show notification using Awesome Notifications
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        channelKey: 'basic_channel',
        title: message.notification?.title,
        body: message.notification?.body,
      ),
    );
  });

  // Handle when the user taps on the notification and opens the app
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('Notification clicked: ${message.notification?.title}');
    // You can navigate to a specific screen if required
  });

  // Check if the app was opened from a notification
  RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    print('App opened from notification: ${initialMessage.notification?.title}');
    // Navigate to a specific screen if needed
  }
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
      deviceName = androidInfo.model ?? "Android Device";
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceName = iosInfo.utsname.machine ?? "iOS Device";
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


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ConnectivityAppWrapper(
      app: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ConnectivityWidgetWrapper(
          child: AuthWrapper(),
          disableInteraction: true,
          height: 80,
          message: "No internet connection! Please reconnect.",
        ),
      ),
    );
  }
}
