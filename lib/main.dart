import 'package:asmolg/Authentication/AuthWrapper.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await AwesomeNotifications().initialize(
      null, // Custom icon path
      [
        NotificationChannel(
          channelGroupKey: "basic channel group key",
          channelKey: "basic channel",
          channelName: "Basic Notifications",
          channelDescription: "Notification channel for basic tests",
          defaultColor: Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.High,  // Set importance to High
          playSound: true,
          enableVibration: true,
        )
      ],
      channelGroups: [
        NotificationChannelGroup(
            channelGroupKey: "basic channel group key",
            channelGroupName: "basic group"
        )
      ],
    debug: true,
  );

  bool isAllowedToSendNotification = await AwesomeNotifications().isNotificationAllowed();
if(!isAllowedToSendNotification){
  AwesomeNotifications().requestPermissionToSendNotifications();
}
  runApp(const MyApp());

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(

      debugShowCheckedModeBanner: false,
      home: AuthWrapper(),
    );
  }
}



