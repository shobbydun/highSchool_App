import 'package:ccm/database/firestore_services.dart';
import 'package:ccm/pages/main_pages/home_page.dart';
import 'package:flutter/material.dart';

class GradesTargetsPage extends StatefulWidget {
  final FirestoreServices firestoreServices;
  final String navigationSource;

  const GradesTargetsPage({
    Key? key,
    required this.firestoreServices,
    required this.navigationSource,
  }) : super(key: key);

  @override
  _GradesTargetsPageState createState() => _GradesTargetsPageState();
}

class _GradesTargetsPageState extends State<GradesTargetsPage> {
  Map<String, String> _personalTargets = {};
  String _overallGrade = '';

  @override
  void initState() {
    super.initState();
    _loadTargets();
  }

  Future<void> _loadTargets() async {
    try {
      final personalTargets =
          await widget.firestoreServices.getPersonalTargets();
      setState(() {
        _personalTargets = personalTargets.cast<String, String>();
        _overallGrade = personalTargets['overall'] ?? ''; // Load overall grade
      });
    } catch (e) {
      print("Error loading targets: $e");
    }
  }

  Future<void> _navigateToSubjectSelectionPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            SubjectSelectionPage(firestoreServices: widget.firestoreServices),
      ),
    );
    _loadTargets();
  }

  Future<void> _navigateToTargetSelectionPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TargetSelectionPage(
          firestoreServices: widget.firestoreServices,
          selectedSubjects: _personalTargets.keys.toList(),
        ),
      ),
    );
    _loadTargets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink[100],
        elevation: 0,
        leading: widget.navigationSource == 'drawer'
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => HomePage(
                        firestoreServices: widget.firestoreServices,
                      ),
                    ),
                  );
                },
              )
            : null,
        title: Text('Grades and Targets'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'My Targets',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.pink[800],
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: ListView(
                children: <Widget>[
                  ..._personalTargets.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            entry.key,
                            style: TextStyle(fontSize: 18.0),
                          ),
                          Text(
                            entry.value.isNotEmpty ? entry.value : 'Not set',
                            style: TextStyle(fontSize: 18.0),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.pink[50],
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pink.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          'Overall Grade',
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.pink[800],
                          ),
                        ),
                        Text(
                          _overallGrade.isNotEmpty ? _overallGrade : 'Not set',
                          style: TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.pink[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _navigateToSubjectSelectionPage,
              child: Text('Select Subjects'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.pink[300],
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _navigateToTargetSelectionPage,
              child: Text('Set Targets'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.pink[300],
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TargetSelectionPage extends StatefulWidget {
  final FirestoreServices firestoreServices;
  final List<String> selectedSubjects;

  const TargetSelectionPage({
    super.key,
    required this.firestoreServices,
    required this.selectedSubjects,
  });

  @override
  _TargetSelectionPageState createState() => _TargetSelectionPageState();
}

class _TargetSelectionPageState extends State<TargetSelectionPage> {
  Map<String, String> _personalTargets = {};
  String _overallGrade = '';
  final List<String> _grades = [
    'A',
    'A-',
    'B+',
    'B',
    'B-',
    'C+',
    'C',
    'C-',
    'D+',
    'D',
    'D-',
    'E'
  ];

  @override
  void initState() {
    super.initState();
    _initializeTargets();
  }

  Future<void> _initializeTargets() async {
    try {
      final personalTargets =
          await widget.firestoreServices.getPersonalTargets();
      setState(() {
        _personalTargets = Map.fromIterable(
          widget.selectedSubjects,
          key: (subject) => subject as String,
          value: (subject) => personalTargets[subject] ?? '',
        );
        _overallGrade =
            personalTargets['Overal'] ?? ''; // Load overall grade if present
      });
    } catch (e) {
      print("Error loading targets: $e");
    }
  }

  Future<void> _saveTargets() async {
    try {
      final nonEmptyTargets = Map.fromEntries(
        _personalTargets.entries.where((entry) => entry.value.isNotEmpty),
      );
      nonEmptyTargets['overall'] =
          _overallGrade; // Include overall grade in saved data
      await widget.firestoreServices.setPersonalTargets(nonEmptyTargets);
    } catch (e) {
      print("Error saving targets: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Set Targets'),
        backgroundColor: Colors.pink[100],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: <Widget>[
            ..._personalTargets.keys.map((subject) {
              final currentValue = _personalTargets[subject];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(subject),
                    DropdownButton<String>(
                      value:
                          _grades.contains(currentValue) ? currentValue : null,
                      items: _grades.map((grade) {
                        return DropdownMenuItem<String>(
                          value: grade,
                          child: Text(grade),
                        );
                      }).toList(),
                      onChanged: (String? newGrade) {
                        setState(() {
                          _personalTargets[subject] = newGrade ?? '';
                        });
                      },
                      hint: Text('Select Grade'),
                    ),
                  ],
                ),
              );
            }).toList(),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Overall Grade'),
                DropdownButton<String>(
                  value: _grades.contains(_overallGrade) ? _overallGrade : null,
                  items: _grades.map((grade) {
                    return DropdownMenuItem<String>(
                      value: grade,
                      child: Text(grade),
                    );
                  }).toList(),
                  onChanged: (String? newGrade) {
                    setState(() {
                      _overallGrade = newGrade ?? '';
                    });
                  },
                  hint: Text('Select Overall Grade'),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _saveTargets().then((_) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => GradesTargetsPage(
                  firestoreServices: widget.firestoreServices,
                  navigationSource: '',
                ),
              ),
            );
          });
        },
        child: Icon(Icons.save),
        backgroundColor: Colors.pinkAccent,
      ),
    );
  }
}

