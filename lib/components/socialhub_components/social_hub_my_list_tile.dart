import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SocialHubMyListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Timestamp timestamp;
  final Widget? leading;
  final Widget? trailing;
  final int? maxLines;
  final int followersCount; 

  const SocialHubMyListTile({
    super.key,
    required this.subtitle,
    required this.title,
    required this.timestamp,
    this.leading,
    this.trailing,
    this.maxLines,
    required this.followersCount,
  });

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat.yMMMd().format(timestamp.toDate());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white70,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: EdgeInsets.all(16),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          subtitle: Text(
            '$subtitle\n$formattedDate\nFollowers: $followersCount', 
            style: TextStyle(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
          leading: leading,
          trailing: trailing,
        ),
      ),
    );
  }
}
