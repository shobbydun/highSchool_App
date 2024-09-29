import 'package:ccm/components/my_textfield.dart';
import 'package:ccm/components/socialhub_components/my_drawer.dart';
import 'package:ccm/components/socialhub_components/my_post_button.dart';
import 'package:ccm/components/socialhub_components/search_delegate_widget.dart';
import 'package:ccm/database/socialhub_firestore.dart';
import 'package:ccm/pages/social_hub/user_profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'comments_page.dart';
import 'package:share_plus/share_plus.dart';

class SocialHubHomePage extends StatefulWidget {
  SocialHubHomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<SocialHubHomePage> {
  final FirestoreDatabase database = FirestoreDatabase();
  final TextEditingController newPostController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  void postMessage() {
    if (newPostController.text.isNotEmpty) {
      String message = newPostController.text;
      database.addPost(message);
      newPostController.clear();
    }
  }

  void sharePost(String message) {
    Share.share(message);
  }

  Future<void> _toggleLike(String postId, bool isLiked) async {
    final postDoc = FirebaseFirestore.instance.collection('Posts').doc(postId);
    final userEmail = FirebaseAuth.instance.currentUser?.email;

    if (userEmail == null) {
      print('User is not logged in');
      return;
    }

    try {
      if (isLiked) {
        await postDoc.update({
          'likes': FieldValue.arrayRemove([userEmail])
        });
      } else {
        await postDoc.update({
          'likes': FieldValue.arrayUnion([userEmail])
        });
      }
    } catch (e) {
      print('Error toggling like status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[100],
      appBar: AppBar(
        title: Text("CCM HUB"),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.secondary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate:
                    SearchDelegateWidget(searchController: searchController),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              // Handle notifications
            },
          ),
        ],
      ),
      drawer: MyDrawer(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stories section
          Container(
            height: 120,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection("users").snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final users = snapshot.data?.docs;

                if (users == null || users.isEmpty) {
                  return const Center(child: Text("No users found"));
                }

                final filteredUsers = users.where((user) {
                  final userData = user.data() as Map<String, dynamic>;
                  final username = userData['userName'] ?? '';
                  return username
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase());
                }).toList();

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final userDoc = filteredUsers[index];
                    final user = userDoc.data() as Map<String, dynamic>;
                    final userId = userDoc.id;
                    final username = user['userName'] ?? 'Unknown';
                    final profileImageUrl = user['profileImage'];

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                OtherProfilePage(userId: userId),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0),
                        width: 80,
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.green,
                                  width: 3,
                                ),
                              ),
                              child: CircleAvatar(
                                backgroundColor: Colors.grey[300],
                                backgroundImage: profileImageUrl != null
                                    ? NetworkImage(profileImageUrl)
                                    : null,
                                child: profileImageUrl == null
                                    ? Icon(Icons.person_3,
                                        size: 30, color: Colors.grey[600])
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              username,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Textfield for posting
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Expanded(
                  child: MyTextfield(
                    hintText: "What's on your mind?",
                    obscureText: false,
                    controller: newPostController,
                  ),
                ),
                const SizedBox(width: 5),
                MyPostButton(onTap: postMessage),
              ],
            ),
          ),

          // Posts
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: database.getPostsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final posts = snapshot.data?.docs;

                if (posts == null || posts.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(25),
                      child: Text("No posts.. Post Something"),
                    ),
                  );
                }

                final filteredPosts = posts.where((post) {
                  final postData = post.data() as Map<String, dynamic>;
                  final message = postData['PostMessage'] ?? '';
                  return message
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase());
                }).toList();

                final currentUser = FirebaseAuth.instance.currentUser;
                final currentUserEmail = currentUser?.email;

                if (currentUserEmail == null) {
                  // Handle the case where the user is not logged in
                  print('User is not logged in');
                  return Center(child: Text("Please log in to see posts."));
                }

                return ListView.builder(
                  itemCount: filteredPosts.length,
                  itemBuilder: (context, index) {
                    final post = filteredPosts[index];
                    final postId = post.id;
                    final message = post['PostMessage'];
                    final userEmail = post['UserEmail']
                        ?.toString()
                        .trim(); // Ensure no extra spaces
                    final timestamp = post['TimeStamp'] as Timestamp;
                    final likes = (post.data() as Map<String, dynamic>)
                            .containsKey('likes')
                        ? List<String>.from(post['likes'])
                        : [];
                    final commentsCount = (post.data() as Map<String, dynamic>)
                            .containsKey('commentsCount')
                        ? (post['commentsCount'] as int)
                        : 0;
                    final isLiked = likes.contains(currentUserEmail);
                    return Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.white70,
                        borderRadius: BorderRadius.circular(8.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey,
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Use Query to fetch user document based on email
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('users')
                                    .where('email', isEqualTo: userEmail)
                                    .snapshots(),
                                builder: (context, userSnapshot) {
                                  if (userSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.grey[300],
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  if (userSnapshot.hasError) {
                                    print(
                                        "Error fetching user data: ${userSnapshot.error}");
                                    return CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.grey[300],
                                      child: Icon(Icons.error,
                                          size: 20, color: Colors.red),
                                    );
                                  }

                                  if (!userSnapshot.hasData ||
                                      userSnapshot.data!.docs.isEmpty) {
                                    print(
                                        "User document does not exist for email: $userEmail");
                                    return CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.grey[300],
                                      child: Icon(Icons.person,
                                          size: 20, color: Colors.grey[600]),
                                    );
                                  }

                                  final user = userSnapshot.data!.docs.first
                                      .data() as Map<String, dynamic>?;
                                  final profileImageUrl = user?['profileImage'];

                                  return CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.grey[300],
                                    backgroundImage: profileImageUrl != null
                                        ? NetworkImage(profileImageUrl)
                                        : null,
                                    child: profileImageUrl == null
                                        ? Icon(Icons.person,
                                            size: 20, color: Colors.grey[600])
                                        : null,
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  userEmail ?? 'Unknown User',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _formatTimestamp(timestamp),
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(message),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isLiked ? Colors.red : null,
                                ),
                                onPressed: () => _toggleLike(postId, isLiked),
                              ),
                              Text('${likes.length}'),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: Icon(Icons.comment_outlined),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          CommentsPage(postId: postId),
                                    ),
                                  );
                                },
                              ),
                              Text('$commentsCount'),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: Icon(Icons.share_outlined),
                                onPressed: () {
                                  sharePost(message);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    return DateFormat('MMM d, yyyy - h:mm a').format(timestamp.toDate());
  }
}
