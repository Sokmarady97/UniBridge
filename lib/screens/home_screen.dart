import 'package:flutter/material.dart';
import 'package:pknu/screens/schedule_screen.dart';
import 'package:pknu/screens/map_screen.dart';
import 'package:pknu/screens/chat_screen.dart';
import 'profile_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pknu/screens/subject_list_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Homescreen extends StatefulWidget {
  static const String id = 'home_screen';
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  // Firebase instance references
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // List to store registered subjects
  List<Map<String, dynamic>> subjects = [];

  // Define _titles for the AppBar
  final List<String> _titles = ['Home', 'Schedule', 'Chat', 'Map'];

  // Define _selectedIndex for navigation tracking
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSubjectsFromFirestore();
  }

  // Method to handle the user registration
  void _saveSubjectToFirestore(Map<String, dynamic> subject) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('registered_subjects')
            .add(subject);
        print("Subject added to Firestore");
      } catch (e) {
        print("Error adding subject to Firestore: $e");
      }
    }
  }

  // Method to load subjects from Firestore on login
  void _loadSubjectsFromFirestore() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        QuerySnapshot querySnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('registered_subjects')
            .get();

        setState(() {
          subjects = querySnapshot.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;

            // Convert serialized fields back to their original types
            return {
              'id': doc.id, // Store Firestore document ID for future deletion
              'subject': data['subject'],
              'day': data['day'],
              'startTime': _convertStringToTimeOfDay(
                  data['startTime']), // Convert String back to TimeOfDay
              'endTime': _convertStringToTimeOfDay(data['endTime']),
              'classroom': data['classroom'],
              'color': Color(data['color']), // Convert int back to Color
            };
          }).toList();
        });
        print("Subjects loaded from Firestore");
      } catch (e) {
        print("Error loading subjects from Firestore: $e");
      }
    }
  }

  // Helper function to convert a time string (e.g., "14:30") back into TimeOfDay
  TimeOfDay _convertStringToTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  // Method to handle adding subjects
  void _navigateToSearchScreen() async {
    final registeredSubject = await showSearch(
      context: context, // Use context directly from the state
      delegate: SubjectSearchDelegate(),
    );

    if (registeredSubject != null) {
      setState(() {
        subjects.add(registeredSubject); // Add subject to timetable
      });
      _saveSubjectToFirestore(registeredSubject); // Save to Firebase
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${registeredSubject['subject']} added to schedule')),
      );
    }
  }

  // Method to delete a subject from Firestore and remove it from the local list
  Future<void> _removeSubjectFromFirestore(String? subjectId) async {
    User? user = _auth.currentUser;
    if (user != null && subjectId != null) {
      try {
        // Delete the subject from Firestore using the document ID
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('registered_subjects')
            .doc(subjectId)
            .delete();

        // Remove the subject from the local list (UI update)
        setState(() {
          subjects.removeWhere((subject) => subject['id'] == subjectId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Subject removed successfully')),
        );
      } catch (e) {
        print("Error removing subject: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove subject')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to remove subject: invalid ID')),
      );
    }
  }

  // Show a dialog to confirm subject removal
  Future<void> _showRemoveSubjectDialog(String subjectId, String subject,
      String day, TimeOfDay startTime, TimeOfDay endTime) async {
    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Subject'),
          content: const Text('Do you want to remove this subject?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Call the remove subject method, passing the document ID
                _removeSubjectFromFirestore(subjectId);
                Navigator.pop(context);
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  // Handle the navigation when a bottom nav item is tapped
  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SchedulePage()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const ChatScreen(
                  friendEmail: '',
                )),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MapPage()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToSearchScreen, // Call the navigation method
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: _buildPageContent(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_rounded),
            label: 'Map',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true, // Ensures selected labels are shown
        showUnselectedLabels: true, // Ensures unselected labels are also shown
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildPageContent(int index) {
    if (index == 0) {
      return _buildSchedulePage();
    } else {
      return const Center(child: Text("Welcome to UniBridge"));
    }
  }

  Widget _buildSchedulePage() {
    // Scrollable SingleChildScrollView
    return SingleChildScrollView(
      child: Column(
        children: [
          // Map of time slots (rows) in the timetable
          Padding(
            padding: const EdgeInsets.all(1.0),
            child: Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              columnWidths: const {
                0: FixedColumnWidth(50),
              },
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: Colors.blueAccent),
                  children: [
                    _buildTableHeaderCell('Time'),
                    _buildTableHeaderCell('Mon'),
                    _buildTableHeaderCell('Tue'),
                    _buildTableHeaderCell('Wed'),
                    _buildTableHeaderCell('Thu'),
                    _buildTableHeaderCell('Fri'),
                    _buildTableHeaderCell('Sat'),
                    _buildTableHeaderCell('Sun'),
                  ],
                ),
                ..._buildTimetableRows(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<TableRow> _buildTimetableRows() {
    Map<String, TableRow> rows = {};

    // Initialize empty rows with time slots and days in 24-hour format
    for (var hour = 8; hour <= 22; hour++) {
      String time = '${hour.toString().padLeft(2, '0')}:00';
      rows[time] = TableRow(
        children: [
          _buildTableCell(time),
          for (var day = 0; day < 7; day++) _buildEmptyTableCell(),
        ],
      );
    }

    // Fill in the timetable with registered subjects
    for (var sub in subjects) {
      if (sub['startTime'] != null && sub['endTime'] != null) {
        TimeOfDay startTime = sub['startTime'];
        TimeOfDay endTime = sub['endTime'];
        String dayStr = sub['day'];
        int dayIndex =
            ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].indexOf(dayStr);

        // Convert startTime and endTime to 24-hour format
        String start =
            '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
        String end =
            '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

        bool merging = false;
        for (String time in rows.keys) {
          if (time == start) merging = true;
          if (merging) {
            rows[time]?.children[dayIndex + 1] = _buildMergedTableCell(
                sub['subject'],
                sub['classroom'],
                sub['color'],
                sub['startTime'],
                sub['endTime'],
                sub['day'],
                sub['id']); // Pass document ID to handle removal
          }
          if (time == end) merging = false;
        }
      }
    }

    return rows.values.toList();
  }

  Widget _buildTableHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.lobster(
            textStyle: const TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Container(
      padding: const EdgeInsets.all(5.0),
      child: Center(child: Text(text, style: const TextStyle(fontSize: 12))),
    );
  }

  Widget _buildEmptyTableCell() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.all(15.0),
      child: const Center(child: Text('')),
    );
  }

  Widget _buildMergedTableCell(String subject, String classroom, Color color,
      TimeOfDay startTime, TimeOfDay endTime, String day, String? subjectId) {
    return GestureDetector(
      onLongPress: () {
        if (subjectId != null) {
          _showRemoveSubjectDialog(subjectId, subject, day, startTime, endTime);
        } else {
          print("Error: Subject ID is null, cannot remove subject.");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unable to remove subject: invalid ID')),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.all(2.0),
        padding: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          color: color.withOpacity(0.7),
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4.0,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(subject,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10)),
            Text(classroom,
                style: const TextStyle(color: Colors.white70, fontSize: 8)),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    home: Homescreen(),
  ));
}
