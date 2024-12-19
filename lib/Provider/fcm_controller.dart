import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class FcmController extends GetxController {
  /// Store the FCM token and associate it with a unique document ID
  Future<void> storeFcmToken() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Check if the deviceName_UUID exists in SharedPreferences
      String? uniqueDocumentId = prefs.getString('device_uuid');

      // If it does not exist, generate a new one
      if (uniqueDocumentId == null) {
        DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
        String deviceName = "UnknownDevice";

        if (Platform.isAndroid) {
          AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
          deviceName = androidInfo.model ?? "UnknownAndroidDevice";
        } else if (Platform.isIOS) {
          IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
          deviceName = iosInfo.utsname.machine ?? "UnknowniOSDevice";
        }

        uniqueDocumentId = "$deviceName-${Uuid().v4()}";
        await prefs.setString('device_uuid', uniqueDocumentId); // Save in SharedPreferences
        print("Generated new device UUID: $uniqueDocumentId");
      } else {
        print("Using existing device UUID from SharedPreferences: $uniqueDocumentId");
      }

      // Get the FCM token
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) {
        print("Unable to fetch FCM token.");
        return;
      }

      // Reference to the document in the fcmtoken collection
      DocumentReference docRef = FirebaseFirestore.instance.collection('fcmtoken').doc(uniqueDocumentId);

      // Check if the document exists
      DocumentSnapshot docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        // Document exists, check if the token matches
        final data = docSnapshot.data() as Map<String, dynamic>?;
        String? existingToken = data?['token'];

        if (existingToken == fcmToken) {
          print("FCM token already matches the stored token for $uniqueDocumentId. No update needed.");
          return;
        } else {
          // Update the token if it is different
          print("Token mismatch. Updating FCM token for $uniqueDocumentId.");
          await docRef.update({'token': fcmToken});
        }
      } else {
        // Document does not exist, create a new one
        print("No document found for $uniqueDocumentId. Creating a new document.");
        await docRef.set({'token': fcmToken});
      }

      print("FCM token stored successfully for $uniqueDocumentId.");
    } catch (e) {
      print("Error storing FCM token: $e");
    }
  }
}
