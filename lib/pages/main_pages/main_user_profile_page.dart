import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MainUserProfilePage extends StatefulWidget {
  const MainUserProfilePage({Key? key}) : super(key: key);

  @override
  _MainUserProfilePageState createState() => _MainUserProfilePageState();
}

class _MainUserProfilePageState extends State<MainUserProfilePage> {
  Map<String, String> _userGrades = {};
  String _overallGrade = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final userData = userDoc.data();
      
      if (userData != null) {
        final userGrades = Map<String, String>.from(userData['personal_targets'] ?? {});
        setState(() {
          _userGrades = userGrades;
          _overallGrade = userGrades['overall'] ?? ''; // Assuming 'overall' is a key in your grades
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.pink[100],
      appBar: AppBar(
        title: Text('My Profile'),
        backgroundColor: Colors.pink[200],
      ),
      body: FutureBuilder(
        future: FirebaseFirestore.instance.collection("users").doc(userId).get(),
        builder: (context, AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (snapshot.hasData && snapshot.data!.exists) {
            final user = snapshot.data!.data();
            final userEmail = user?['email'] ?? '';
            final profileImageUrl = user?['profileImage'];

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 25),
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    backgroundImage: profileImageUrl != null
                        ? NetworkImage(profileImageUrl)
                        : null,
                    child: profileImageUrl == null
                        ? Icon(
                            Icons.person,
                            size: 64,
                            color: Theme.of(context).colorScheme.onPrimary,
                          )
                        : null,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    user?['userName'] ?? 'No Username',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    userEmail,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 7),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      user?['bio'] ?? 'No bio available',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(right:272),
                    
                    child: Text(
                      'My Targets:',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.pink[800],
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      ..._userGrades.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                entry.key,
                                style: TextStyle(fontSize: 16.0,
                                color: Colors.black),
                              ),
                              const SizedBox(width:9,),
                              Text(
                                entry.value.isNotEmpty ? entry.value : 'Not set',
                                style: TextStyle(fontSize: 18.0),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      if (_overallGrade.isNotEmpty) ...[
                        SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            const SizedBox(width: 5,),
                            Text(
                              'Overall Grade',
                              style: TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.pink[800],
                              ),
                            ),
                            const SizedBox(width: 5,),
                            Text(
                              _overallGrade.isNotEmpty ? _overallGrade : 'Not set',
                              style: TextStyle(
                                fontSize: 24.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.pink[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          } else {
            return const Center(child: Text("No data❌"));
          }
        },
      ),
    );
  }
}
