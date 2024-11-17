import 'package:asmolg/Authentication/LoginPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart' as package_info_plus;
import 'package:flutter_upgrade_version/flutter_upgrade_version.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Import Firebase Messaging
import 'package:shared_preferences/shared_preferences.dart';
import '../MainScreeens/homepage.dart';

class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isUpdateRequired = false;
  bool _updateDialogShown = false;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
    _handlePermissions();
    _revokeNotificationPermissions(); // Call method to revoke notification permissions
  }

  Future<void> _checkForUpdate() async {
    package_info_plus.PackageInfo packageInfo = await package_info_plus.PackageInfo.fromPlatform();
    InAppUpdateManager updateManager = InAppUpdateManager();

    // Check for updates on Android
    AppUpdateInfo? updateInfo = await updateManager.checkForUpdate();
    if (updateInfo != null && updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
      setState(() => _isUpdateRequired = true);
      if (!_updateDialogShown) _showUpdateDialog(); // Show update dialog if not already shown
    }
  }

  Future<void> _showUpdateDialog() async {
    setState(() => _updateDialogShown = true);
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dialog from closing on outside tap
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          backgroundColor: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(Icons.shop, color: Colors.blue, size: 60), // Placeholder for Play Store icon
                    SizedBox(height: 12),
                    Text(
                      "Update Available",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "A new version of the app is available. Please update to continue.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _startUpdate,
                      child: Text(
                        "Update Now",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white), // White text color
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Abhi update kar lo, future aur bhi bright hoga! 🌟", // Updated humorous phrase in Hinglish
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) => setState(() => _updateDialogShown = false));
  }

  Future<void> _startUpdate() async {
    InAppUpdateManager manager = InAppUpdateManager();
    AppUpdateInfo? updateInfo = await manager.checkForUpdate();
    if (updateInfo != null) {
      await manager.startAnUpdate(type: AppUpdateType.immediate);
    }
  }

  Future<void> _handlePermissions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int permissionState = prefs.getInt('permissionState') ?? 0; // Get stored permission state, defaulting to 0

    if (permissionState == 0) {
      // Request permissions if not granted
      // Example: Requesting notification permissions
      // Replace with actual permission handling code
      // For example, you might request notification permissions using firebase_messaging or local_notifications package
      // FirebaseMessaging.instance.requestPermission();

      // Store permission state as granted (1) once permissions are granted
      await prefs.setInt('permissionState', 1);
    }
  }

  Future<void> _revokeNotificationPermissions() async {
    try {
      await FirebaseMessaging.instance.deleteToken(); // Revoke notification token
      print('Notification permissions revoked successfully.');
    } catch (e) {
      print('Failed to revoke notification permissions: $e');
      // Handle error as needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            return LoginPage();
          } else {
            return HomeScreen();
          }
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}
