import 'package:asmolg/Authentication/AuthWrapper.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_wrapper/connectivity_wrapper.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if it hasn’t been already
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

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

  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

  OneSignal.initialize("cd32a0b0-2476-4529-9a20-965b26b5eb5e");

  OneSignal.Notifications.requestPermission(true);

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  runApp(const MyApp());
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
