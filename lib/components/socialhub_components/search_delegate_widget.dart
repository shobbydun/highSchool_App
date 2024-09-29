import 'package:flutter/material.dart';

class SearchDelegateWidget extends SearchDelegate {
  final TextEditingController searchController;

  SearchDelegateWidget({required this.searchController});

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          searchController.clear();
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // This method can be used to display search results based on the query
    // Here, we're using a placeholder, but you can integrate with your search logic
    return FutureBuilder(
      future: _search(query), // Replace with your search method
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
          return Center(child: Text('No results found.'));
        }

        final results = snapshot.data as List;

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final result = results[index];
            // Replace with your result widget
            return ListTile(
              title: Text(result.toString()),
              onTap: () {
                // Handle tap on result
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    searchController.text = query;
    // You can customize suggestions based on the query here
    return Center(child: Text('No suggestions available.'));
  }

  Future<List> _search(String query) async {
    // Replace with your actual search logic
    // For example, query your Firestore collection or any other data source
    await Future.delayed(Duration(seconds: 1)); // Simulate a network delay
    return []; // Replace with search results
  }
}
