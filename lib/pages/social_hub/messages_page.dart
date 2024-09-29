import 'dart:io';

import 'package:ccm/pages/social_hub/user_profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as Path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class MessagesPage extends StatefulWidget {
  final String chatRoomId;
  final String recipientEmail;
  final String recipientUserId;

  MessagesPage({
    Key? key,
    required this.chatRoomId,
    required this.recipientEmail,
    required this.recipientUserId,
  }) : super(key: key);

  @override
  _MessagesPageState createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  late String _currentUserEmail;
  List<String> _selectedMessages = [];
  bool _isSelecting = false;
  bool _isSearching = false;
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    _currentUserEmail = user?.email ?? '';
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    try {
      final messagesCollection = FirebaseFirestore.instance
          .collection('messages')
          .doc(widget.chatRoomId)
          .collection('messages');

      await messagesCollection.add({
        'sender': _currentUserEmail,
        'recipient': widget.recipientEmail,
        'message': _messageController.text,
        'type': 'text',
        'timestamp': FieldValue.serverTimestamp(),
      });

      final chatRoomDoc = FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(widget.chatRoomId);
      final chatRoomSnapshot = await chatRoomDoc.get();

      if (!chatRoomSnapshot.exists) {
        await chatRoomDoc.set({
          'users': [_currentUserEmail, widget.recipientEmail],
          'last_message': null,
          'last_message_timestamp': null,
        });
      }

      final lastMessageDoc = await messagesCollection
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
      if (lastMessageDoc.docs.isNotEmpty) {
        final lastMessage = lastMessageDoc.docs.first;
        await chatRoomDoc.update({
          'last_message': lastMessage.id,
          'last_message_timestamp': lastMessage['timestamp'],
        });
      }

      _messageController.clear();
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _getMessages() {
    return FirebaseFirestore.instance
        .collection('messages')
        .doc(widget.chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterMessages(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> messages) {
    if (_searchQuery == null || _searchQuery!.isEmpty) {
      return messages;
    }
    final queryLower = _searchQuery!.toLowerCase();
    return messages.where((doc) {
      final message = doc['message'] as String;
      return message.toLowerCase().contains(queryLower);
    }).toList();
  }

  Future<void> _clearChat() async {
    final messagesCollection = FirebaseFirestore.instance
        .collection('messages')
        .doc(widget.chatRoomId)
        .collection('messages');

    final snapshot = await messagesCollection.get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<Map<String, String?>> _getRecipientUserDetails() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.recipientUserId)
          .get();

      if (userDoc.exists) {
        return {
          'userName': userDoc.data()?['userName'] ?? 'No Name',
          'profileImage': userDoc.data()?['profileImage'] ?? null,
        };
      } else {
        return {'userName': 'No Name', 'profileImage': null};
      }
    } catch (e) {
      print('Error fetching user details: $e');
      return {'userName': 'Error', 'profileImage': null};
    }
  }

  Future<void> _pickMedia() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.image),
              title: Text('Send Image'),
              onTap: () async {
                Navigator.pop(
                    context); // Close the modal first to avoid UI blocking
                final pickedFile =
                    await ImagePicker().pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  _showCaptionDialog(pickedFile.path, 'image');
                } else {
                  print("No image selected.");
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.video_library),
              title: Text('Send Video'),
              onTap: () async {
                Navigator.pop(context); // Close the modal first
                final pickedFile =
                    await ImagePicker().pickVideo(source: ImageSource.gallery);
                if (pickedFile != null) {
                  _showCaptionDialog(pickedFile.path, 'video');
                } else {
                  print("No video selected.");
                }
              },
            ),
          ],
        );
      },
    );
  }

 Future<void> _showCaptionDialog(String filePath, String type) async {
  final TextEditingController captionController = TextEditingController();
  bool isSending = false;
  String? messageUrl; // To hold the media URL after sending

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.transparent, // Make background transparent
        title: Text('Add Caption'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pinkAccent, Colors.grey[300]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              padding: EdgeInsets.all(20),
              width: 600, // Set a fixed width for the dialog
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (type == 'image') ...[
                    ClipRect(
                      child: Align(
                        alignment: Alignment.center,
                        heightFactor: 0.6, // Show 50% of the image height
                        child: Image.file(File(filePath), fit: BoxFit.cover),
                      ),
                    ),
                    SizedBox(height: 10),
                    if (isSending) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 10),
                          Text('Sending...'),
                        ],
                      ),
                    ] else if (messageUrl != null) ...[
                      // Display the sent message preview (optional)
                      Text('Message sent: $messageUrl'),
                    ],
                  ] else ...[
                    // Placeholder for video
                    Container(),
                  ],
                  SizedBox(height: 10),
                  TextField(
                    controller: captionController,
                    decoration: InputDecoration(
                      hintText: 'Enter your caption',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 10), // Space before buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Cancel
                        },
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          if (isSending) return; // Prevent double sending
                          setState(() {
                            isSending = true; // Start sending
                          });

                          // Send media and capture the URL
                          messageUrl = await _sendMediaMessage(
                              filePath, type, captionController.text);

                          setState(() {
                            isSending = false; // Finished sending
                          });
                          Navigator.pop(context); // Close dialog
                        },
                        child: Text('Send'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

Future<String?> _sendMediaMessage(
    String filePath, String type, String caption) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User is not authenticated');
      return null;
    }

    final ref = FirebaseStorage.instance
        .ref()
        .child('media/${Path.basename(filePath)}');
    await ref.putFile(File(filePath));
    final downloadUrl = await ref.getDownloadURL();

    final messagesCollection = FirebaseFirestore.instance
        .collection('messages')
        .doc(widget.chatRoomId)
        .collection('messages');

    await messagesCollection.add({
      'sender': _currentUserEmail,
      'recipient': widget.recipientEmail,
      'message': downloadUrl,
      'caption': caption, // Store the caption
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
    });

    return downloadUrl; // Return the URL for the message
  } catch (e) {
    print('Error sending media: $e');
    return null;
  }
}


  void _showOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Contact Info'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        OtherProfilePage(userId: widget.recipientUserId),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_forever),
              title: Text('Clear Chat'),
              onTap: () async {
                Navigator.pop(context);
                bool confirm = await _showConfirmationDialog('clear the chat');
                if (confirm) {
                  await _clearChat();
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.select_all),
              title: Text('Select Messages'),
              onTap: () {
                setState(() {
                  _isSelecting = !_isSelecting;
                });
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool> _showConfirmationDialog(String action) async {
    return await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Confirm'),
              content: Text('Are you sure you want to $action?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Yes'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _deleteSelectedMessages() async {
    bool confirm =
        await _showConfirmationDialog('delete the selected messages');
    if (confirm) {
      final messagesCollection = FirebaseFirestore.instance
          .collection('messages')
          .doc(widget.chatRoomId)
          .collection('messages');

      for (String messageId in _selectedMessages) {
        await messagesCollection.doc(messageId).delete();
      }

      setState(() {
        _selectedMessages.clear();
        _isSelecting = false;
      });
    }
  }

  void _copySelectedMessages() {
    String concatenatedMessages = '';

    Future.wait(_selectedMessages.map((messageId) async {
      final messageDoc = FirebaseFirestore.instance
          .collection('messages')
          .doc(widget.chatRoomId)
          .collection('messages')
          .doc(messageId);
      final doc = await messageDoc.get();
      if (doc.exists) {
        concatenatedMessages += doc['message'] + '\n';
      }
    })).then((_) {
      Clipboard.setData(ClipboardData(text: concatenatedMessages)).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Messages copied to clipboard')),
        );
      });

      setState(() {
        _selectedMessages.clear();
        _isSelecting = false;
      });
    });
  }

  void _handleLongPress(String messageId) {
    setState(() {
      if (_isSelecting) {
        if (_selectedMessages.contains(messageId)) {
          _selectedMessages.remove(messageId);
        } else {
          _selectedMessages.add(messageId);
        }
      } else {
        _isSelecting = true;
        _selectedMessages.add(messageId);
      }
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = null;
        _searchController.clear();
      }
    });
  }

  Future<void> _viewImage(
      BuildContext context, Map<String, dynamic> message) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImagePage(
          imageUrl: message[
              'message'], // Make sure 'message' is defined and accessible
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[100],
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search messages',
                  border: InputBorder.none,
                ),
                onChanged: (query) {
                  setState(() {
                    _searchQuery = query;
                  });
                },
              )
            : FutureBuilder<Map<String, String?>>(
                future: _getRecipientUserDetails(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text('Loading...');
                  } else if (snapshot.hasError) {
                    return Text('Error');
                  } else {
                    final userDetails = snapshot.data;
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OtherProfilePage(
                                userId: widget.recipientUserId),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: userDetails?['profileImage'] !=
                                    null
                                ? NetworkImage(userDetails!['profileImage']!)
                                : AssetImage('assets/girlProfile.jpeg')
                                    as ImageProvider,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              userDetails?['userName'] ?? 'No Name',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
        backgroundColor: Colors.pink[200],
        elevation: 0,
        actions: [
          if (_isSelecting)
            IconButton(
              icon: Icon(Icons.delete_forever),
              onPressed: _deleteSelectedMessages,
            ),
          if (_isSelecting)
            IconButton(
              icon: Icon(Icons.copy),
              onPressed: _copySelectedMessages,
            ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: _showOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<
                List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
              stream: _getMessages(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final allMessages = snapshot.data ?? [];
                final filteredMessages = _filterMessages(allMessages);

                return ListView.builder(
                  reverse: true,
                  itemCount: filteredMessages.length,
                  itemBuilder: (context, index) {
                    final message = filteredMessages[index].data();
                    final messageId = filteredMessages[index].id;
                    final isCurrentUser =
                        message['sender'] == _currentUserEmail;
                    final isSelected = _selectedMessages.contains(messageId);

                    return ListTile(
                      onLongPress: () => _handleLongPress(messageId),
                      leading: _isSelecting
                          ? Checkbox(
                              value: isSelected,
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedMessages.add(messageId);
                                  } else {
                                    _selectedMessages.remove(messageId);
                                  }
                                });
                              },
                            )
                          : null,
                      title: Align(
                        alignment: isCurrentUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 14.0),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blue[100]
                                : isCurrentUser
                                    ? const Color.fromARGB(255, 212, 242, 178)
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: isCurrentUser
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              if (message['type'] == 'image')
                                GestureDetector(
                                  onTap: () => _viewImage(context, message),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment
                                        .start, // Align the caption properly
                                    children: [
                                      Container(
                                        constraints: BoxConstraints(
                                          maxWidth:
                                              200, // Adjust width as needed
                                          maxHeight:
                                              200, // Adjust height as needed
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          image: DecorationImage(
                                            image: NetworkImage(
                                                message['message']),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                          height:
                                              4), // Spacing between image and caption
                                      if (message['caption'] != null &&
                                          message['caption'].isNotEmpty)
                                        Text(
                                          message['caption'],
                                          style: TextStyle(
                                            color: isCurrentUser
                                                ? Colors.black
                                                : Colors.black,
                                            fontSize: 14,
                                            fontStyle: FontStyle
                                                .italic, // Optional: italic for caption
                                          ),
                                        ),
                                    ],
                                  ),
                                )
                              else if (message['type'] == 'video')
                                Text(
                                  'Video message',
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 16),
                                )
                              else
                                Text(
                                  message['message'],
                                  style: TextStyle(
                                    color: isCurrentUser
                                        ? Colors.black
                                        : Colors.black,
                                    fontSize: 16,
                                  ),
                                ),
                              SizedBox(height: 4),
                              Text(
                                message['timestamp'] != null
                                    ? DateFormat('HH:mm').format(
                                        (message['timestamp'] as Timestamp)
                                            .toDate())
                                    : '',
                                style: TextStyle(
                                  color: isCurrentUser
                                      ? Colors.grey[600]
                                      : Colors.grey[600],
                                  fontSize: 12,
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
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    maxLines: null,
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 16.0),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.attach_file),
                  onPressed: _pickMedia,
                  color: Colors.blueAccent,
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: Colors.blueAccent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FullScreenImagePage extends StatelessWidget {
  final String imageUrl;

  FullScreenImagePage({
    Key? key,
    required this.imageUrl,
  }) : super(key: key);

  Future<String> _downloadImage(BuildContext context) async {
    try {
      var response = await Dio().get(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      // Create the ccmHub directory if it doesn't exist
      final directory = await getApplicationDocumentsDirectory();
      final ccmHubDirectory = Directory('${directory.path}/ccmHub');
      if (!await ccmHubDirectory.exists()) {
        await ccmHubDirectory.create();
      }

      final filePath =
          '${ccmHubDirectory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      File file = File(filePath);
      await file.writeAsBytes(response.data);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image downloaded to $filePath')),
        );
      }
      return filePath; // Return the file path for sharing
    } catch (e) {
      print('Error downloading image: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download image')),
        );
      }
      return '';
    }
  }

  Future<void> _shareImage(BuildContext context) async {
    String imageUrl = this.imageUrl; // Ensure this is defined in your class

    try {
      // Step 1: Download the image
      var response = await Dio().get(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      // Step 2: Get the temporary directory
      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Step 3: Save the image
      File file = File(filePath);
      await file.writeAsBytes(response.data);

      // Step 4: Share the image
      await Share.shareXFiles([XFile(filePath)], text: 'Check out this image!');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image shared successfully!')),
        );
      }
    } catch (e) {
      print('Error sharing image: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share image')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () => _shareImage(context),
          ),
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () => _downloadImage(context),
          ),
        ],
      ),
      body: Center(
        child: Image.network(imageUrl),
      ),
    );
  }
}
