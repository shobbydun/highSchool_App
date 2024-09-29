import 'package:ccm/components/additional_resources_page.dart';
import 'package:ccm/components/guidance_request_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GoalsCounsellingPage extends StatelessWidget {
  final bool showBackButton;

  const GoalsCounsellingPage({super.key, this.showBackButton = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[100],
      appBar: AppBar(
        title: Text('Goals & Counselling'),
        backgroundColor: Colors.transparent,
        leading: showBackButton
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.purple[700]),
                onPressed: () {
                  Navigator.of(context).pushNamed('/home_page');
                },
              )
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Text(
              'Welcome to Your Goals & Counselling Page',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.purple[700],
              ),
            ),
            SizedBox(height: 20),
            Text(
              'We’re here to support you in achieving your goals and provide guidance whenever you need it. Stay motivated and remember, every step you take brings you closer to your dreams!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 30),
            
            // Quotes Section
            Text(
              'Inspirational Quotes:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.purple[600],
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('quotes').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error fetching quotes'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No quotes available'));
                  }

                  final quotes = snapshot.data!.docs
                      .map((doc) => doc['text'] as String)
                      .toList();

                  return ListView.builder(
                    
                    itemCount: quotes.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                        child: _buildQuoteCard(context, quotes[index]),
                      );
                    },
                  );
                },
              ),
            ),
            SizedBox(height: 5),
            
            // Guidance Section
            ElevatedButton(
              
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GuidanceRequestPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent[100],
              ),
              child: Text(
                'Request Guidance',
                style: TextStyle(fontSize: 16,color: Colors.purple[700]),
              ),
            ),
            SizedBox(height: 1),
            
            // Additional Resources Section
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdditionalResourcesPage(),
                  ),
                );
              },
              child: Text(
                'Explore Additional Resources',
                style: TextStyle(
                  color: Colors.purple[600],
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteCard(BuildContext context, String quote) {
    return Card(
      color: Colors.grey[200],
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          quote,
          style: TextStyle(
            fontSize: 16,
            fontStyle: FontStyle.italic,
            color: Colors.black54,
          ),
        ),
      ),
    );
  }
}
