import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:pknu/components/rounded_button.dart';
import 'package:pknu/constants.dart';
import 'package:pknu/screens/home_screen.dart';
import 'package:pknu/screens/forgot_password_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String emailOrStudentNumber = '';
  String password = '';
  bool rememberMe = false; // Track the "Remember Me" checkbox state

  var animationLink = 'images/login-bear.riv';
  SMITrigger? failTrigger, successTrigger;
  SMIBool? isHandsUp, isChecking;
  SMINumber? lookNum;
  StateMachineController? stateMachineController;
  Artboard? artboard;

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    rootBundle.load(animationLink).then((value) {
      final file = RiveFile.import(value);
      final art = file.mainArtboard;
      stateMachineController =
          StateMachineController.fromArtboard(art, "Login Machine");

      if (stateMachineController != null) {
        art.addController(stateMachineController!);

        stateMachineController!.inputs.forEach((element) {
          if (element.name == "isChecking") {
            isChecking = element as SMIBool;
          } else if (element.name == "isHandsUp") {
            isHandsUp = element as SMIBool;
          } else if (element.name == "trigSuccess") {
            successTrigger = element as SMITrigger;
          } else if (element.name == "trigFail") {
            failTrigger = element as SMITrigger;
          } else if (element.name == "numLook") {
            lookNum = element as SMINumber;
          }
        });
      }
      setState(() => artboard = art);
    });

    _loadRememberMe(); // Load saved preference for Remember Me
  }

  // Load Remember Me state and fill in email/password if applicable
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

  // Save Remember Me preference, email, and password
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

  void lookAround() {
    isChecking?.change(true);
    isHandsUp?.change(false);
    lookNum?.change(0);
  }

  void moveEyes(value) {
    lookNum?.change(value.length.toDouble());
  }

  void handsUpOnEyes() {
    isHandsUp?.change(true);
    isChecking?.change(false);
  }

  void loginClick() async {
    setState(() {
      showSpinner = true;
      isChecking?.change(false);
      isHandsUp?.change(false);
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
        successTrigger?.fire(); // Trigger success animation

        // Save Remember Me preference
        _saveRememberMe(rememberMe);

        Navigator.pushNamed(context, Homescreen.id);
      }
    } on FirebaseAuthException catch (e) {
      failTrigger?.fire(); // Trigger fail animation
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
      body: Stack(
        children: [
          // Fullscreen Rive animation at the top
          Container(
            height: MediaQuery.of(context).size.height,
            child: artboard != null
                ? Rive(
                    artboard: artboard!,
                    fit: BoxFit.cover, // Cover the entire available space
                  )
                : const SizedBox(), // Placeholder while animation is loading
          ),

          // Login form over the animation
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Email / Student Number Field
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      textAlign: TextAlign.left,
                      onChanged: (value) {
                        emailOrStudentNumber = value;
                        moveEyes(value);
                      },
                      onTap: lookAround,
                      decoration: kTextFieldDecoration.copyWith(
                        hintText: 'Enter your email or student number',
                        hintStyle: TextStyle(
                            color: Colors
                                .black), // Change hint text color to black
                      ),
                      style: TextStyle(
                          color:
                              Colors.black), // Change input text color to black
                    ),
                    const SizedBox(height: 8.0),

                    // Password Field
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      textAlign: TextAlign.left,
                      onChanged: (value) {
                        password = value;
                      },
                      onTap: handsUpOnEyes,
                      decoration: kTextFieldDecoration.copyWith(
                        hintText: 'Enter your password',
                        hintStyle: TextStyle(
                            color: Colors
                                .black), // Change hint text color to black
                      ),
                      style: TextStyle(
                          color:
                              Colors.black), // Change input text color to black
                    ),
                    const SizedBox(height: 8.0),

                    // Remember Me Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: rememberMe,
                          onChanged: (newValue) {
                            setState(() {
                              rememberMe = newValue ?? false;
                            });
                          },
                          activeColor: Colors
                              .white, // Change the box color when checked to white
                          checkColor: Colors
                              .black, // Change the checkmark color to black (optional)
                        ),
                        const Text(
                          'Remember Me',
                          style: TextStyle(
                            color:
                                Colors.white, // Change the text color to white
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24.0),

                    // Login Button
                    RoundedButton(
                      title: 'Login',
                      colour: Colors.lightBlueAccent,
                      onPressed: loginClick,
                    ),

                    // Forgot Password Button
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, ForgotPasswordScreen.id);
                      },
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                            color: Color.fromARGB(255, 255, 255,
                                255)), // Change Forgot Password text color to black
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