class SubjectSelectionPage extends StatefulWidget {
  final FirestoreServices firestoreServices;

  const SubjectSelectionPage({super.key, required this.firestoreServices});

  @override
  _SubjectSelectionPageState createState() => _SubjectSelectionPageState();
}

class _SubjectSelectionPageState extends State<SubjectSelectionPage> {
  final List<String> _allSubjects = [
    'Math',
    'English',
    'Kiswahili',
    'Biology',
    'Chemistry',
    'Physics',
    'History',
    'C.R.E',
    'Business',
    'Agriculture',
    'Music',
    'Home Science',
  ];

  Map<String, bool> _selectedSubjects = {};

  @override
  void initState() {
    super.initState();
    _loadSelectedSubjects();
  }

  Future<void> _loadSelectedSubjects() async {
    try {
      final selectedSubjects =
          await widget.firestoreServices.getSelectedSubjects();
      setState(() {
        _selectedSubjects = Map.fromIterable(
          _allSubjects,
          key: (subject) => subject as String,
          value: (subject) => selectedSubjects.contains(subject),
        );
      });
    } catch (e) {
      print("Error loading selected subjects: $e");
    }
  }

  Future<void> _saveSelectedSubjects() async {
    try {
      final subjectsToSave = _selectedSubjects.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();
      await widget.firestoreServices.setSelectedSubjects(subjectsToSave);
    } catch (e) {
      print("Error saving selected subjects: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Your Subjects'),
        backgroundColor: Colors.pink[100],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: _allSubjects.map((subject) {
            return CheckboxListTile(
              title: Text(subject),
              value: _selectedSubjects[subject] ?? false,
              onChanged: (bool? value) {
                setState(() {
                  _selectedSubjects[subject] = value ?? false;
                });
              },
            );
          }).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _saveSelectedSubjects().then((_) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => TargetSelectionPage(
                  firestoreServices: widget.firestoreServices,
                  selectedSubjects: _selectedSubjects.keys
                      .where((subject) => _selectedSubjects[subject]!)
                      .toList(),
                ),
              ),
            );
          });
        },
        child: Icon(Icons.arrow_forward),
        backgroundColor: Colors.pinkAccent,
      ),
    );
  }
}
