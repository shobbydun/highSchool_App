import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false; // Variable to track loading state

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImageAndSaveDetails() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    final userId = FirebaseAuth.instance.currentUser!.uid;

    String? imageUrl;

    if (_image != null) {
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child(userId)
            .child('profile_image.jpg');

        // Upload the file and await completion
        await storageRef.putFile(_image!);

        // Retrieve the download URL
        imageUrl = await storageRef.getDownloadURL();
        print('Image URL: $imageUrl'); // Log the image URL
      } catch (e) {
        print('Failed to upload image: $e');
        setState(() {
          _isLoading = false; // Hide loading indicator
        });
        return;
      }
    }

    try {
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(userId);
      await userDoc.update({
        'userName': _usernameController.text,
        'bio': _bioController.text,
        if (imageUrl != null) 'profileImage': imageUrl,
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      print('Failed to update user details: $e');
    } finally {
      setState(() {
        _isLoading = false; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[100],
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.pink[200],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: Icon(Icons.camera),
                            title: Text('Take a Photo'),
                            onTap: () {
                              _pickImage(ImageSource.camera);
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            leading: Icon(Icons.image),
                            title: Text('Pick from Gallery'),
                            onTap: () {
                              _pickImage(ImageSource.gallery);
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _image != null ? FileImage(_image!) : null,
                    child: _image == null
                        ? Icon(Icons.camera_alt,
                            size: 50, color: Colors.grey[600])
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _usernameController,
                        decoration:
                            const InputDecoration(labelText: 'Username'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your username';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _bioController,
                        decoration: const InputDecoration(labelText: 'Bio'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            _uploadImageAndSaveDetails();
                          }
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading) // Show loading indicator
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
