import 'package:ccm/pages/social_hub/recent_chat_page.dart'; // Import the ChatPage
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({super.key});

  @override
  _MyDrawerState createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  // Logout user
  void logout() async {
    // Show confirmation dialog
    bool? confirmLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Logout'),
          content: Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Logout'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    // If user confirmed logout
    if (confirmLogout == true) {
      try {
        await FirebaseAuth.instance.signOut();

        if (mounted) {
          // Navigate to login/register page and clear stack
          Navigator.of(context).pushNamedAndRemoveUntil(
              '/login_register_page', (route) => false);
        }
      } catch (e) {
        print('Error during sign out: $e');
        // Optionally, show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.pink[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              // Drawer header
              DrawerHeader(
                child: Icon(
                  Icons.connect_without_contact,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 80,
                ),
              ),
              const SizedBox(height: 25),

              // Home tile
              Padding(
                padding: const EdgeInsets.only(left: 25.0),
                child: ListTile(
                  leading: Icon(
                    Icons.home,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  title: Text("H O M E"),
                  onTap: () {
                    // Pop drawer
                    Navigator.pop(context);
                    // Navigate to home page
                    Navigator.pushNamed(context, '/socialclub_page');
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Profile tile
              Padding(
                padding: const EdgeInsets.only(left: 25.0),
                child: ListTile(
                  leading: Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  title: const Text("P R O F I L E"),
                  onTap: () async {
                    // Pop drawer
                    Navigator.pop(context);

                    // Fetch current user email
                    final User? currentUser = FirebaseAuth.instance.currentUser;
                    if (currentUser != null && currentUser.email != null) {
                      // Navigate to profile page
                      Navigator.pushNamed(
                        context,
                        '/user_profile_page',
                        arguments: currentUser.email!,
                      );
                    } else {
                      // Handle case where user is not logged in or email is null
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('No user is currently logged in')),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Users tile
              Padding(
                padding: const EdgeInsets.only(left: 25.0),
                child: ListTile(
                  leading: Icon(
                    Icons.group,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  title: const Text("U S E R S"),
                  onTap: () {
                    // Pop drawer
                    Navigator.pop(context);
                    // Navigate to users page
                    Navigator.pushNamed(context, '/users_page');
                  },
                ),
              ),

              // Chat page tile
              Padding(
                padding: const EdgeInsets.only(left: 25.0),
                child: ListTile(
                  leading: Icon(
                    Icons.inbox,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  title: const Text("I N B O X"),
                  onTap: () {
                    // Pop drawer
                    Navigator.pop(context);
                    // Navigate to chat page with required arguments
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecentChatsPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/home_page');
              },
              child: Text("Go to Main Page"),
            ),
          ),
        ],
      ),
    );
  }
}
