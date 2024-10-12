import 'package:asmolg/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'LoginPage.dart';
import 'LoginScreen.dart';
import 'homepage.dart';



class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // Listen for auth state changes
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            return LoginPage(); // Show login screen if user is not logged in
          } else {
            return HomeScreen(); // Navigate to HomeScreen if logged in
          }
        }
        // Show loading screen while waiting for authentication state
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}
