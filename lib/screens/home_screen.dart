import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pknu/screens/schedule_screen.dart';
import 'package:pknu/screens/map_screen.dart';
import 'package:pknu/screens/chat_screen.dart';
import 'profile_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Homescreen extends StatefulWidget {
  static const String id = 'home_screen';
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> subjects = [];
  final List<String> _titles = ['Home', 'Schedule', 'Chat', 'Map'];
  int _selectedIndex = 0;

  void _navigateToSearchScreen() async {
    final newSubject = await showSearch(
      context: context,
      delegate: SubjectSearchDelegate(registerSubject: _registerSubject),
    );

    if (newSubject != null) {
      setState(() {
        for (var time in newSubject['studyTimes']) {
          subjects.add({
            'subject': newSubject['subject'],
            'day': time['day'],
            'startTime': time['startTime'],
            'endTime': time['endTime'],
            'classroom': newSubject['classroom'],
            'color': newSubject['color'],
          });
        }
      });
      _saveSubjectsToFirestore(); // Save after adding
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${newSubject['subject']} added to schedule'),
        ),
      );
    }
  }

  void _registerSubject(
      BuildContext context, Map<String, dynamic> subjectData) {
    setState(() {
      subjects.add(subjectData);
    });
    _saveSubjectsToFirestore(); // Save subjects to Firestore
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${subjectData['subject']} registered successfully'),
      ),
    );
  }

  Future<void> _saveSubjectsToFirestore() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userSubjectsRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('registered_subjects');

      // Clear previous subjects
      final previousSubjects = await userSubjectsRef.get();
      for (var doc in previousSubjects.docs) {
        await doc.reference.delete();
      }

      // Add updated subjects
      for (var subject in subjects) {
        await userSubjectsRef.add({
          'subject': subject['subject'],
          'day': subject['day'],
          'startTime':
              '${subject['startTime'].hour}:${subject['startTime'].minute}',
          'endTime': '${subject['endTime'].hour}:${subject['endTime'].minute}',
          'classroom': subject['classroom'],
          'color': subject['color'].value, // Store color as an integer
        });
      }
    }
  }

  Future<void> _loadSubjectsFromFirestore() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userSubjectsRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('registered_subjects');

      final querySnapshot = await userSubjectsRef.get();
      setState(() {
        subjects = querySnapshot.docs.map((doc) {
          final data = doc.data();
          final startTimeParts = (data['startTime'] as String).split(':');
          final endTimeParts = (data['endTime'] as String).split(':');

          int startHour = int.tryParse(startTimeParts[0]) ?? 0;
          int startMinute = int.tryParse(startTimeParts[1]) ?? 0;
          int endHour = int.tryParse(endTimeParts[0]) ?? 0;
          int endMinute = int.tryParse(endTimeParts[1]) ?? 0;

          return {
            'subject': data['subject'],
            'day': data['day'],
            'startTime': TimeOfDay(hour: startHour, minute: startMinute),
            'endTime': TimeOfDay(hour: endHour, minute: endMinute),
            'classroom': data['classroom'],
            'color': Color(data['color']), // Reconstruct color from integer
          };
        }).toList();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSubjectsFromFirestore(); // Load subjects when the app starts
  }

  Future<void> _showRemoveSubjectDialog(String subjectName) async {
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
                setState(() {
                  subjects.removeWhere(
                      (subject) => subject['subject'] == subjectName);
                });
                _saveSubjectsToFirestore(); // Update Firestore
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Subject removed successfully')),
                );
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

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
            onPressed: _navigateToSearchScreen,
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
        showSelectedLabels: true,
        showUnselectedLabels: true,
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
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(1.0),
            child: Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              columnWidths: const {0: FixedColumnWidth(50)},
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

    int classNumber = 1;
    for (var hour = 8; hour <= 22; hour++) {
      for (var minute = 0; minute <= 30; minute += 30) {
        String time =
            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        String periodText = minute == 0
            ? '${classNumber}교시 $time'
            : '${classNumber - 0.5}교시 $time';

        rows[time] = TableRow(
          children: [
            _buildTableCell(periodText),
            for (var day = 0; day < 7; day++) _buildEmptyTableCell(),
          ],
        );

        if (minute == 0) {
          classNumber++;
        }
      }
    }

    for (var sub in subjects) {
      if (sub['startTime'] != null && sub['endTime'] != null) {
        TimeOfDay startTime = sub['startTime'];
        TimeOfDay endTime = sub['endTime'];
        String dayStr = sub['day'];
        int dayIndex =
            ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].indexOf(dayStr);

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
            );
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
      TimeOfDay startTime, TimeOfDay endTime, String day) {
    return GestureDetector(
      onLongPress: () => _showRemoveSubjectDialog(subject),
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

// Global function to generate a random color
Color _generateRandomColor() {
  Random random = Random();
  return Color.fromARGB(
    255,
    random.nextInt(256),
    random.nextInt(256),
    random.nextInt(256),
  );
}

class SubjectSearchDelegate extends SearchDelegate {
  final Function(BuildContext, Map<String, dynamic>) registerSubject;

  SubjectSearchDelegate({required this.registerSubject});

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
    return _buildSubjectList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSubjectList(context);
  }

  Widget _buildSubjectList(BuildContext context) {
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
            final additionalTime = subjectData['Column47'];
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
              return dayMapping[timeString.substring(0, 1)] ?? 'Unknown';
            }

            List<int> parsePeriods(String timeString) {
              try {
                String periodRange = timeString
                    .substring(1)
                    .trim(); // Remove day prefix and trim whitespace
                List<String> periods = periodRange.split('-');

                // Ensure both periods have numeric values
                if (periods.length != 2 ||
                    periods[0].isEmpty ||
                    periods[1].isEmpty) {
                  throw FormatException(
                      "Invalid period values in: $timeString");
                }

                int startPeriod = int.tryParse(periods[0].trim()) ?? -1;
                int endPeriod = int.tryParse(periods[1].trim()) ?? -1;

                // Check if parsed periods are valid numbers
                if (startPeriod == -1 || endPeriod == -1) {
                  throw FormatException(
                      "Non-numeric period values in: $timeString");
                }

                return [startPeriod, endPeriod];
              } catch (e) {
                print("Error parsing periods in parsePeriods(): $e");
                return [0, 0]; // Return default values if parsing fails
              }
            }

            String convertPeriodToTime(int period) {
              Map<int, String> periodToTimeMapping = {
                0: '08:00',
                1: '09:00',
                2: '10:00',
                3: '11:00',
                4: '12:00',
                5: '13:00',
                6: '14:00',
                7: '15:00',
                8: '16:00',
                9: '17:00',
                10: '18:00',
                11: '19:00',
                12: '20:00',
                13: '21:00',
                14: '22:00',
              };
              return periodToTimeMapping[period] ?? 'Unknown';
            }

            String timeAndClassroom = '';
            List<Map<String, dynamic>> studyTimes = [];

            if (timetable is String) {
              final day = parseDay(timetable);
              final periods = parsePeriods(timetable);

              if (periods[0] != 0 && periods[1] != 0) {
                String startTime = convertPeriodToTime(periods[0]);
                String endTime = convertPeriodToTime(periods[1]);

                timeAndClassroom =
                    '$day: $startTime - $endTime (교시 ${periods[0]} - ${periods[1]})';
                studyTimes.add({
                  'day': day,
                  'startTime': TimeOfDay(
                      hour: int.parse(startTime.split(':')[0]),
                      minute: int.parse(startTime.split(':')[1])),
                  'endTime': TimeOfDay(
                      hour: int.parse(endTime.split(':')[0]),
                      minute: int.parse(endTime.split(':')[1])),
                });
              }
            }

            if (additionalTime is String) {
              final additionalDay = parseDay(additionalTime);
              final additionalPeriods = parsePeriods(additionalTime);

              if (additionalPeriods[0] != 0 && additionalPeriods[1] != 0) {
                String startTime = convertPeriodToTime(additionalPeriods[0]);
                String endTime = convertPeriodToTime(additionalPeriods[1]);

                timeAndClassroom +=
                    '\n$additionalDay: $startTime - $endTime (교시 ${additionalPeriods[0]} - ${additionalPeriods[1]})';
                studyTimes.add({
                  'day': additionalDay,
                  'startTime': TimeOfDay(
                      hour: int.parse(startTime.split(':')[0]),
                      minute: int.parse(startTime.split(':')[1])),
                  'endTime': TimeOfDay(
                      hour: int.parse(endTime.split(':')[0]),
                      minute: int.parse(endTime.split(':')[1])),
                });
              }
            }

            final subtitleText =
                '$timeAndClassroom\nProfessor: $professor\nBuilding: $building';

            return ListTile(
              title: Text(subjectData['교과목명'] ?? 'Unknown Subject'),
              subtitle: Text(subtitleText),
              trailing: TextButton(
                child: const Text('Register'),
                onPressed: () {
                  Map<String, dynamic> registeredSubjectData = {
                    'subject': subjectData['교과목명'] ?? 'Unknown Subject',
                    'studyTimes': studyTimes, // Store all study times in a list
                    'classroom': building,
                    'color': _generateRandomColor(),
                  };

                  Navigator.pop(
                      context, registeredSubjectData); // Pass the data map back
                },
              ),
            );
          },
        );
      },
    );
  }
}

void main() {
  runApp(const MaterialApp(
    home: Homescreen(),
  ));
}
