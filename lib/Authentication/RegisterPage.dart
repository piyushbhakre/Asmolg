import 'dart:async';
import 'dart:ui';
import 'package:asmolg/Authentication/LoginScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_otp/email_otp.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class RegisterPage extends StatefulWidget {
  final String email;
  final String phone;

  RegisterPage({required this.email, required this.phone});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _collegeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repeatPasswordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _emailOtpController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  bool _isLoading = false;
  EmailOTP emailOTP = EmailOTP();
  bool _obscureTextPassword = true;
  bool _emailVerified = false;
  bool _isLoadingEmail = false;
  bool _showEmailOtpFields = false;
  bool _obscureTextRepeatPassword = true;
  Timer? _otpTimer;
  int _otpCooldown = 0;

  final RegExp passwordRegex = RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>])[a-zA-Z\d!@#$%^&*(),.?":{}|<>]{8,}$');
  final RegExp mobileRegex = RegExp(r'^\d{10}$');

  void _startOtpTimer() {
    _otpCooldown = 59;
    _otpTimer?.cancel();
    _otpTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_otpCooldown > 0) {
          _otpCooldown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _sendEmailOtp() async {
    if (_emailController.text.isEmpty) {
      CherryToast.error(
        title: Text("Error"),
        description: Text("Please enter your email."),
      ).show(context);
      return;
    }

    EmailOTP.config(
      appName: 'ASMOLG',
      otpType: OTPType.numeric,
      expiry: 300000, // OTP expires in 5 minutes
      appEmail: 'asmolgpvtltd@gmail.com', // Replace with your email
      emailTheme: EmailTheme.v6,
      otpLength: 6,
    );
    setState(() {
      _isLoadingEmail = true;
    });
    bool sent = await EmailOTP.sendOTP(email: _emailController.text);
    if (sent) {
      setState(() {
        _showEmailOtpFields = true;
        _isLoadingEmail = false;
      });
      _startOtpTimer();
      CherryToast.success(
        title: Text("OTP Sent"),
        description: Text("An OTP has been sent to your email."),
      ).show(context);
    } else {
      setState(() {
        _isLoadingEmail = false;
      });
      CherryToast.error(
        title: Text("Error"),
        description: Text("Failed to send OTP. Please try again."),
      ).show(context);
    }
  }

  Future<void> _verifyEmailOtp() async {
    if (_emailOtpController.text.isEmpty) {
      CherryToast.error(
        title: Text("Error"),
        description: Text("Please enter the OTP."),
      ).show(context);
      return;
    }

    setState(() {
      _isLoadingEmail = true;
    });

    bool isValid = EmailOTP.verifyOTP(otp: _emailOtpController.text);
    if (isValid) {
      setState(() {
        _emailVerified = true;
        _isLoadingEmail = false;
      });
      CherryToast.success(
        title: Text("Verified"),
        description: Text("Email verified successfully."),
      ).show(context);
    } else {
      setState(() {
        _isLoadingEmail = false;
      });
      CherryToast.error(
        title: Text("Error"),
        description: Text("Invalid OTP. Please try again."),
      ).show(context);
    }
  }

  void _register() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _repeatPasswordController.text.trim();
    String mobile = _mobileController.text.trim();

    // Email validation using regex
    final RegExp emailRegex = RegExp(
      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
    );

    if (_fullNameController.text.isEmpty ||
        _collegeController.text.isEmpty ||
        email.isEmpty ||
        mobile.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      CherryToast.error(
        title: Text("Error"),
        description: Text("All fields are mandatory."),
        animationDuration: Duration(milliseconds: 500),
      ).show(context);
      return;
    }

    if (!emailRegex.hasMatch(email)) {
      CherryToast.error(
        title: Text("Error"),
        description: Text("Please enter a valid email format."),
        animationDuration: Duration(milliseconds: 500),
      ).show(context);
      return;
    }

    if (!mobileRegex.hasMatch(mobile)) {
      CherryToast.error(
        title: Text("Error"),
        description: Text("Please enter a valid 10-digit mobile number."),
        animationDuration: Duration(milliseconds: 500),
      ).show(context);
      return;
    }

    if (password != confirmPassword) {
      CherryToast.error(
        title: Text("Error"),
        description: Text("Passwords do not match."),
        animationDuration: Duration(milliseconds: 500),
      ).show(context);
      return;
    }

    if (!passwordRegex.hasMatch(password)) {
      CherryToast.error(
        title: Text("Error"),
        description: Text("Password must be at least 8 characters, contain a letter, a number, and a special character."),
        animationDuration: Duration(milliseconds: 500),
      ).show(context);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create a user in Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Store additional details in Firestore
      await FirebaseFirestore.instance.collection('users').doc(email).set({
        'Email': email,
        'FullName': _fullNameController.text.trim(),
        'MobileNumber': mobile,
        'collegeOrUniversity': _collegeController.text.trim(),
      });

      CherryToast.success(
        title: Text("Registration Successful"),
        description: Text("Your account has been created successfully."),
        animationDuration: Duration(milliseconds: 500),
      ).show(context);

      // Navigate to the login screen or next screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
            (Route<dynamic> route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = '';
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          errorMessage = 'The account already exists for that email.';
          break;
        default:
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
      print('Error: $e');
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
                    Text("Email", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    if (!_emailVerified)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _emailController,
                              enabled: true,
                              decoration: InputDecoration(
                                labelText: "Enter your email",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.blueAccent),
                                ),
                                filled: true,
                                fillColor: Colors.blue[50],
                                prefixIcon: Icon(Icons.email, color: Colors.blue),
                              ),
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: (_otpCooldown > 0 || _isLoadingEmail) ? null : _sendEmailOtp,
                            child: _isLoadingEmail
                                ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : (_otpCooldown > 0
                                ? Text("SENT ($_otpCooldown s)")
                                : Text("Send OTP", style: TextStyle(color: Colors.white))),
                            style: ElevatedButton.styleFrom(
                              elevation: 4,
                              backgroundColor: _otpCooldown > 0 || _isLoadingEmail
                                  ? Colors.green
                                  : Colors.blue,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              minimumSize: Size(120, 50),
                            ),
                          ),
                        ],
                      ),
                    if (_emailVerified)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: TextField(
                          controller: _emailController,
                          enabled: false,
                          decoration: InputDecoration(
                            labelText: "Verified Email",
                            labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.greenAccent),
                            ),
                            filled: true,
                            fillColor: Colors.blue[50],
                            prefixIcon: Icon(Icons.email, size: 28, color: Colors.green),
                            suffixIcon: Icon(Icons.check_circle, color: Colors.green, size: 28),
                          ),
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    SizedBox(height: 16),
                    if (!_emailVerified && _showEmailOtpFields)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _emailOtpController,
                              decoration: InputDecoration(
                                labelText: "Enter OTP",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.blueAccent),
                                ),
                                filled: true,
                                fillColor: Colors.blue[50],
                                prefixIcon: Icon(Icons.lock, color: Colors.blue),
                              ),
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _isLoadingEmail ? null : _verifyEmailOtp,
                            child: _isLoadingEmail
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text("Verify", style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              elevation: 4,
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              minimumSize: Size(120, 50),
                            ),
                          ),
                        ],
                      ),
                    Divider(),
                    _buildLargerTextField(
                      controller: _fullNameController,
                      label: "Full Name",
                      hintText: "Enter your full name",
                    ),
                    SizedBox(height: 16),
                    _buildLargerTextField(
                      controller: _collegeController,
                      label: "College/University",
                      hintText: "",
                    ),
                    SizedBox(height: 16),
                    _buildLargerTextField(
                      controller: _mobileController,
                      label: "Mobile Number",
                      hintText: "Enter your 10-digit mobile number",
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildPasswordField(
                      controller: _passwordController,
                      label: "Password",
                      hintText: "Enter your password",
                      obscureText: _obscureTextPassword,
                      onToggle: () {
                        setState(() {
                          _obscureTextPassword = !_obscureTextPassword;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    _buildPasswordField(
                      controller: _repeatPasswordController,
                      label: "Repeat Password",
                      hintText: "Repeat your password",
                      obscureText: _obscureTextRepeatPassword,
                      onToggle: () {
                        setState(() {
                          _obscureTextRepeatPassword = !_obscureTextRepeatPassword;
                        });
                      },
                    ),
                    SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _emailVerified ? _register : null,
                        child: Text(
                          _emailVerified ? 'Register' : 'Verify Email First',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          elevation: 6,
                          backgroundColor: _emailVerified ? Colors.blue : Colors.grey,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
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
                child: LoadingAnimationWidget.staggeredDotsWave(
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildLargerTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  /// Helper to build a password field with toggle visibility.
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggle,
        ),
      ),
    );
  }
}