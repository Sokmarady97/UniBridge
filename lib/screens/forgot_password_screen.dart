import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pknu/constants.dart';

class ForgotPasswordScreen extends StatefulWidget {
  static const String id = 'forgot_password_screen';

  const ForgotPasswordScreen({super.key});

  @override
  ForgotPasswordScreenState createState() => ForgotPasswordScreenState();
}

class ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  late String emailOrStudentNumber;

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

  void _resetPassword() async {
    if (emailOrStudentNumber.isEmpty) {
      _showErrorDialog('Please enter your email or student number');
      return;
    }

    try {
      String resetEmail = emailOrStudentNumber;

      // Check if the input is a student number by checking if it contains only digits
      if (RegExp(r'^\d+$').hasMatch(emailOrStudentNumber)) {
        final fetchedEmail =
            await _getEmailFromStudentNumber(emailOrStudentNumber);
        if (fetchedEmail != null) {
          resetEmail = fetchedEmail;
        } else {
          throw Exception('No user found with this student number');
        }
      }

      await _auth.sendPasswordResetEmail(email: resetEmail);
      _showErrorDialog('Password reset email sent to $resetEmail');
    } catch (e) {
      print(e);
      _showErrorDialog('Failed to send password reset email');
    }
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
      appBar: AppBar(
        title: Text('Reset Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
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
              height: 24.0,
            ),
            ElevatedButton(
              onPressed: _resetPassword,
              child: Text('Send Password Reset Email'),
            ),
          ],
        ),
      ),
    );
  }
}
