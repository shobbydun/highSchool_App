import 'package:ccm/authentication/login_or_register_page.dart';
import 'package:ccm/database/firestore_services.dart';
import 'package:ccm/pages/main_pages/goals_counselling_page.dart';
import 'package:ccm/pages/main_pages/grades_targets_page.dart';
import 'package:ccm/pages/social_hub/recent_chat_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DrawerContent extends StatefulWidget {
  final String userEmail;
  final FirestoreServices firestoreServices;

  const DrawerContent({
    Key? key,
    required this.userEmail,
    required this.firestoreServices,
  }) : super(key: key);

  @override
  _DrawerContentState createState() => _DrawerContentState();
}

class _DrawerContentState extends State<DrawerContent> {
  late Future<Map<String, String?>> _userInfoFuture;

  @override
  void initState() {
    super.initState();
    _userInfoFuture = _fetchUserInfo();
  }

  Future<Map<String, String?>> _fetchUserInfo() async {
    try {
      final profileImageUrl =
          await widget.firestoreServices.getProfileImageUrl(widget.userEmail);
      final userName =
          await widget.firestoreServices.getUsername(widget.userEmail);
      return {
        'profileImage': profileImageUrl,
        'userName': userName,
      };
    } catch (e) {
      print("Error fetching user info: $e");
      return {
        'profileImage': null,
        'userName': 'Default Name',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.pink[100],
      child: FutureBuilder<Map<String, String?>>(
        future: _userInfoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print("Error: ${snapshot.error}");
            return Center(child: Text('Error loading profile info'));
          }

          final data = snapshot.data ?? {};
          final profileImageUrl = data['profileImage'];
          final userName = data['userName']?.toUpperCase() ?? 'Default Name';

          final ImageProvider<Object>? imageProvider =
              profileImageUrl != null && profileImageUrl.isNotEmpty
                  ? (profileImageUrl.startsWith('http')
                      ? NetworkImage(profileImageUrl)
                      : AssetImage('assets/girlProfile.jpeg'))
                  : AssetImage('assets/girlProfile.jpeg');

          return ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.pink[200],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: imageProvider,
                    ),
                    SizedBox(height: 4),
                    Text(
                      userName,
                      style: TextStyle(
                        color: Colors.pink[800],
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(Icons.home),
                title: Text('Home'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacementNamed('/home_page');
                },
              ),
              ListTile(
                leading: Icon(Icons.library_books),
                title: Text('Grades'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => GradesTargetsPage(
                        firestoreServices: widget.firestoreServices,
                        navigationSource: 'drawer',
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.stars),
                title: Text('Goals'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) =>
                          GoalsCounsellingPage(showBackButton: true),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.attach_money),
                title: Text('Fees'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacementNamed('/fees_page');
                },
              ),
              ListTile(
                leading: Icon(Icons.school),
                title: Text('Classes'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacementNamed('/classes_page');
                },
              ),
              ListTile(
                leading: Icon(Icons.group),
                title: Text('Social Hub'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context)
                      .pushReplacementNamed('/socialclub_page');
                },
              ),
              ListTile(
                leading: Icon(Icons.message_sharp),
                title: Text('Messages'),
                onTap: () {
                  Navigator.of(context).pop();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecentChatsPage(),
                    ),
                  );
                },
              ),
              SizedBox(height: 120),
              ListTile(
                leading: Icon(Icons.exit_to_app),
                title: Text('Logout'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showLogoutConfirmation(context);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  String _generateChatRoomId(String userEmail1, String userEmail2) {
    final List<String> emails = [userEmail1, userEmail2]
      ..sort(); // Sort to ensure consistent ID
    return emails.join(
        '_'); // Join the sorted emails into a single string with a delimiter
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Logout'),
              onPressed: () {
                Navigator.of(context).pop();
                _performLogout();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout() async {
    try {
      // Sign out from Firebase Auth
      await FirebaseAuth.instance.signOut();
      print("User signed out from Firebase");

      // Clear shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print("Shared preferences cleared");

      // Redirect to login page and clear navigation stack
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginOrRegisterPage()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      print("Logout error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
      }
    }
  }
}
