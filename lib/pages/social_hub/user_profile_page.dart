import 'package:ccm/pages/social_hub/messages_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatelessWidget {
  ProfilePage({super.key});

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserDetails(String userId) {
    print('Fetching user details for userId: $userId');
    return FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserPosts(String userEmail) {
    print('Fetching posts for email: $userEmail');
    return FirebaseFirestore.instance
        .collection("Posts")
        .where('UserEmail', isEqualTo: userEmail)
        .orderBy('TimeStamp', descending: true)
        .snapshots();
  }

  Future<void> _followUser(String userIdToFollow) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final currentUserId = currentUser.uid;

    final userDoc =
        FirebaseFirestore.instance.collection("users").doc(currentUserId);
    final userToFollowDoc =
        FirebaseFirestore.instance.collection("users").doc(userIdToFollow);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userDoc);
      final userToFollowSnapshot = await transaction.get(userToFollowDoc);

      final currentUserFollowing =
          List<String>.from(userSnapshot.get('following') ?? []);
      final userToFollowFollowers =
          List<String>.from(userToFollowSnapshot.get('followers') ?? []);

      if (!currentUserFollowing.contains(userIdToFollow)) {
        currentUserFollowing.add(userIdToFollow);
        userToFollowFollowers.add(currentUserId);

        transaction.update(userDoc, {
          'following': currentUserFollowing,
          'followingCount': FieldValue.increment(1),
        });

        transaction.update(userToFollowDoc, {
          'followers': userToFollowFollowers,
          'followersCount': FieldValue.increment(1),
        });
      }
    });
  }

  Future<void> _unfollowUser(String userIdToUnfollow) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final currentUserId = currentUser.uid;

    final userDoc =
        FirebaseFirestore.instance.collection("users").doc(currentUserId);
    final userToUnfollowDoc =
        FirebaseFirestore.instance.collection("users").doc(userIdToUnfollow);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userDoc);
      final userToUnfollowSnapshot = await transaction.get(userToUnfollowDoc);

      final currentUserFollowing =
          List<String>.from(userSnapshot.get('following') ?? []);
      final userToUnfollowFollowers =
          List<String>.from(userToUnfollowSnapshot.get('followers') ?? []);

      if (currentUserFollowing.contains(userIdToUnfollow)) {
        currentUserFollowing.remove(userIdToUnfollow);
        userToUnfollowFollowers.remove(currentUserId);

        transaction.update(userDoc, {
          'following': currentUserFollowing,
          'followingCount': FieldValue.increment(-1),
        });

        transaction.update(userToUnfollowDoc, {
          'followers': userToUnfollowFollowers,
          'followersCount': FieldValue.increment(-1),
        });
      }
    });
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
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: getUserDetails(userId),
        builder: (context, snapshot) {
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
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn(
                          'followers',
                          (user?['followersCount'] ?? 0) as int,
                        ),
                        _buildStatColumn(
                          'following',
                          (user?['followingCount'] ?? 0) as int,
                        ),
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: getUserPosts(userEmail),
                          builder: (context, postSnapshot) {
                            if (postSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }

                            if (postSnapshot.hasError) {
                              return Center(
                                  child: Text("Error: ${postSnapshot.error}"));
                            }

                            final postCount = postSnapshot.hasData
                                ? postSnapshot.data!.docs.length
                                : 0;

                            return _buildStatColumn(
                              'Posts',
                              postCount,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/edit_profile_page');
                      },
                      child: const Text('Edit Profile'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent Posts:',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 1),
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: getUserPosts(userEmail),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }

                            if (snapshot.hasError) {
                              return Center(
                                  child: Text("Error: ${snapshot.error}"));
                            }

                            final posts = snapshot.data?.docs;

                            if (posts == null || posts.isEmpty) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(25),
                                  child: Text("No posts yet"),
                                ),
                              );
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: posts.length,
                              itemBuilder: (context, index) {
                                final post = posts[index];
                                final data = post.data();
                                String message = data['PostMessage'] ?? '';
                                Timestamp timestamp = data['TimeStamp'];
                                List<String> likes =
                                    List<String>.from(data['likes'] ?? []);
                                bool isLiked = likes.contains(userEmail);

                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 7.0),
                                  child: Card(
                                    color: Colors.white70,
                                    elevation: 5,
                                    shadowColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.all(16.0),
                                      title: Text(
                                        message,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            DateFormat('MMM d, yyyy - h:mm a')
                                                .format(timestamp.toDate()),
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: Icon(
                                                  isLiked
                                                      ? Icons.favorite
                                                      : Icons.favorite_border,
                                                  color: isLiked
                                                      ? Colors.redAccent
                                                      : null,
                                                ),
                                                onPressed: () async {
                                                  await _toggleLike(
                                                      post.id, isLiked);
                                                },
                                              ),
                                              Text(
                                                '${likes.length} likes',
                                                style: TextStyle(
                                                  color: Colors.grey[700],
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      trailing: PopupMenuButton<String>(
                                        onSelected: (value) async {
                                          if (value == 'delete') {
                                            bool confirm =
                                                await _confirmDelete(context);
                                            if (confirm) {
                                              await FirebaseFirestore.instance
                                                  .collection("Posts")
                                                  .doc(post.id)
                                                  .delete();
                                            }
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          PopupMenuItem<String>(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete,
                                                    color: Colors.red),
                                                const SizedBox(width: 8),
                                                Text('Delete'),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
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

  Widget _buildStatColumn(String label, int count) {
    return Column(
      children: [
        Text(
          _formatNumber(count),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M'; // For millions
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k'; // For thousands
    } else {
      return number.toString(); // For numbers less than 1000
    }
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Delete Post"),
            content: const Text("Are you sure you want to delete this post?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Delete"),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _toggleLike(String postId, bool isLiked) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final userEmail = currentUser.email;

    final postDoc = FirebaseFirestore.instance.collection("Posts").doc(postId);

    if (isLiked) {
      // If currently liked, remove the like
      await postDoc.update({
        'likes': FieldValue.arrayRemove([userEmail])
      });
    } else {
      // If not liked, add the like
      await postDoc.update({
        'likes': FieldValue.arrayUnion([userEmail])
      });
    }
  }
}


class OtherProfilePage extends StatefulWidget {
  final String userId;

  OtherProfilePage({super.key, required this.userId});

  @override
  _OtherProfilePageState createState() => _OtherProfilePageState();
}

class _OtherProfilePageState extends State<OtherProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String _currentUserEmail;
  late String _currentUserId;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser!.uid;
    _currentUserEmail = _auth.currentUser!.email!;
    if (widget.userId.isNotEmpty) {
      _checkIfFollowing();
    } else {
      print('Error: userId is empty.');
    }
  }

  Future<void> _checkIfFollowing() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      if (!userDoc.exists) {
        print('User does not exist.');
        return;
      }

      final userFollowers =
          List<String>.from(userDoc.data()?['followers'] ?? []);
      setState(() {
        _isFollowing = userFollowers.contains(_currentUserEmail);
      });
    } catch (e) {
      print('Error checking follow status: $e');
    }
  }

  Future<void> _toggleFollow() async {
    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(_currentUserId);
    final followingDoc =
        FirebaseFirestore.instance.collection('users').doc(widget.userId);

    try {
      if (_isFollowing) {
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final userSnapshot = await transaction.get(userDoc);
          final followingSnapshot = await transaction.get(followingDoc);

          List<String> userFollowing =
              List<String>.from(userSnapshot.data()?['following'] ?? []);
          List<String> userFollowers =
              List<String>.from(followingSnapshot.data()?['followers'] ?? []);

          if (userFollowing.contains(widget.userId)) {
            userFollowing.remove(widget.userId);
            userFollowers.remove(_currentUserEmail);

            transaction.update(userDoc, {
              'following': userFollowing,
              'followingCount': FieldValue.increment(-1),
            });

            transaction.update(followingDoc, {
              'followers': userFollowers,
              'followersCount': FieldValue.increment(-1),
            });
          }
        });
      } else {
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final userSnapshot = await transaction.get(userDoc);
          final followingSnapshot = await transaction.get(followingDoc);

          List<String> userFollowing =
              List<String>.from(userSnapshot.data()?['following'] ?? []);
          List<String> userFollowers =
              List<String>.from(followingSnapshot.data()?['followers'] ?? []);

          if (!userFollowing.contains(widget.userId)) {
            userFollowing.add(widget.userId);
            userFollowers.add(_currentUserEmail);

            transaction.update(userDoc, {
              'following': userFollowing,
              'followingCount': FieldValue.increment(1),
            });

            transaction.update(followingDoc, {
              'followers': userFollowers,
              'followersCount': FieldValue.increment(1),
            });
          }
        });
      }
      setState(() {
        _isFollowing = !_isFollowing;
      });
    } catch (e) {
      print('Error toggling follow status: $e');
    }
  }

  Future<void> _toggleLike(String postId, bool isLiked) async {
    final postDoc = FirebaseFirestore.instance.collection('Posts').doc(postId);

    try {
      if (isLiked) {
        await postDoc.update({
          'likes': FieldValue.arrayRemove([_currentUserEmail])
        });
      } else {
        await postDoc.update({
          'likes': FieldValue.arrayUnion([_currentUserEmail])
        });
      }
    } catch (e) {
      print('Error toggling like status: $e');
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserDetails(String userId) {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserPosts(String userEmail) {
    return FirebaseFirestore.instance
        .collection("Posts")
        .where('UserEmail', isEqualTo: userEmail)
        .orderBy('TimeStamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Error'),
          backgroundColor: Colors.pink[200],
        ),
        body: Center(
          child: Text(
            'Invalid User ID',
            style: TextStyle(fontSize: 24, color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.pink[100],
      appBar: AppBar(
        title: Text('User Profile'),
        backgroundColor: Colors.pink[200],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: getUserDetails(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (snapshot.hasData && snapshot.data!.exists) {
            final user = snapshot.data!.data();
            final userEmail = user?['email'] ?? '';
            final profileImageUrl = user?['profileImage'];
            final recipientUserId = widget.userId; // Get recipientUserId

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
                  const SizedBox(height: 20),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn(
                          'Followers',
                          (user?['followersCount'] ?? 0) as int,
                        ),
                        _buildStatColumn(
                          'Following',
                          (user?['followingCount'] ?? 0) as int,
                        ),
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: getUserPosts(userEmail),
                          builder: (context, postSnapshot) {
                            if (postSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }

                            if (postSnapshot.hasError) {
                              return Center(
                                  child: Text("Error: ${postSnapshot.error}"));
                            }

                            final postCount = postSnapshot.hasData
                                ? postSnapshot.data!.docs.length
                                : 0;

                            return _buildStatColumn(
                              'Posts',
                              postCount,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _toggleFollow,
                    child: Text(
                      _isFollowing ? 'Unfollow' : 'Follow',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFollowing ? Colors.red : Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      String chatRoomId = _generateChatRoomId(_currentUserEmail, userEmail);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MessagesPage(
                            chatRoomId: chatRoomId,
                            recipientEmail: userEmail,
                            recipientUserId: recipientUserId, // Pass recipientUserId
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'Send Message',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent Posts:',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 10),
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: getUserPosts(userEmail),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }

                            if (snapshot.hasError) {
                              return Center(
                                  child: Text("Error: ${snapshot.error}"));
                            }

                            final posts = snapshot.data?.docs;

                            if (posts == null || posts.isEmpty) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(25),
                                  child: Text("No posts yet"),
                                ),
                              );
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: posts.length,
                              itemBuilder: (context, index) {
                                final post = posts[index];
                                final data = post.data();
                                String postId = post.id;
                                String message = data['PostMessage'] ?? '';
                                Timestamp timestamp = data['TimeStamp'];
                                List<String> likes =
                                    List<String>.from(data['likes'] ?? []);
                                bool isLiked =
                                    likes.contains(_currentUserEmail);

                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Card(
                                    color: Colors.white70,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.all(16),
                                      title: Text(
                                        message,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        DateFormat('yyyy-MM-dd – kk:mm')
                                            .format(timestamp.toDate()),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              isLiked
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color:
                                                  isLiked ? Colors.red : null,
                                            ),
                                            onPressed: () =>
                                                _toggleLike(postId, isLiked),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            '${likes.length}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 17,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Center(child: Text('No data available'));
          }
        },
      ),
    );
  }

  Widget _buildStatColumn(String title, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(title),
      ],
    );
  }

  String _generateChatRoomId(String currentUserEmail, String recipientEmail) {
    List<String> users = [currentUserEmail, recipientEmail];
    users.sort();
    return users.join("_");
  }
}
