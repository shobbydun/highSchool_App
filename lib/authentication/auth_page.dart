import 'package:ccm/database/firestore_services.dart';
import 'package:ccm/pages/main_pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_or_register_page.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasData) {
              final User? user = snapshot.data;
              if (user != null) {
                // Pass user.uid to FirestoreServices
                return HomePage(
                  firestoreServices: FirestoreServices(user.uid),
                );
              }
            }
            // User is not authenticated or snapshot does not have data
            return const LoginOrRegisterPage();
          }
          // While waiting for auth state changes
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
