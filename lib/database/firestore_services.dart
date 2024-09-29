import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreServices {
  final FirebaseFirestore _db = FirebaseFirestore.instance;  
  final String userId;

  FirestoreServices(this.userId);

  String get _userCollection => 'users/$userId';

  Future<String?> getProfileImageUrl(String s) async {
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        return data['profileImage'] as String?;
      }
    } catch (e) {
      print("Error fetching profile image URL: $e");
    }
    return null;
  }

  Future<String?> getUsername(String s) async {
    try {
      if (userId.isEmpty) {
        print("User ID is empty.");
        return null;
      }

      final docSnapshot = await _db.collection('users').doc(userId).get();

      if (!docSnapshot.exists) {
        print("Document does not exist for userId: $userId");
        return 'N/A';
      }

      final data = docSnapshot.data();
      if (data == null || !data.containsKey('userName')) {
        print("Document does not contain 'userName' field.");
        return 'N/A';
      }

      return data['userName'] as String? ?? 'N/A';
    } catch (e) {
      print("Error fetching user name: $e");
      return null;
    }
  }

  Future<void> setSelectedSubjects(List<String> subjects) async {
    try {
      await _db.collection('users').doc(userId).update({
        'selected_subjects': subjects,
      });
    } catch (e) {
      print("Error setting selected subjects: $e");
    }
  }

  Future<List<String>> getSelectedSubjects() async {
    try {
      final docSnapshot = await _db.collection('users').doc(userId).get();
      final data = docSnapshot.data();
      if (data != null && data['selected_subjects'] is List) {
        return List<String>.from(data['selected_subjects']);
      } else {
        return [];
      }
    } catch (e) {
      print("Error fetching selected subjects: $e");
      return [];
    }
  }

  Future<void> setPersonalTargets(Map<String, String> targets) async {
    try {
      await _db.collection('users').doc(userId).update({
        'personal_targets': targets,
      });
    } catch (e) {
      print("Error setting personal targets: $e");
    }
  }

  Future<Map<String, String>> getPersonalTargets() async {
    try {
      final docSnapshot = await _db.collection('users').doc(userId).get();
      final data = docSnapshot.data();
      if (data != null && data['personal_targets'] is Map) {
        return Map<String, String>.from(data['personal_targets']);
      } else {
        return {};
      }
    } catch (e) {
      print("Error fetching personal targets: $e");
      return {};
    }
  }

  // Method to fetch upcoming events
  Future<List<Event>> fetchUpcomingEvents() async {
    try {
      final snapshot = await _db.collection('events')
        .where('type', isEqualTo: 'event')
        .orderBy('date')
        .get();
      return snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
    } catch (e) {
      print("Error fetching events: $e");
      return [];
    }
  }

  // Method to fetch recent notifications
  Future<List<CustomNotification>> fetchRecentNotifications() async {
    try {
      final snapshot = await _db.collection('notification')
        .orderBy('date', descending: true)
        .limit(3)
        .get();
      return snapshot.docs.map((doc) => CustomNotification.fromFirestore(doc)).toList();
    } catch (e) {
      print("Error fetching notifications: $e");
      return [];
    }
  }
}

// Event model
class Event {
  final String imagePath;
  final String title;
  final Timestamp date;
  final String description;

  Event({
    required this.imagePath,
    required this.title,
    required this.date,
    required this.description,
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Event(
      imagePath: data['imagePath'] ?? '',
      title: data['title'] ?? '',
      date: data['date'] as Timestamp,
      description: data['description'] ?? '',
    );
  }
}

// CustomNotification model
class CustomNotification {
  final String title;
  final Timestamp date;

  CustomNotification({
    required this.title,
    required this.date,
  });

  factory CustomNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CustomNotification(
      title: data['title'] ?? 'No Title',
      date: data['date'] as Timestamp,
    );
  }
}
