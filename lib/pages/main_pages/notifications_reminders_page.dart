import 'package:ccm/database/firestore_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationsRemindersPage extends StatelessWidget {
  const NotificationsRemindersPage({super.key});

  Future<List<CustomNotification>> _fetchAllNotifications() async {
    // Fetch all notifications from Firestore
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore.collection('notification').orderBy('date', descending: true).get();
    return snapshot.docs.map((doc) => CustomNotification.fromFirestore(doc)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[100],
      appBar: AppBar(
        title: Text('All Notifications'),
        backgroundColor: Colors.pink[100],
      ),
      body: FutureBuilder<List<CustomNotification>>(
        future: _fetchAllNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Failed to load notifications.'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No notifications available.'));
          }

          final notifications = snapshot.data!;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return ListTile(
                leading: Icon(Icons.notifications, color: Colors.pink[600]),
                title: Text(notification.title),
                subtitle: Text(notification.date.toDate().toLocal().toString().split(' ')[0]), // Display date only
                onTap: () {
                },
              );
            },
          );
        },
      ),
    );
  }
}
