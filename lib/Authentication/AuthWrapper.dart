import 'package:asmolg/Authentication/LoginPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart' as package_info_plus;
import 'package:flutter_upgrade_version/flutter_upgrade_version.dart';
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
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Icon(Icons.update, color: Colors.blue, size: 28),
              const SizedBox(width: 8),
              const Text(
                "Update Required",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
          content: const Text(
            "A new version of the app is available. Please update to continue.",
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          actions: [
            Container(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _startUpdate,
                child: const Text(
                  "Update Now",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
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
