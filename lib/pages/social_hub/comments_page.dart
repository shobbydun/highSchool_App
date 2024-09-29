import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CommentsPage extends StatefulWidget {
  final String postId;

  CommentsPage({required this.postId});

  @override
  _CommentsPageState createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final TextEditingController _commentController = TextEditingController();
  
  void _addComment() async {
    final userEmail = FirebaseAuth.instance.currentUser!.email!;
    final commentText = _commentController.text;

    if (commentText.isNotEmpty) {
      await FirebaseFirestore.instance.collection('Posts').doc(widget.postId).collection('comments').add({
        'userEmail': userEmail,
        'commentText': commentText,
        'timestamp': Timestamp.now(),
        'likes': [], // Initialize with an empty list
        'dislikes': [], // Initialize with an empty list
      });

      await FirebaseFirestore.instance.collection('Posts').doc(widget.postId).update({
        'commentsCount': FieldValue.increment(1),
      });

      _commentController.clear();
    }
  }

  Future<void> _toggleLike(String commentId, bool isLiked) async {
    final userEmail = FirebaseAuth.instance.currentUser!.email!;
    final commentDoc = FirebaseFirestore.instance.collection('Posts').doc(widget.postId).collection('comments').doc(commentId);

    try {
      if (isLiked) {
        await commentDoc.update({
          'likes': FieldValue.arrayRemove([userEmail])
        });
      } else {
        await commentDoc.update({
          'likes': FieldValue.arrayUnion([userEmail])
        });
      }
    } catch (e) {
      print('Error toggling like status: $e');
    }
  }

  Future<void> _toggleDislike(String commentId, bool isDisliked) async {
    final userEmail = FirebaseAuth.instance.currentUser!.email!;
    final commentDoc = FirebaseFirestore.instance.collection('Posts').doc(widget.postId).collection('comments').doc(commentId);

    try {
      if (isDisliked) {
        await commentDoc.update({
          'dislikes': FieldValue.arrayRemove([userEmail])
        });
      } else {
        await commentDoc.update({
          'dislikes': FieldValue.arrayUnion([userEmail])
        });
      }
    } catch (e) {
      print('Error toggling dislike status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[100],
      appBar: AppBar(
        backgroundColor: Colors.pink[200],
        title: Text('Comments'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data?.docs;

                if (comments == null || comments.isEmpty) {
                  return Center(child: Text('Be the first to comment...'));
                }

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final commentData = comment.data() as Map<String, dynamic>;
                    final commentText = commentData['commentText'];
                    final userEmail = commentData['userEmail'];
                    final timestamp = commentData['timestamp'] as Timestamp;
                    final likes = List<String>.from(commentData['likes'] ?? []);
                    final dislikes = List<String>.from(commentData['dislikes'] ?? []);
                    final isLiked = likes.contains(FirebaseAuth.instance.currentUser!.email);
                    final isDisliked = dislikes.contains(FirebaseAuth.instance.currentUser!.email);

                    return ListTile(
                      title: Text(commentText),
                      subtitle: Text('$userEmail - ${_formatTimestamp(timestamp)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              isLiked ? Icons.thumb_up : Icons.thumb_up_off_alt,
                              color: isLiked ? Colors.blue : null,
                            ),
                            onPressed: () => _toggleLike(comment.id, isLiked),
                          ),
                          Text('${likes.length}'),
                          IconButton(
                            icon: Icon(
                              isDisliked ? Icons.thumb_down : Icons.thumb_down_off_alt,
                              color: isDisliked ? Colors.red : null,
                            ),
                            onPressed: () => _toggleDislike(comment.id, isDisliked),
                          ),
                          Text('${dislikes.length}'),
                        ],
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
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    return DateFormat('MMM d, yyyy - h:mma ').format(timestamp.toDate());
  }
}
