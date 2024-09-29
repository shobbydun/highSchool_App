import 'package:ccm/pages/social_hub/user_profile_page.dart';
import 'package:ccm/services/helper_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_updateSearchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateSearchQuery() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  String formatFollowersCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}m';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    } else {
      return count.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Users"),
        backgroundColor: Colors.pink[200],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by email or username',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixIcon: Icon(Icons.search),
              ),
            ),
          ),
        ),
      ),
      backgroundColor: Colors.pink[100],
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("users").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print("Error: ${snapshot.error}");
            displayMessageToUser("Something went wrong", context);
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No users found"));
          }

          final users = snapshot.data!.docs;
          final filteredUsers = users.where((userDoc) {
            final user = userDoc.data() as Map<String, dynamic>;
            final username = (user['userName'] ?? '').toLowerCase();
            final email = (user['email'] ?? '').toLowerCase();
            return username.contains(_searchQuery) || email.contains(_searchQuery);
          }).toList();

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(0),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final userDoc = filteredUsers[index];
                      final user = userDoc.data() as Map<String, dynamic>;
                      String userId = userDoc.id;
                      String username = user['userName'] ?? 'Unknown';
                      String email = user['email'] ?? 'No email';
                      String? profileImageUrl = user['profileImage'] as String?;
                      int followersCount = (user['followersCount'] ?? 0) as int;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OtherProfilePage(userId: userId),
                            ),
                          );
                        },
                        child: Card(
                          color: Colors.grey[300],
                          margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          elevation: 4,
                          child: ListTile(
                            contentPadding: EdgeInsets.all(12.0),
                            leading: CircleAvatar(
                              backgroundImage: profileImageUrl != null
                                  ? NetworkImage(profileImageUrl)
                                  : null,
                              child: profileImageUrl == null
                                  ? Icon(Icons.person, color: Colors.grey[600])
                                  : null,
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    email,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    username,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Text(
                              '.#${formatFollowersCount(followersCount)} Followers',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
