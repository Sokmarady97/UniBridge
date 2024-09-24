import 'package:flutter/material.dart';
import 'package:pknu/components/rounded_button.dart';
import 'package:pknu/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:pknu/screens/home_screen.dart';
import 'package:pknu/screens/forgot_password_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  static const String id = 'login_screen';

  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool showSpinner = false;
  String emailOrStudentNumber = ''; // Initialize with an empty string
  String password = ''; // Initialize with an empty string

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Flexible(
                child: Hero(
                  tag: 'logo',
                  child: Container(
                    height: 200.0,
                    child: Image.asset('images/pocus.png'),
                  ),
                ),
              ),
              SizedBox(
                height: 48.0,
              ),
              TextField(
                keyboardType: TextInputType.emailAddress,
                textAlign: TextAlign.left,
                onChanged: (value) {
                  emailOrStudentNumber = value;
                },
                decoration: kTextFieldDecoration.copyWith(
                  hintText: 'Enter your email or student number',
                ),
              ),
              SizedBox(
                height: 8.0,
              ),
              TextField(
                obscureText: true,
                textAlign: TextAlign.left,
                onChanged: (value) {
                  password = value;
                },
                decoration: kTextFieldDecoration.copyWith(
                  hintText: 'Enter your password',
                ),
              ),
              SizedBox(
                height: 24.0,
              ),
              RoundedButton(
                title: 'Login',
                colour: Colors.lightBlueAccent,
                onPressed: () async {
                  setState(() {
                    showSpinner = true;
                  });
                  try {
                    String loginEmail = emailOrStudentNumber;

                    // Check if the input is a student number by checking if it contains only digits
                    if (RegExp(r'^\d+$').hasMatch(emailOrStudentNumber)) {
                      final fetchedEmail = await _getEmailFromStudentNumber(
                          emailOrStudentNumber);
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
                      Navigator.pushNamed(context, Homescreen.id);
                    }
                    setState(() {
                      showSpinner = false;
                    });
                  } on FirebaseAuthException catch (e) {
                    String errorMessage = '';
                    if (e.code == 'user-not-found') {
                      errorMessage =
                          'No user found with this email or student number.';
                    } else if (e.code == 'wrong-password') {
                      errorMessage = 'Invalid password, please try again.';
                    } else {
                      errorMessage = 'An unknown error occurred.';
                    }
                    _showErrorDialog(errorMessage);
                    setState(() {
                      showSpinner = false;
                    });
                  } catch (e) {
                    print(e);
                    _showErrorDialog('An unknown error occurred.');
                    setState(() {
                      showSpinner = false;
                    });
                  }
                },
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, ForgotPasswordScreen.id);
                },
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(color: Colors.lightBlueAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
