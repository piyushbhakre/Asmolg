import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class ExpiredSubjectsController extends GetxController {
  /// Delete expired subjects for the logged-in user.
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
              bool expired = _isExpired(purchaseDate, globalExpiryDays);
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

  /// Check if a subject is expired based on the purchase date and expiry days.
  bool _isExpired(DateTime purchaseDate, int expiryDays) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime expiryDate = purchaseDate.add(Duration(days: expiryDays));
    DateTime expiryStartDate = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);

    return expiryStartDate.isBefore(today) || expiryStartDate.isAtSameMomentAs(today);
  }
}
