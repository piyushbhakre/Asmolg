import 'dart:ui';
import 'package:asmolg/Authentication/LoginScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart'; // For loading animation

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _collegeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repeatPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureTextPassword = true;
  bool _obscureTextRepeatPassword = true;

  // Email Regex pattern
  final RegExp emailRegex = RegExp(r'^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$');
  final RegExp passwordRegex = RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)[a-zA-Z\d]{8,}$'); // Alpha-numeric password

  // Check if all required fields are filled
  bool _areFieldsValid() {
    if (_fullNameController.text.isEmpty || _emailController.text.isEmpty || _phoneController.text.isEmpty || _collegeController.text.isEmpty || _passwordController.text.isEmpty || _repeatPasswordController.text.isEmpty) {
      return false;
    }
    return true;
  }

  // Validate phone number (only digits allowed)
  bool _isPhoneNumberValid() {
    return _phoneController.text.isNotEmpty && _phoneController.text.length == 10 && RegExp(r'^[0-9]+$').hasMatch(_phoneController.text);
  }

  // Validate password
  bool _isPasswordValid() {
    return passwordRegex.hasMatch(_passwordController.text);
  }

  Future<void> _register() async {
    if (!_areFieldsValid()) {
      CherryToast.error(
        title: Text("Error"),
        description: Text("All fields are required."),
        animationDuration: Duration(milliseconds: 500),
      ).show(context);
      return;
    }

    if (!_isPhoneNumberValid()) {
      CherryToast.error(
        title: Text("Error"),
        description: Text("Please enter a valid 10-digit phone number."),
        animationDuration: Duration(milliseconds: 500),
      ).show(context);
      return;
    }

    if (!_isPasswordValid()) {
      CherryToast.error(
        title: Text("Error"),
        description: Text("Password must be at least 8 characters and alphanumeric."),
        animationDuration: Duration(milliseconds: 500),
      ).show(context);
      return;
    }

    if (_passwordController.text != _repeatPasswordController.text) {
      CherryToast.error(
        title: Text("Error"),
        description: Text("Passwords do not match."),
        animationDuration: Duration(milliseconds: 500),
      ).show(context);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create user with Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // After successful registration, save additional user info in Firestore
      await FirebaseFirestore.instance.collection('users').doc(_emailController.text).set({
        'FullName': _fullNameController.text,
        'Email': _emailController.text,
        'MobileNumber': _phoneController.text,
        'college/University': _collegeController.text,
      });

      // Show success dialog
      CherryToast.success(
        title: Text("Registration Successful"),
        description: Text("Your account has been created successfully."),
        animationDuration: Duration(milliseconds: 500),
      ).show(context);

      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
              (Route<dynamic> route) => false
      );


    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'The account already exists for that email.';
      } else {
        errorMessage = 'Registration failed. Please try again.';
      }

      CherryToast.error(
        title: Text("Registration Failed"),
        description: Text(errorMessage),
        animationDuration: Duration(milliseconds: 500),
      ).show(context);
    } catch (e) {
      CherryToast.error(
        title: Text("Server Error"),
        description: Text("The server is down. Please try again later."),
        animationDuration: Duration(milliseconds: 500),
      ).show(context);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.black,
    ));

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: SizedBox(),
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_forward, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: -15,
            left: 0,
            right: 0,
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/asmolg-card.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(30, 180, 0, 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Register',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Create your account',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 260,
            left: 0,
            right: 0,
            bottom: 0,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _fullNameController,
                    decoration: InputDecoration(
                      hintText: 'Full Name',
                      labelText: 'Full Name',
                      labelStyle: TextStyle(color: Colors.black54),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: 'Email',
                      labelText: 'Email',
                      labelStyle: TextStyle(color: Colors.black54),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Phone Number',
                      labelText: 'Phone Number',
                      labelStyle: TextStyle(color: Colors.black54),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _collegeController,
                    decoration: InputDecoration(
                      hintText: 'College/University',
                      labelText: 'College/University',
                      labelStyle: TextStyle(color: Colors.black54),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscureTextPassword,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      labelText: 'Password',
                      labelStyle: TextStyle(color: Colors.black54),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureTextPassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureTextPassword = !_obscureTextPassword; // Toggle visibility
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _repeatPasswordController,
                    obscureText: _obscureTextRepeatPassword,
                    decoration: InputDecoration(
                      hintText: 'Repeat Password',
                      labelText: 'Repeat Password',
                      labelStyle: TextStyle(color: Colors.black54),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureTextRepeatPassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureTextRepeatPassword = !_obscureTextRepeatPassword; // Toggle visibility
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Register',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
          if (_isLoading)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: LoadingAnimationWidget.halfTriangleDot(
                    color: Colors.black,
                    size: 50,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
