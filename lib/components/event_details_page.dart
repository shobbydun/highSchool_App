import 'package:ccm/database/firestore_services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add this import for date formatting

class EventDetailsPage extends StatelessWidget {
  final Event event;

  const EventDetailsPage({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    // Format the date
    final formattedDate = DateFormat('MMMM d, yyyy').format(event.date.toDate());

    return Scaffold(
      appBar: AppBar(
        title: Text(event.title),
        backgroundColor: Colors.pink[100],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(event.imagePath,
            ),
            SizedBox(height: 16),
            Text(
              event.title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.pink[800],
              ),
            ),
            SizedBox(height: 8),
            Text(
              formattedDate,
              style: TextStyle(
                fontSize: 18,
                color: Colors.pink[600],
              ),
            ),
            SizedBox(height: 16),
            Text(
              event.description, 
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
