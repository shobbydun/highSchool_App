import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GuidanceRequestPage extends StatefulWidget {
  @override
  _GuidanceRequestPageState createState() => _GuidanceRequestPageState();
}

class _GuidanceRequestPageState extends State<GuidanceRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  Future<void> _submitRequest() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Create a map of the form data
      final requestData = {
        'name': _nameController.text,
        'email': _emailController.text,
        'subject': _subjectController.text,
        'message': _messageController.text,
        'timestamp': FieldValue.serverTimestamp(),  
      };

      try {
        // Save data to Firestore
        await FirebaseFirestore.instance.collection('guidance_requests').add(requestData);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Your request has been submitted!')),
        );

        // Clear the form
        _nameController.clear();
        _emailController.clear();
        _subjectController.clear();
        _messageController.clear();
      } catch (e) {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit request. Please try again later.')),
        );
        print('Error saving data to Firestore: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[100],
      appBar: AppBar(
        title: Text('Request Guidance'),
        backgroundColor: Colors.pink[100],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Guidance Information Section
            Text(
              'Need Guidance?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.purple[700],
              ),
            ),
            SizedBox(height: 10),
            Text(
              'We offer guidance on various aspects including academic planning, career counseling, personal development, and social issues. Please fill out the form below to request guidance tailored to your needs.',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            SizedBox(height: 20),

            // Form Section
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  
                  TextFormField(
                    controller: _subjectController,
                    decoration: InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a subject';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  
                  TextFormField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your message';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),

                  // File Attachment Section
                  
                  SizedBox(height: 20),

                  Center(
                    child: ElevatedButton(
                      onPressed: _submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink[300],
                      ),
                      child: Text('Submit Request',
                      style: TextStyle(
                        color: Colors.white
                      ),),
                    ),
                  ),
                ],
              ),
            ),

            // Contact Information Section
            SizedBox(height: 20),
            Text(
              'Contact Us',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple[600],
              ),
            ),
            SizedBox(height: 10),
            Text(
              'If you have any immediate questions or need further assistance, feel free to contact us:',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            SizedBox(height: 10),
            Text(
              'Email: shobbyduncan@gmail.com',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            Text(
              'Phone: 0710285209',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}
