import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Define registerSubject as a global function
void registerSubject(
    BuildContext context, Map<String, dynamic> subjectData) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    // Check for subject name duplication
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('registered_subjects')
        .where('subject', isEqualTo: subjectData['subject'])
        .get();

    // Check for time overlap duplication on the same day
    final timeQuery = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('registered_subjects')
        .where('day', isEqualTo: subjectData['day'])
        .get();

    bool timeConflict = false;

    for (var doc in timeQuery.docs) {
      var data = doc.data();
      TimeOfDay existingStartTime =
          _convertStringToTimeOfDay(data['startTime']);
      TimeOfDay existingEndTime = _convertStringToTimeOfDay(data['endTime']);

      // Check for overlapping time
      if (!(subjectData['endTime'].hour <= existingStartTime.hour &&
              subjectData['endTime'].minute <= existingStartTime.minute) &&
          !(subjectData['startTime'].hour >= existingEndTime.hour &&
              subjectData['startTime'].minute >= existingEndTime.minute)) {
        timeConflict = true;
        break;
      }
    }

    // If the subject with the same name or overlapping time already exists, show an error message
    if (querySnapshot.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This subject is already registered!'),
          backgroundColor: Colors.red,
        ),
      );
      return; // Do not proceed to registration
    } else if (timeConflict) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Time duplication detected! Cannot register.'),
          backgroundColor: Colors.red,
        ),
      );
      return; // Do not proceed to registration
    }

    // Generate a random color for the subject
    final randomColor = _generateRandomColor();

    // Convert TimeOfDay and Color into serializable formats
    Map<String, dynamic> serializableSubjectData = {
      'subject': subjectData['subject'],
      'day': subjectData['day'],
      'startTime':
          '${subjectData['startTime'].hour}:${subjectData['startTime'].minute}', // Convert TimeOfDay to String
      'endTime':
          '${subjectData['endTime'].hour}:${subjectData['endTime'].minute}',
      'classroom': subjectData['classroom'],
      'color': randomColor.value, // Save the randomly generated color
    };

    // Save the subject if no conflicts are found
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('registered_subjects')
        .add(serializableSubjectData)
        .then((value) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('${subjectData['subject']} registered successfully!')),
      );
    }).catchError((error) => print("Failed to register subject: $error"));
  } else {
    print('No user is currently logged in');
  }
}

// Function to generate a random color
Color _generateRandomColor() {
  Random random = Random();
  return Color.fromARGB(
    255,
    random.nextInt(256),
    random.nextInt(256),
    random.nextInt(256),
  );
}

// Helper function to convert a time string (e.g., "14:30") back into TimeOfDay
TimeOfDay _convertStringToTimeOfDay(String time) {
  if (time == null) {
    print("Error: time string is null");
    return const TimeOfDay(
        hour: 0, minute: 0); // Default fallback or handle it differently
  }
  final parts = time.split(':');
  return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
}

class Homescreen extends StatefulWidget {
  static const String id = 'home_screen';
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // List to store registered subjects
  List<Map<String, dynamic>> subjects = [];

  @override
  void initState() {
    super.initState();
    _loadSubjectsFromFirestore();
  }

  // Load registered subjects from Firestore when the user logs in
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

