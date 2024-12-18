import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserController extends GetxController {
  final Rx<User?> user = Rx<User?>(FirebaseAuth.instance.currentUser);
  RxString phone = ''.obs;
  RxString fullName = ''.obs;
  RxString email = ''.obs;
  RxBool isLoading = true.obs;

  UserController() {
    _initializeUser();
  }

  void _initializeUser() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.email != null) {
      fetchUserDetailsFromFirestore(currentUser.email!);
    } else {
      email.value = 'No email';
      fullName.value = 'No full name';
      phone.value = 'No phone number';
    }
  }

  Future<void> fetchUserDetailsFromFirestore(String authEmail) async {
    isLoading.value = true;
    try {

      final DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(authEmail)
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;

        fullName.value = data['FullName'] ?? 'No full name';
        phone.value = data['MobileNumber'] ?? 'No phone number';
        email.value = data['Email'] ?? authEmail;
      } else {
        fullName.value = 'No full name';
        phone.value = 'No phone number';
        email.value = 'No email';
      }
    } catch (e) {
      print("Error fetching user details from Firestore: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
