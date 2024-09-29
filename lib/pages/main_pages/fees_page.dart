import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class FeesPage extends StatefulWidget {
  const FeesPage({super.key});

  @override
  _FeesPageState createState() => _FeesPageState();
}

class _FeesPageState extends State<FeesPage> {
  late Future<String> _imageUrlFuture;

  @override
  void initState() {
    super.initState();
    _imageUrlFuture = _fetchImageUrl();
  }

  Future<String> _fetchImageUrl() async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child('resources/fee_structure.png');
      final url = await storageRef.getDownloadURL();
      return url;
    } catch (e) {
      throw Exception('Failed to fetch image URL: $e');
    }
  }

  Future<void> _downloadImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/fee_structure.png');
        await file.writeAsBytes(bytes);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Image downloaded to ${file.path}'),
        ));
      } else {
        throw Exception('Failed to download image. Status code: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error downloading image: $e'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushNamed('/home_page');
          },
        ),
        title: Text('Fees Overview'),
        backgroundColor: Colors.pink[100],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'School Fees Overview',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.pink[800],
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Please review the fee structure and deadlines below.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 20),

            // Fee Breakdown with Image
            Text(
              'Fees Structure:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.pink[600],
              ),
            ),
            SizedBox(height: 10),
            FutureBuilder<String>(
              future: _imageUrlFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  final imageUrl = snapshot.data!;
                  return GestureDetector(
                    onTap: () => _downloadImage(imageUrl),
                    child: Container(
                      width: double.infinity,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                } else {
                  return Center(child: Text('No image available.'));
                }
              },
            ),
            SizedBox(height: 20),

            // Payment Instructions
            Text(
              'Payment Instructions:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.pink[600],
              ),
            ),
            SizedBox(height: 10),
            Text(
              '1. Online payments can be made through our secure portal.\n'
              '2. For bank transfers, please use the following details:\n'
              '   Bank: XYZ Bank\n'
              '   Account Number: 1234567890\n'
              '3. Contact the accounts office for any issues.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 20),

            // Important Dates
            Text(
              'Important Dates:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.pink[600],
              ),
            ),
            SizedBox(height: 10),
            Text(
              '1. Tuition Fees Due: 15th of every month\n'
              '2. Sports Fee Due: 1st of each term\n'
              '3. Library Fee Due: End of each term\n'
              '4. Late Payment Penalty: Ksh 500 per week',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 20),

            // Contact Details
            Text(
              'Contact Us:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.pink[600],
              ),
            ),
            SizedBox(height: 10),
            Text(
              'For any inquiries or assistance, please contact:\n'
              'Email: fees@school.com\n'
              'Phone: +254 123 456 789\n'
              'Office Hours: Mon-Fri, 8:00 AM - 4:00 PM',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