            // Save document ID for future deletion and ensure it’s passed correctly
            return {
              'id': doc.id, // Correctly store Firestore document ID
              'subject': data['subject'],
              'day': data['day'],
              'startTime': _convertStringToTimeOfDay(data['startTime']),
              'endTime': _convertStringToTimeOfDay(data['endTime']),
              'classroom': data['classroom'],
              'color': Color(data['color']), // Retrieve and use saved color
            };
          }).toList();
        });
        print("Subjects loaded from Firestore");
      } catch (e) {
        print("Error loading subjects from Firestore: $e");
      }
    }
  }

  // Method to delete the subject from Firestore and UI
  void _deleteSubject(String? subjectId) async {
    if (subjectId == null) {
      print("Error: Subject ID is null, cannot remove subject.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error: Subject ID is null, cannot remove subject.')),
      );
      return;
    }

    User? user = _auth.currentUser;

    if (user != null) {
      try {
        // Delete the subject from Firestore using the subjectId
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('registered_subjects')
            .doc(subjectId)
            .delete();

        // Remove the subject from the local list and update UI
        setState(() {
          subjects.removeWhere((subject) => subject['id'] == subjectId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subject deleted successfully!')),
        );
      } catch (e) {
        print('Error deleting subject: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete subject')),
        );
      }
    }
  }

  // Confirmation dialog for deletion
  void _showDeleteConfirmationDialog(String? subjectId) {
    if (subjectId == null) {
      print("Invalid subject ID");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to remove subject: invalid ID')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Subject'),
          content: const Text('Are you sure you want to delete this subject?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                _deleteSubject(subjectId); // Correctly pass the subjectId
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: _buildSchedulePage(),
    );
  }

  Widget _buildSchedulePage() {
    return SingleChildScrollView(
      child: Column(
        children: [
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

        bool merging = false;
        for (String time in rows.keys) {
          if (time == '${startTime.hour.toString().padLeft(2, '0')}:00')
            merging = true;
          if (merging) {
            rows[time]?.children[dayIndex + 1] = _buildMergedTableCell(
              sub['subject'],
              sub['classroom'],
              sub['color'],
              sub['startTime'],
              sub['endTime'],
              sub['day'],
              sub['id'], // Ensure the subjectId is passed correctly here
            );
          }
          if (time == '${endTime.hour.toString().padLeft(2, '0')}:00')
            merging = false;
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
          style: const TextStyle(fontSize: 16, color: Colors.white),
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
      TimeOfDay startTime, TimeOfDay endTime, String day, String subjectId) {
    return GestureDetector(
      onLongPress: () => _showDeleteConfirmationDialog(
          subjectId), // Ensure subjectId is passed correctly
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

class SubjectSearchDelegate extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('subject')
          .where('교과목명', isGreaterThanOrEqualTo: query)
          .where('교과목명', isLessThanOrEqualTo: query + '\uf8ff')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No subjects found'));
        }

        final subjects = snapshot.data!.docs;

        return ListView.builder(
          itemCount: subjects.length,
          itemBuilder: (context, index) {
            var subjectData = subjects[index].data() as Map<String, dynamic>;
            final timetable = subjectData['시간표'];
            final professor = subjectData['Column42'] ?? 'Unknown Professor';
            final building = subjectData['Column51'] ?? 'Unknown Building';

            String parseDay(String timeString) {
              Map<String, String> dayMapping = {
                '월': 'Mon',
                '화': 'Tue',
                '수': 'Wed',
                '목': 'Thu',
                '금': 'Fri',
                '토': 'Sat',
                '일': 'Sun',
              };
              String day = timeString.substring(0, 1);
              return dayMapping[day] ?? 'Unknown';
            }

            List<int> parseTimeSlot(String timeString) {
              String timeRange = timeString.substring(1);
              List<String> times = timeRange.split('-');
              int startTime = int.parse(times[0]) + 12;
              int endTime = int.parse(times[1]) + 12;
              return [startTime, endTime];
            }

            String timeAndClassroom = '';
            if (timetable is String) {
              final day = parseDay(timetable);
              final times = parseTimeSlot(timetable);
              timeAndClassroom = '$day: ${times[0]}:00 - ${times[1]}:00';
            } else {
              timeAndClassroom = 'Unknown';
            }

            final subtitleText =
                '$timeAndClassroom\nProfessor: $professor\nBuilding: $building';

            return ListTile(
              title: Text(subjectData['교과목명'] ?? 'Unknown Subject'),
              subtitle: Text(subtitleText),
              trailing: TextButton(
                child: const Text('Register'),
                onPressed: () {
                  final parsedDay = parseDay(timetable);
                  final parsedTimes = parseTimeSlot(timetable);

                  Map<String, dynamic> registeredSubjectData = {
                    'subject': subjectData['교과목명'] ?? 'Unknown Subject',
                    'day': parsedDay,
                    'startTime': TimeOfDay(hour: parsedTimes[0], minute: 0),
                    'endTime': TimeOfDay(hour: parsedTimes[1], minute: 0),
                    'classroom': subjectData['Column51'] ?? 'Unknown Classroom',
                    'color': _generateRandomColor(), // Use random color here
                  };

                  // This sends the data back to the home screen
                  registerSubject(context, registeredSubjectData);
                  Navigator.pop(context, registeredSubjectData);
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('subject')
          .where('교과목명', isGreaterThanOrEqualTo: query)
          .where('교과목명', isLessThanOrEqualTo: query + '\uf8ff')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No subjects found'));
        }

        final subjects = snapshot.data!.docs;

        return ListView.builder(
          itemCount: subjects.length,
          itemBuilder: (context, index) {
            var subjectData = subjects[index].data() as Map<String, dynamic>;
            final timetable = subjectData['시간표'];
            final professor = subjectData['Column42'] ?? 'Unknown Professor';
            final building = subjectData['Column51'] ?? 'Unknown Building';

            String parseDay(String timeString) {
              Map<String, String> dayMapping = {
                '월': 'Mon',
                '화': 'Tue',
                '수': 'Wed',
                '목': 'Thu',
                '금': 'Fri',
                '토': 'Sat',
                '일': 'Sun',
              };
              String day = timeString.substring(0, 1);
              return dayMapping[day] ?? 'Unknown';
            }

            List<int> parseTimeSlot(String timeString) {
              String timeRange = timeString.substring(1);
              List<String> times = timeRange.split('-');
              int startTime = int.parse(times[0]) + 12;
              int endTime = int.parse(times[1]) + 12;
              return [startTime, endTime];
            }

            String timeAndClassroom = '';
            if (timetable is String) {
              final day = parseDay(timetable);
              final times = parseTimeSlot(timetable);
              timeAndClassroom = '$day: ${times[0]}:00 - ${times[1]}:00';
            } else {
              timeAndClassroom = 'Unknown';
            }

            final subtitleText =
                '$timeAndClassroom\nProfessor: $professor\nBuilding: $building';

            return ListTile(
              title: Text(subjectData['교과목명'] ?? 'Unknown Subject'),
              subtitle: Text(subtitleText),
              trailing: TextButton(
                child: const Text('Register'),
                onPressed: () {
                  final parsedDay = parseDay(timetable);
                  final parsedTimes = parseTimeSlot(timetable);

                  Map<String, dynamic> registeredSubjectData = {
                    'subject': subjectData['교과목명'] ?? 'Unknown Subject',
                    'day': parsedDay,
                    'startTime': TimeOfDay(hour: parsedTimes[0], minute: 0),
                    'endTime': TimeOfDay(hour: parsedTimes[1], minute: 0),
                    'classroom': subjectData['Column51'] ?? 'Unknown Classroom',
                    'color': _generateRandomColor(), // Use random color here
                  };

                  // Return the data to the home screen
                  registerSubject(context, registeredSubjectData);
                  Navigator.pop(context, registeredSubjectData);
                },
              ),
            );
          },
        );
      },
    );
  }
}
