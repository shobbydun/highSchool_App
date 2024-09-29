import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class AdditionalResourcesPage extends StatelessWidget {
  // Helper method to launch URL
  Future<void> _launchUrl(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Handle the error gracefully
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch $url'),
        ),
      );
    }
  }

  // Helper method for phone call
  Future<void> _callPhoneNumber(BuildContext context, String phoneNumber) async {
    final Uri uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not make a call to $phoneNumber'),
        ),
      );
    }
  }

  // Helper method for WhatsApp message
  Future<void> _sendWhatsAppMessage(BuildContext context, String phoneNumber) async {
    final Uri uri = Uri.parse('https://wa.me/$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not send WhatsApp message to $phoneNumber'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[100],
      appBar: AppBar(
        title: Text('Additional Resources'),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('resources').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error fetching resources'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('No resources available'));
            }

            final resources = snapshot.data!.docs;

            return ListView(
              children: [
                // Introduction Section
                Text(
                  'Explore Additional Resources',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[700],
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'We have compiled a list of resources to assist you in your academic and personal journey. Whether you are looking for study materials, mental health support, or career guidance, you will find helpful links and information below.',
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                SizedBox(height: 20),

                // Study Materials Section
                Text(
                  'Study Materials',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[600],
                  ),
                ),
                SizedBox(height: 10),
                ...resources.where((resource) => resource['category'] == 'Study Materials').map((resource) {
                  final title = resource['title'];
                  final description = resource['description'];
                  final fileUrl = resource['fileUrl'];

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5.0),
                    child: Card(
                      color: Colors.grey[200],
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        title: Text(title),
                        subtitle: Text(description),
                        trailing: Icon(Icons.download),
                        onTap: () async {
                          if (fileUrl != null && fileUrl.isNotEmpty) {
                            await _launchUrl(context, fileUrl);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('File URL is not available.'),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  );
                }).toList(),

                SizedBox(height: 20),

                // Mental Health Support Section
                Text(
                  'Mental Health Support',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[600],
                  ),
                ),
                SizedBox(height: 10),
                ...resources.where((resource) => resource['category'] == 'Mental Health Support').map((resource) {
                  final title = resource['title'];
                  final description = resource['description'];
                  final phoneNumber = resource['phoneNumber']?.toString();  // Convert to String

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5.0),
                    child: Card(
                      color: Colors.grey[200],
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        title: Text(title),
                        subtitle: Text(description),
                        trailing: Icon(Icons.phone),
                        onTap: () async {
                          if (phoneNumber != null && phoneNumber.isNotEmpty) {
                            await _callPhoneNumber(context, phoneNumber);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Phone number is not available.'),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  );
                }).toList(),

                SizedBox(height: 20),

                // Career Guidance Section
                Text(
                  'Career Guidance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[600],
                  ),
                ),
                SizedBox(height: 10),
                ...resources.where((resource) => resource['category'] == 'Career Guidance').map((resource) {
                  final title = resource['title'];
                  final description = resource['description'];
                  final fileUrl = resource['fileUrl'];

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5.0),
                    child: Card(
                      color: Colors.grey[200],
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        title: Text(title),
                        subtitle: Text(description),
                        trailing: Icon(Icons.business_center),
                        onTap: () async {
                          if (fileUrl != null && fileUrl.isNotEmpty) {
                            await _launchUrl(context, fileUrl);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Career guidance URL is not available.'),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  );
                }).toList(),

                SizedBox(height: 20),

                // Contact Information Section
                Text(
                  'Contact Us',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[600],
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'For more personalized help or if you have any questions, feel free to contact us using the details below:',
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    _launchUrl(context, 'mailto:shobbyduncan@gmail.com');
                  },
                  child: Text(
                    'Email: shobbyduncan@gmail.com',
                    style: TextStyle(fontSize: 16, color: Colors.black, decoration: TextDecoration.underline),
                  ),
                ),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    _callPhoneNumber(context, '0710285209');
                  },
                  child: Text(
                    'Phone: 0710285209',
                    style: TextStyle(fontSize: 16, color: Colors.black, decoration: TextDecoration.underline),
                  ),
                ),
                SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    _sendWhatsAppMessage(context, '+254710285209');
                  },
                  child: Text(
                    'Send WhatsApp Message',
                    style: TextStyle(color: Colors.purple[600], fontSize: 16),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
