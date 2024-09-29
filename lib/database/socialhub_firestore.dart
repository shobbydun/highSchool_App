import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreDatabase {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final String _userEmail;

  FirestoreDatabase() {
    _userEmail = _auth.currentUser?.email ?? 'Unknown User';
  }

  // Collection reference for posts
  CollectionReference get _postsCollection => _db.collection('Posts');

  // Add a post
  Future<void> addPost(String message) async {
    try {
      await _postsCollection.add({
        'UserEmail': _userEmail,
        'PostMessage': message,
        'TimeStamp': Timestamp.now(),
      });
    } catch (e) {
      print("Error adding post: $e");
    }
  }

  // Stream of posts
  Stream<QuerySnapshot> getPostsStream() {
    return _postsCollection
        .orderBy('TimeStamp', descending: true)
        .snapshots();
  }
}
