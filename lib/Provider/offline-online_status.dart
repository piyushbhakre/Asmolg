import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class OfflineBannerController extends GetxController {
  RxBool isOnline = true.obs; // Tracks internet status
  RxBool showBanner = false.obs; // Controls banner visibility

  @override
  void onInit() {
    super.onInit();
    _checkInternetConnection();
    _listenToConnectivity();
  }

  // Initial connectivity check
  void _checkInternetConnection() async {
    bool hasConnection = await InternetConnectionChecker().hasConnection;
    _updateConnectionStatus(hasConnection);
  }

  // Listen for network changes
  void _listenToConnectivity() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) async {
      bool hasConnection = await InternetConnectionChecker().hasConnection;
      _updateConnectionStatus(hasConnection);
    });
  }

  // Update connection status and banner visibility
  void _updateConnectionStatus(bool connected) {
    if (!connected) {
      // Show offline banner immediately
      showBanner.value = true;
      isOnline.value = false;
    } else if (!isOnline.value) {
      // Show online banner briefly, then fade out
      isOnline.value = true;
      Future.delayed(Duration(milliseconds: 200), () {
        showBanner.value = true;
      });
      Future.delayed(Duration(seconds: 2), () {
        showBanner.value = false;
      });
    }
  }
}

// Reusable Offline Banner Widget
class OfflineBanner extends StatelessWidget implements PreferredSizeWidget {
  final double height;

  OfflineBanner({this.height = 24.0}); // Default banner height

  @override
  Widget build(BuildContext context) {
    final OfflineBannerController controller = Get.put(OfflineBannerController());

    return Obx(
          () => AnimatedOpacity(
        opacity: controller.showBanner.value ? 1.0 : 0.0,
        duration: Duration(milliseconds: 500), // Smooth fade animation
        child: Container(
          height: controller.showBanner.value ? height : 0.0,
          width: double.infinity,
          color: controller.isOnline.value ? Colors.green : Colors.red,
          alignment: Alignment.center,
          child: Text(
            controller.isOnline.value ? 'ONLINE' : 'OFFLINE',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
