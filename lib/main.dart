import 'dart:ui';
import 'package:asmolg/Authentication/SplashScreen.dart';
import 'package:asmolg/Provider/DevelopermodeDectector.dart';
import 'package:asmolg/Provider/UserController.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:get/get.dart';

const String deleteExpiredSubjectsTask = "deleteExpiredSubjects";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Get.put(DeveloperModeDetection());
  await Firebase.initializeApp();
  Get.put(UserController());

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

  bool isAllowedToSendNotification = await AwesomeNotifications().isNotificationAllowed();
  if (!isAllowedToSendNotification) {
    AwesomeNotifications().requestPermissionToSendNotifications();
  }


  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}