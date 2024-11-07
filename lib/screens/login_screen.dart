import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:pknu/components/rounded_button.dart';
import 'package:pknu/constants.dart';
import 'package:pknu/screens/home_screen.dart';
import 'package:pknu/screens/forgot_password_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class LoginScreen extends StatefulWidget {
  static const String id = 'login_screen';

  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool showSpinner = false;
  String emailOrStudentNumber = '';
  String password = '';
  bool rememberMe = false;

  late AnimationController controller;
  late Animation<Color?> animation;

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRememberMe();

    controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Both begin and end colors are set to white for a static white background
    animation =
        ColorTween(begin: Colors.white, end: Colors.white).animate(controller);

    controller.forward();

    controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _loadRememberMe() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      rememberMe = prefs.getBool('rememberMe') ?? false;
      if (rememberMe) {
        emailController.text = prefs.getString('email') ?? '';
        passwordController.text = prefs.getString('password') ?? '';
        emailOrStudentNumber = emailController.text;
        password = passwordController.text;
      }
    });
  }

  Future<void> _saveRememberMe(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('rememberMe', value);
    if (value) {
      prefs.setString('email', emailOrStudentNumber);
      prefs.setString('password', password);
    } else {
      prefs.remove('email');
      prefs.remove('password');
    }
  }

  Future<String?> _getEmailFromStudentNumber(String studentNumber) async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('studentNumber', isEqualTo: studentNumber)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first['email'];
    }
    return null;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void loginClick() async {
    setState(() {
      showSpinner = true;
    });

    try {
      String loginEmail = emailOrStudentNumber;

      if (RegExp(r'^\d+$').hasMatch(emailOrStudentNumber)) {
        final fetchedEmail =
            await _getEmailFromStudentNumber(emailOrStudentNumber);
        if (fetchedEmail != null) {
          loginEmail = fetchedEmail;
        } else {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'No user found with this student number',
          );
        }
      }

      final user = await _auth.signInWithEmailAndPassword(
          email: loginEmail, password: password);

      if (user != null) {
        _saveRememberMe(rememberMe);

        // Save login status to SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);

        Navigator.pushNamed(context, Homescreen.id);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = '';
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found with this email or student number.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Invalid password, please try again.';
      } else {
        errorMessage = 'An unknown error occurred.';
      }
      _showErrorDialog(errorMessage);
    } finally {
      setState(() {
        showSpinner = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: animation.value,
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                  height: 80.0), // Adjust this height to move content down
              Flexible(
                child: AnimatedTextKit(
                  animatedTexts: [
                    TypewriterAnimatedText(
                      'UniBridge',
                      textStyle: TextStyle(
                        fontSize: 32.0,
                        fontWeight: FontWeight.w900,
                        color: const Color.fromARGB(
                            255, 0, 0, 0), // Customize color
                      ),
                      speed: const Duration(milliseconds: 50),
                    ),
                  ],
                  totalRepeatCount: 1, // Only animate once
                  isRepeatingAnimation: false, // Don't loop
                ),
              ),
              const SizedBox(height: 24.0),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textAlign: TextAlign.left,
                onChanged: (value) {
                  emailOrStudentNumber = value;
                },
                decoration: kTextFieldDecoration.copyWith(
                  hintText: 'Enter your email or student number',
                  hintStyle: TextStyle(color: Colors.black),
                ),
                style: TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 8.0),
              TextField(
                controller: passwordController,
                obscureText: true,
                textAlign: TextAlign.left,
                onChanged: (value) {
                  password = value;
                },
                decoration: kTextFieldDecoration.copyWith(
                  hintText: 'Enter your password',
                  hintStyle: TextStyle(color: Colors.black),
                ),
                style: TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Checkbox(
                    value: rememberMe,
                    onChanged: (newValue) {
                      setState(() {
                        rememberMe = newValue ?? false;
                      });
                    },
                    activeColor: Colors.white,
                    checkColor: Colors.black,
                  ),
                  const Text(
                    'Remember Me',
                    style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                  ),
                ],
              ),
              const SizedBox(height: 24.0),
              RoundedButton(
                title: 'Login',
                colour: Colors.lightBlueAccent,
                onPressed: loginClick,
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, ForgotPasswordScreen.id);
                },
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
