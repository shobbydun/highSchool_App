import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final Timestamp date;
  final VoidCallback onTap;

  const EventCard({
    Key? key,
    required this.imagePath,
    required this.title,
    required this.date,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Format the date to only show the date part
    final formattedDate = DateFormat('MMMM d, yyyy').format(date.toDate());

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 5,
        margin: EdgeInsets.symmetric(vertical: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(7.0),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(10.0)),
              child: Image.network(
                imagePath,
                height: 260,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(child: Text('Failed to load image'));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    formattedDate, // Use formattedDate
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
