import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ClassesPage extends StatefulWidget {
  const ClassesPage({super.key});

  @override
  _ClassesPageState createState() => _ClassesPageState();
}

class _ClassesPageState extends State<ClassesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedClass = 'Form 1';
  List<Map<String, dynamic>> _resources = [];
  bool _loadingResources = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  List<String> _categories = [
    'All',
    'Assignments',
    'Lecture Notes',
    'Practice Tests'
  ];
  Map<String, Map<String, dynamic>> _bookmarkedResources = {};

  @override
  void initState() {
    super.initState();
    _fetchResources(_selectedClass);
    _loadBookmarks();
  }


// Load bookmarks
Future<void> _loadBookmarks() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final bookmarkedData = prefs.getString('bookmarkedResources');
    if (bookmarkedData != null) {
      setState(() {
        _bookmarkedResources = Map<String, Map<String, dynamic>>.from(
          (jsonDecode(bookmarkedData) as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
          ),
        );
      });
    }
  } catch (e) {
    print("Error loading bookmarks: $e");
  }
}

Future<void> _saveBookmarks() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final bookmarkedData = jsonEncode(_bookmarkedResources);
    await prefs.setString('bookmarkedResources', bookmarkedData);
  } catch (e) {
    print("Error saving bookmarks: $e");
  }
}


  @override
  void dispose() {
    _saveBookmarks();
    super.dispose();
  }

  Future<void> _fetchResources(String className) async {
    setState(() {
      _loadingResources = true;
      _errorMessage = null;
    });

    try {
      final snapshot = await _firestore
          .collection('classMaterials')
          .where('class', isEqualTo: className)
          .get();

      setState(() {
        _resources = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
        _loadingResources = false;
      });
    } catch (e) {
      setState(() {
        _loadingResources = false;
        _errorMessage = "Error fetching resources: $e";
      });
      print("Error fetching resources: $e");
    }
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print("Could not launch $url");
    }
  }

  void _viewBookmarkedResources() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            BookmarkedResourcesPage(bookmarkedResources: _bookmarkedResources),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[100],
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushNamed('/home_page');
          },
        ),
        title: Text('Classes & Resources'),
        backgroundColor: Colors.pink[200],
        actions: [
          IconButton(
            icon: Icon(Icons.bookmark),
            onPressed: _viewBookmarkedResources,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Search Resources',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            SizedBox(height: 10),
            DropdownButton<String>(
              borderRadius: BorderRadius.circular(5),
              dropdownColor: Colors.grey[400],
              value: _selectedClass,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedClass = newValue;
                    _fetchResources(_selectedClass);
                  });
                }
              },
              items: ['Form 1', 'Form 2', 'Form 3', 'Form 4']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 10),
            DropdownButton<String>(
              borderRadius: BorderRadius.circular(5),
              dropdownColor: Colors.grey[400],
              value: _selectedCategory,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                }
              },
              items: _categories.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 10),
            _loadingResources
                ? Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : _resources.isEmpty
                        ? Center(
                            child:
                                Text('No resources available for this class.'))
                        : Column(
                            children: _resources.where((resource) {
                              bool matchesQuery = resource['title']
                                  .toString()
                                  .toLowerCase()
                                  .contains(_searchQuery.toLowerCase());
                              bool matchesCategory =
                                  _selectedCategory == 'All' ||
                                      resource['category'] == _selectedCategory;
                              return matchesQuery && matchesCategory;
                            }).map((resource) {
                              return Card(
                                color: Colors.grey[300],
                                elevation: 5,
                                shadowColor: Colors.black,
                                margin: EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  title: Text(
                                    resource['title'] ?? 'No Title',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(resource['description'] ??
                                      'No Description'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.open_in_new),
                                        onPressed: () =>
                                            _launchURL(resource['url'] ?? ''),
                                      ),
                                      IconButton(
                                        icon: Icon(_bookmarkedResources[
                                                    resource['title']] !=
                                                null
                                            ? Icons.bookmark
                                            : Icons.bookmark_border),
                                        onPressed: () {
                                          setState(() {
                                            if (_bookmarkedResources
                                                .containsKey(
                                                    resource['title'])) {
                                              _bookmarkedResources
                                                  .remove(resource['title']);
                                            } else {
                                              _bookmarkedResources[
                                                  resource['title']] = resource;
                                            }
                                            _saveBookmarks(); // Save bookmarks whenever they are updated
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
          ],
        ),
      ),
    );
  }
}

class BookmarkedResourcesPage extends StatelessWidget {
  final Map<String, Map<String, dynamic>> bookmarkedResources;

  const BookmarkedResourcesPage({super.key, required this.bookmarkedResources});

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print("Could not launch $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> bookmarkedList =
        bookmarkedResources.values.toList();

    return Scaffold(
      backgroundColor: Colors.pink[100],
      appBar: AppBar(
        title: Text('Bookmarked Resources'),
        backgroundColor: Colors.pink[200],
      ),
      body: bookmarkedList.isEmpty
          ? Center(child: Text('No bookmarked resources.'))
          : ListView.builder(
              itemCount: bookmarkedList.length,
              itemBuilder: (context, index) {
                final resource = bookmarkedList[index];
                return Card(
                  color: Colors.grey[300],
                  elevation: 5,
                  shadowColor: Colors.black,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(resource['title'] ?? 'No Title',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(resource['description'] ?? 'No Description'),
                    trailing: IconButton(
                      icon: Icon(Icons.open_in_new),
                      onPressed: () => _launchURL(resource['url'] ?? ''),
                    ),
                    onTap: () {
                      // Optionally, handle onTap event
                      _launchURL(resource['url'] ?? '');
                    },
                  ),
                );
              },
            ),
    );
  }
}
