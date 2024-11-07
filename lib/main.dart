import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pknu/screens/home_screen.dart';
import 'package:pknu/screens/chat_screen.dart';
import 'package:pknu/screens/profile_screen.dart';
import 'package:pknu/screens/welcome_screen.dart'; // Import the WelcomeScreen
import 'package:pknu/screens/login_screen.dart'; // Import the LoginScreen
import 'package:pknu/screens/registration_screen.dart'; // Import the RegistrationScreen
import 'package:pknu/screens/forgot_password_screen.dart';
import 'package:pknu/screens/map_screen.dart';
import 'screens/Initializer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF075E54),
        hintColor: const Color(0xFF128C7E),
      ),
      initialRoute: '/', // Start with the Initializer route
      routes: {
        '/': (context) => const Initializer(), // Initializer checks login state
        WelcomeScreen.id: (context) => const WelcomeScreen(),
        LoginScreen.id: (context) => const LoginScreen(),
        RegistrationScreen.id: (context) => const RegistrationScreen(),
        ChatScreen.id: (context) => const ChatScreen(
              friendEmail: '',
            ),
        Homescreen.id: (context) => const Homescreen(),
        ProfileScreen.id: (context) => const ProfileScreen(),
        ForgotPasswordScreen.id: (context) => const ForgotPasswordScreen(),
        MapPage.id: (context) => const MapPage(),
      },
    );
  }
}
