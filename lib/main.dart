import 'package:ccm/authentication/auth_page.dart';
import 'package:ccm/authentication/login_or_register_page.dart';
import 'package:ccm/authentication/login_page.dart';
import 'package:ccm/authentication/register_page.dart';
import 'package:ccm/database/firestore_services.dart';
import 'package:ccm/pages/main_pages/classes_page.dart';
import 'package:ccm/pages/main_pages/events_announcements_page.dart';
import 'package:ccm/pages/main_pages/fees_page.dart';
import 'package:ccm/pages/main_pages/goals_counselling_page.dart';
import 'package:ccm/pages/main_pages/grades_targets_page.dart';
import 'package:ccm/pages/main_pages/main_user_profile_page.dart';
import 'package:ccm/pages/main_pages/notifications_reminders_page.dart';
import 'package:ccm/pages/social_hub/edit_profile_page.dart';
import 'package:ccm/pages/social_hub/social_hub_home_page.dart';
import 'package:ccm/pages/social_hub/user_profile_page.dart';
import 'package:ccm/pages/main_pages/home_page.dart';
import 'package:ccm/pages/social_hub/users_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

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
      home: const AuthPage(),
      routes: {
        '/login_register_page': (context) => const LoginOrRegisterPage(),
        '/home_page': (context) => HomePage(
              firestoreServices: _getFirestoreServices(context),
            ),
        '/register_page': (context) => RegisterPage(onTap: () {}),
        '/login_page': (context) => LoginPage(onTap: () {}),
        '/classes_page': (context) => ClassesPage(),
        '/events_announcement': (context) => EventsAnnouncementsPage(),
        '/fees_page': (context) => FeesPage(),
        '/goals_counselling': (context) => GoalsCounsellingPage(),
        '/grades_targets': (context) {
          final firestoreServices = _getFirestoreServices(context);
          return GradesTargetsPage(
            firestoreServices: firestoreServices,
            navigationSource: 'drawer',
          );
        },
        '/notifications_reminder_page': (context) => NotificationsRemindersPage(),
        '/user_profile_page': (context) => ProfilePage(),
        '/subject_selection_page': (context) => SubjectSelectionPage(
          firestoreServices: _getFirestoreServices(context),
        ),
        '/target_selection_page': (context) => TargetSelectionPage(
          firestoreServices: _getFirestoreServices(context),
          selectedSubjects: [],
        ),
        '/socialclub_page': (context) => SocialHubHomePage(),
        '/users_page': (context) => UsersPage(),
        '/edit_profile_page': (context) => EditProfilePage(),
        '/MainUserProfilePage': (context) => MainUserProfilePage(),
      },
    );
  }

  FirestoreServices _getFirestoreServices(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError("User is not authenticated");
    }
    return FirestoreServices(user.uid);
  }
}
