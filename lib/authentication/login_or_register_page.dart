import 'package:ccm/authentication/login_page.dart';
import 'package:ccm/authentication/register_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginOrRegisterPage extends StatefulWidget {
  const LoginOrRegisterPage({super.key});

  @override
  State<LoginOrRegisterPage> createState() => _LoginOrRegisterPageState();
}

class _LoginOrRegisterPageState extends State<LoginOrRegisterPage> {
  // Initially show login page at start
  bool showLoginPage = true;

  // Toggle between login and register page
  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if the user is already logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Redirect to the home page if user is already logged in
      Future.microtask(() {
        Navigator.of(context).pushReplacementNamed('/home_page');
      });
      return Scaffold(); // Return an empty scaffold while redirecting
    }

    if (showLoginPage) {
      return LoginPage(
        onTap: togglePages,
      );
    } else {
      return RegisterPage(
        onTap: togglePages,
      );
    }
  }
}
