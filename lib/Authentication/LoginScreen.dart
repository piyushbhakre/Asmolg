import 'dart:ui';
import 'package:asmolg/Authentication/RegisterPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../MainScreeens/homepage.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _resetLoading = false; // Loading state for password reset
  bool _obscureTextPassword = true;
  String? _emailError;
  String? _passwordError;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    // Set the status bar color when the screen is initialized
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));
  }
  // Map Firebase error codes to user-friendly messages
  String _handleFirebaseError(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'Email is incorrect or not registered';
      case 'wrong-password':
        return 'Password is incorrect';
      case 'invalid-email':
        return 'The email address is not valid';
      default:
        return 'Login failed. Please try again';
    }
  }

  Future<void> _login() async {
    // Validate email and password fields
    setState(() {
      _emailError = _emailController.text.isEmpty ? "Please fill in the email" : null;
      _passwordError = _passwordController.text.isEmpty ? "Please fill in the password" : null;
    });

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;

    // Set loading state with mounted check
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Perform sign-in using Firebase Authentication
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Save email to SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String userEmail = _emailController.text.trim();
      await prefs.setString('userEmail', userEmail);

      // Show success message
      if (mounted) { // Ensure widget is still active
        CherryToast.success(
          title: Text("Login Successful 🎉"),
          description: Text("Enjoy our services 😃"),
          animationDuration: Duration(milliseconds: 500),
        ).show(context);
      }

      // Navigate to the home screen
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => HomeScreen()),
              (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      String errorMessage = 'Login failed. Please try again';
      if (e is FirebaseAuthException) {
        errorMessage = _handleFirebaseError(e.code);
      }

      // Show error message
      if (mounted) {
        CherryToast.error(
          title: Text("Login Error"),
          description: Text(errorMessage),
          animationDuration: Duration(milliseconds: 500),
        ).show(context);
      }
    } finally {
      // Reset loading state safely
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  Future<void> _resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);

      if (mounted) {
        CherryToast.success(
          title: Text("Success"),
          description: Text("Password reset email sent."),
          animationDuration: Duration(milliseconds: 500),
        ).show(context);
      }

      if (mounted) {
        Navigator.pop(context); // Close the bottom sheet
      }
    } catch (e) {
      String errorMessage = 'Failed to send reset email';
      if (e is FirebaseAuthException) {
        if (e.code == 'user-not-found') {
          errorMessage = 'Email does not exist in the database';
        }
      }

      if (mounted) {
        CherryToast.error(
          title: Text("Error"),
          description: Text(errorMessage),
          animationDuration: Duration(milliseconds: 500),
        ).show(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _resetLoading = false; // Reset loading state
        });
      }
    }
  }

  void _showForgotPasswordDialog() {
    String email = ""; // Local variable to store email input
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // This allows the modal to resize above the keyboard
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder( // Use StatefulBuilder to control modal's state
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom, // Padding above the keyboard
                left: 16.0,
                right: 16.0,
                top: 16.0,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Forgot Password",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        hintText: "Enter your email",
                        labelText: "Email",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                      onChanged: (value) {
                        email = value.trim(); // Update the email input
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Close the bottom sheet
                          },
                          child: const Text("Cancel"),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (email.isNotEmpty) {
                              setState(() {
                                _resetLoading = true;  // Show loading in the reset button
                              });
                              _resetPassword(email);  // Call password reset
                            } else {
                              CherryToast.error(
                                title: Text("Error"),
                                description: Text("Please enter a valid email."),
                                animationDuration: Duration(milliseconds: 500),
                              ).show(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                          child: _resetLoading
                              ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.0,
                            ),
                          )
                              : const Text("Reset"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Method to navigate to the registration page
  void _navigateToRegister() {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => RegisterPage(email: '', phone: '',),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const offset = Offset(-1.0, 0.0); // Slide transition from left to right
        var tween = Tween<Offset>(begin: offset, end: Offset.zero);
        var offsetAnimation = animation.drive(tween);
        return SlideTransition(position: offsetAnimation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Colors.white, // Set the back arrow color to white
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -15,
            left: 0,
            right: 0,
            child: Container(
              height: 280,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/asmolg-card.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(top: 100, left: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Welcome back',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 320, // Increase this value to add more space from the image
            left: 0,
            right: 0,
            bottom: 0,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.black), // Label text color set to blue
                  errorText: _emailError, // Show error next to email field
                  errorStyle: TextStyle(color: Colors.redAccent), // Error text color
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.black), // Default border color blue
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.black), // Blue border when enabled
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.black), // Blue border when focused
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.black), // Blue border when disabled
                  ),
                  prefixIcon: Icon(
                    Icons.email,
                    color: Colors.black, // Prefix icon color set to blue
                  ),
                ),
                cursorColor: Colors.black, // Cursor color set to blue
                keyboardType: TextInputType.emailAddress, // Ensures email-specific keyboard
                style: TextStyle(fontSize: 16), // Text style
                ),
                  SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscureTextPassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.black), // Label text color set to blue
                    errorText: _passwordError, // Show error next to password field
                    errorStyle: TextStyle(color: Colors.redAccent), // Error text color
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.black), // Default border color blue
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.black), // Blue border when enabled
                    ),
                    prefixIcon: Icon(
                      Icons.password,
                      color: Colors.black, // Prefix icon color set to blue
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.black), // Blue border when focused
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.black), // Blue border when disabled
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureTextPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.black, // Suffix icon color set to blue
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureTextPassword = !_obscureTextPassword;
                        });
                      },
                    ),
                  ),
                  cursorColor: Colors.black, // Cursor color set to blue
                ),

                SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        _showForgotPasswordDialog();
                      },
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  // "Don’t have an account? Register now" clickable text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don’t have an account? ", style: TextStyle(color: Colors.grey)),
                      GestureDetector(
                        onTap: _navigateToRegister,
                        child: Text(
                          "Register now",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
              ]
              ),
              ),
            ),
          if (_isLoading)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: LoadingAnimationWidget.staggeredDotsWave(
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