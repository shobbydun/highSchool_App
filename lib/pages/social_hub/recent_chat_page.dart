import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'messages_page.dart';

class RecentChatsPage extends StatefulWidget {
  @override
  _RecentChatsPageState createState() => _RecentChatsPageState();
}

class _RecentChatsPageState extends State<RecentChatsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final String _currentUserEmail;
  List<String> _pinnedChats = [];
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showPinnedChatsOnly = false;

  @override
  void initState() {
    super.initState();
    _currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    _loadPinnedChats();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  Future<void> _loadPinnedChats() async {
    try {
      final pinnedChatsDoc = await _firestore
          .collection('pinned_chats')
          .doc(_currentUserEmail)
          .get();
      if (pinnedChatsDoc.exists) {
        final data = pinnedChatsDoc.data();
        setState(() {
          _pinnedChats = List<String>.from(data?['pinned_rooms'] ?? []);
        });
        print('Pinned chats loaded: $_pinnedChats'); // Debugging output
      } else {
        setState(() {
          _pinnedChats = [];
        });
      }
    } catch (e) {
      print('Error loading pinned chats: $e');
      setState(() {
        _pinnedChats = [];
      });
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getRecentChats() {
    return _firestore
        .collection('chat_rooms')
        .where('users', arrayContains: _currentUserEmail)
        .orderBy('last_message_timestamp', descending: true)
        .limit(50) // Limit the number of documents
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getPinnedChats() {
    return _firestore
        .collection('pinned_rooms')
        .where('id', whereIn: _pinnedChats)
        .snapshots();
  }

  Future<Map<String, dynamic>> _getRecipientDetails(
      String recipientEmail) async {
    if (recipientEmail == _currentUserEmail) {
      return {
        'username': 'Myself',
        'profileImage': '',
        'userId': _currentUserEmail
      };
    }

    final userQuery = await _firestore
        .collection('users')
        .where('email', isEqualTo: recipientEmail)
        .limit(1)
        .get();

    if (userQuery.docs.isNotEmpty) {
      final userData = userQuery.docs.first.data();
      return {
        'username': userData['userName'] ?? 'Unknown',
        'profileImage': userData['profileImage'] ?? '',
        'userId': userQuery.docs.first.id
      };
    }
    return {'username': 'Unknown', 'profileImage': '', 'userId': ''};
  }

  Future<void> _confirmDeleteChat(String chatRoomId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Chat'),
          content: Text('Are you sure you want to delete this chat?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _firestore.collection('chat_rooms').doc(chatRoomId).delete();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete chat: $e')),
        );
      }
    }
  }

  Future<void> _togglePinChat(String chatRoomId) async {
    final isPinned = _pinnedChats.contains(chatRoomId);

    try {
      if (isPinned) {
        // Unpin chat
        _pinnedChats.remove(chatRoomId);
      } else {
        // Pin chat
        _pinnedChats.add(chatRoomId);
      }

      // Update or create the Firestore document for the current user
      await _firestore.collection('pinned_chats').doc(_currentUserEmail).set({
        'pinned_rooms': _pinnedChats,
      }, SetOptions(merge: true));

      // Reload pinned chats to update the list
      await _loadPinnedChats();
    } catch (e) {
      print('Error updating pinned chats in Firestore: $e');
    }
  }

  bool _isChatPinned(String chatRoomId) {
    return _pinnedChats.contains(chatRoomId);
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final messageDate = timestamp.toDate();

    // Check if the message is from today
    if (now.year == messageDate.year &&
        now.month == messageDate.month &&
        now.day == messageDate.day) {
      final hourDifference = now.difference(messageDate).inHours;
      if (hourDifference == 0) {
        final minutes = now.difference(messageDate).inMinutes;
        return minutes == 0
            ? 'Just now'
            : '$minutes min${minutes > 1 ? 's' : ''} ago';
      }
      return DateFormat.jm().format(messageDate); // e.g., 10:40 AM
    }

    // Check if the message is from yesterday
    if (now.year == messageDate.year &&
        now.month == messageDate.month &&
        now.day == now.day - 1) {
      return 'Yesterday';
    }

    // If it's more than a week old, show the full date
    final difference = now.difference(messageDate).inDays;
    if (difference < 7) {
      return DateFormat.E().format(messageDate); // Day of the week
    } else {
      return DateFormat.yMMMd().format(messageDate); // Full date
    }
  }

  bool _matchesSearchQuery(
      String username, String email, String messageContent) {
    final query = _searchQuery.trim().toLowerCase();
    return username.toLowerCase().contains(query) ||
        email.toLowerCase().contains(query) ||
        messageContent.toLowerCase().contains(query);
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _getFilteredChats(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> chats) async {
    final filteredChats = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

    for (var chatDoc in chats) {
      final chatRoomData = chatDoc.data();
      final users = List<String>.from(chatRoomData['users'] ?? []);
      final recipientEmail = users.firstWhere(
        (email) => email != _currentUserEmail,
        orElse: () => _currentUserEmail,
      );

      final lastMessage = chatRoomData['last_message'] ?? '';

      if (_matchesSearchQuery(
        await _getRecipientUsername(recipientEmail),
        recipientEmail,
        lastMessage,
      )) {
        filteredChats.add(chatDoc);
      }
    }

    return await _getSortedChats(filteredChats);
  }

  Future<String> _getRecipientUsername(String recipientEmail) async {
    if (recipientEmail == _currentUserEmail) return 'Myself';

    final userQuery = await _firestore
        .collection('users')
        .where('email', isEqualTo: recipientEmail)
        .limit(1)
        .get();

    if (userQuery.docs.isNotEmpty) {
      final userData = userQuery.docs.first.data();
      return userData['userName'] ?? 'Unknown';
    }
    return 'Unknown';
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _getSortedChats(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> chats) async {
    final pinnedChats = _pinnedChats.toSet();
    final pinnedList = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    final recentList = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

    for (var chatDoc in chats) {
      if (pinnedChats.contains(chatDoc.id)) {
        pinnedList.add(chatDoc);
      } else {
        recentList.add(chatDoc);
      }
    }

    // Sort recent chats by latest message timestamp
    recentList.sort((a, b) {
      final timestampA = a.data()['last_message_timestamp'] as Timestamp?;
      final timestampB = b.data()['last_message_timestamp'] as Timestamp?;
      return (timestampB ?? Timestamp.now())
          .compareTo(timestampA ?? Timestamp.now());
    });

    return [...pinnedList, ...recentList];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[100],
      appBar: AppBar(
        title: Text('Chats'),
        backgroundColor: Colors.pink[200],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(56.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixIcon: Icon(Icons.search),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _showPinnedChatsOnly ? _getPinnedChats() : _getRecentChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData ||
              snapshot.data == null ||
              snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No chats available.'));
          }

          final chats = snapshot.data!.docs;

          return FutureBuilder<
              List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
            future: _getFilteredChats(chats),
            builder: (context, futureSnapshot) {
              if (futureSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              final sortedChats = futureSnapshot.data ?? [];

              return ListView.separated(
                itemCount: sortedChats.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: Colors.grey[300],
                ),
                itemBuilder: (context, index) {
                  final chatRoomDoc = sortedChats[index];
                  final chatRoomId = chatRoomDoc.id;
                  final chatRoomData = chatRoomDoc.data();

                  final users = List<String>.from(chatRoomData['users'] ?? []);
                  final recipientEmail = users.firstWhere(
                    (email) => email != _currentUserEmail,
                    orElse: () => _currentUserEmail,
                  );

                  return FutureBuilder<Map<String, dynamic>>(
                    future: _getRecipientDetails(recipientEmail),
                    builder: (context, detailsSnapshot) {
                      if (detailsSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[400],
                          ),
                          title: Text('Loading...'),
                          subtitle: Text('Loading...'),
                        );
                      }

                      final recipientDetails = detailsSnapshot.data!;
                      final recipientUsername = recipientDetails['username'];
                      final recipientProfileImage =
                          recipientDetails['profileImage'];
                      final recipientUserId = recipientDetails['userId'];

                      // Get the last message timestamp
                      final lastMessageTimestamp =
                          chatRoomData['last_message_timestamp'] as Timestamp?;
                      String formattedTime = lastMessageTimestamp != null
                          ? _formatTimestamp(lastMessageTimestamp)
                          : '';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: recipientProfileImage.isNotEmpty
                              ? NetworkImage(recipientProfileImage)
                              : AssetImage('assets/girlProfile.jpeg')
                                  as ImageProvider,
                        ),
                        title: Text(recipientUsername),
                      subtitle: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
  stream: _firestore
      .collection('messages')
      .doc(chatRoomId)
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .limit(1) // Get the most recent message
      .snapshots(),
  builder: (context, messageSnapshot) {
    if (messageSnapshot.connectionState == ConnectionState.waiting) {
      return Text('Loading...');
    }

    // Check if there are messages
    if (messageSnapshot.data == null || messageSnapshot.data!.docs.isEmpty) {
      return Row(
        children: [
          Icon(Icons.chat_bubble_outline, color: Colors.grey),
          SizedBox(width: 8),
          Text('No messages yet.'),
        ],
      );
    }

    final lastMessageDoc = messageSnapshot.data!.docs.first;
    final lastMessageData = lastMessageDoc.data();

    final lastMessageType = lastMessageData['type'] ?? 'text'; // Default to 'text' if type is missing
    final lastMessage = lastMessageData['message'] ?? '';
    final sender = lastMessageData['sender'] ?? '';

    Widget displayWidget;

    if (lastMessageType == 'image') {
      displayWidget = Row(
        children: [
          Icon(Icons.photo, color: Colors.grey),
          SizedBox(width: 8),
          Text('${sender == _currentUserEmail ? "Me" : recipientUsername}: [Image]'),
        ],
      );
    } else if (lastMessageType == 'video') {
      displayWidget = Row(
        children: [
          Icon(Icons.videocam, color: Colors.grey),
          SizedBox(width: 8),
          Text('${sender == _currentUserEmail ? "Me" : recipientUsername}: [Video]'),
        ],
      );
    } else {
      displayWidget = Text(
        '${sender == _currentUserEmail ? "Me" : recipientUsername}: $lastMessage',
        overflow: TextOverflow.ellipsis,
      );
    }

    return displayWidget;
  },
),



                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  formattedTime,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                                width:
                                    8), // Space between the time and the dropdown
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert),
                              onSelected: (value) async {
                                if (value == 'delete') {
                                  await _confirmDeleteChat(chatRoomId);
                                } else if (value == 'pin') {
                                  await _togglePinChat(chatRoomId);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem<String>(
                                  value: 'pin',
                                  child: Row(
                                    children: [
                                      Icon(
                                        _isChatPinned(chatRoomId)
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: _isChatPinned(chatRoomId)
                                            ? Colors.yellow
                                            : Colors.grey,
                                      ),
                                      SizedBox(width: 8),
                                      Text(_isChatPinned(chatRoomId)
                                          ? 'Unpin'
                                          : 'Pin'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        tileColor: const Color.fromARGB(20, 38, 35, 35),
                        selectedTileColor: Colors.blue[50],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MessagesPage(
                                chatRoomId: chatRoomId,
                                recipientEmail: recipientEmail,
                                recipientUserId: recipientUserId,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
