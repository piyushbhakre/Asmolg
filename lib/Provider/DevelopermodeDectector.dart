import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_exit_app/flutter_exit_app.dart';
import 'package:safe_device/safe_device.dart';

class DeveloperModeDetection with WidgetsBindingObserver {
  Timer? _developerModeCheckTimer;

  DeveloperModeDetection() {
    WidgetsBinding.instance.addObserver(this); // Add lifecycle observer
  }

  /// Public method to check Developer Mode and exit the app
  Future<void> checkDeveloperModeAndExit() async {
    await _checkDeveloperModeAndExit();
  }

  /// Starts a periodic check for Developer Mode
  void startDeveloperModeListener() {
    // Cancel any existing timer to avoid multiple listeners
    _developerModeCheckTimer?.cancel();

    // Start a new timer that checks every 5 seconds
    _developerModeCheckTimer = Timer.periodic(
      const Duration(seconds: 5),
          (Timer timer) async {
        await _checkDeveloperModeAndExit();
      },
    );
  }

  /// Stops the periodic Developer Mode check
  void stopDeveloperModeListener() {
    _developerModeCheckTimer?.cancel();
  }

  /// Private method to check Developer Mode and exit the app if true
  Future<void> _checkDeveloperModeAndExit() async {
    try {
      // Check Developer Mode status
      bool isDevelopmentModeEnabled = await SafeDevice.isDevelopmentModeEnable;

      if (isDevelopmentModeEnabled) {
        // Show a toast and exit the app if Developer Mode is enabled
        Fluttertoast.showToast(
          msg: "Disable developer mode and retry",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        // Exit the app
        Future.delayed(const Duration(seconds: 8)); // Wait to display the toast
        FlutterExitApp.exitApp();
      }
    } catch (e) {
      print("Error checking Developer Mode status: $e");
    }
  }

  /// Called when the app lifecycle state changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Restart the listener when the app is resumed
      startDeveloperModeListener();
    } else if (state == AppLifecycleState.paused) {
      // Optionally stop the listener when the app is paused
      stopDeveloperModeListener();
    }
  }

  /// Clean up resources
  void dispose() {
    stopDeveloperModeListener();
    WidgetsBinding.instance.removeObserver(this); // Remove lifecycle observer
  }
}
