import 'package:flutter/material.dart';
import 'package:pknu/screens/schedule_screen.dart';
import 'package:pknu/screens/map_screen.dart';
import 'package:pknu/screens/chat_screen.dart';
import 'profile_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pknu/screens/subject_list_screen.dart';

class Homescreen extends StatefulWidget {
  static const String id = 'home_screen';
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  int _selectedIndex = 0;
  final List<String> _titles = ['Home', 'Schedule', 'Chat', 'Map'];

  // List to store subjects
  List<Map<String, dynamic>> subjects = [];

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

  // Future<void> _showAddSubjectDialog() async {
  //   String subject = '';
  //   String classroom = '';
  //   String day = 'Mon';
  //   TimeOfDay startTime = TimeOfDay(hour: 9, minute: 0);
  //   TimeOfDay endTime = TimeOfDay(hour: 10, minute: 30);

  //   await showDialog<String>(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return StatefulBuilder(
  //         builder: (BuildContext context, StateSetter setState) {
  //           return AlertDialog(
  //             title: const Text('Add Subject'),
  //             content: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 TextField(
  //                   decoration: const InputDecoration(labelText: 'Subject'),
  //                   onChanged: (value) {
  //                     setState(() {
  //                       subject = value;
  //                     });
  //                   },
  //                 ),
  //                 TextField(
  //                   decoration: const InputDecoration(labelText: 'Classroom'),
  //                   onChanged: (value) {
  //                     setState(() {
  //                       classroom = value;
  //                     });
  //                   },
  //                 ),
  //                 DropdownButton<String>(
  //                   value: day,
  //                   onChanged: (String? newValue) {
  //                     if (newValue != null) {
  //                       setState(() {
  //                         day = newValue;
  //                       });
  //                     }
  //                   },
  //                   items: <String>[
  //                     'Mon',
  //                     'Tue',
  //                     'Wed',
  //                     'Thu',
  //                     'Fri',
  //                     'Sat',
  //                     'Sun'
  //                   ].map<DropdownMenuItem<String>>((String value) {
  //                     return DropdownMenuItem<String>(
  //                       value: value,
  //                       child: Text(value),
  //                     );
  //                   }).toList(),
  //                 ),
  //                 Row(
  //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                   children: [
  //                     TextButton(
  //                       child: Text('Start: ${startTime.format(context)}'),
  //                       onPressed: () async {
  //                         final TimeOfDay? picked = await showTimePicker(
  //                           context: context,
  //                           initialTime: startTime,
  //                         );
  //                         if (picked != null && picked != startTime) {
  //                           setState(() {
  //                             startTime = picked;
  //                           });
  //                         }
  //                       },
  //                     ),
  //                     TextButton(
  //                       child: Text('End: ${endTime.format(context)}'),
  //                       onPressed: () async {
  //                         final TimeOfDay? picked = await showTimePicker(
  //                           context: context,
  //                           initialTime: endTime,
  //                         );
  //                         if (picked != null && picked != endTime) {
  //                           setState(() {
  //                             endTime = picked;
  //                           });
  //                         }
  //                       },
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //             actions: <Widget>[
  //               TextButton(
  //                 onPressed: () {
  //                   Navigator.pop(context);
  //                 },
  //                 child: const Text('Cancel'),
  //               ),
  //               TextButton(
  //                 onPressed: () {
  //                   setState(() {
  //                     subjects.add({
  //                       'subject': subject,
  //                       'classroom': classroom,
  //                       'day': day,
  //                       'startTime': startTime,
  //                       'endTime': endTime,
  //                       'color': Colors.primaries[subjects.length %
  //                           Colors.primaries.length], // Assign color
  //                     });
  //                   });
  //                   Navigator.pop(context);
  //                 },
  //                 child: const Text('Add'),
  //               ),
  //             ],
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  Future<void> _showRemoveSubjectDialog(String subject, String day,
      TimeOfDay startTime, TimeOfDay endTime) async {
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
                  subjects.removeWhere((sub) =>
                      sub['subject'] == subject &&
                      sub['day'] == day &&
                      sub['startTime'] == startTime &&
                      sub['endTime'] == endTime);
                });
                Navigator.pop(context);
              },
              child: const Text('Remove'),
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
        title: Text(_titles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SubjectListScreen()));
            },
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
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildPageContent(int index) {
    switch (index) {
      case 0:
        return _buildHomePage();
      default:
        return const Center(child: Text("Welcome to Pocus Chat"));
    }
  }

  Widget _buildHomePage() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSchedulePage(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildCard('Reading', '10 tasks', Icons.book, Colors.pink),
                _buildCard('Map', '5 tasks', Icons.map, Colors.orange),
                _buildCard('Alarm', '1 tasks', Icons.alarm, Colors.blue),
                _buildCard('Noted', '2 tasks', Icons.note_alt, Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String title, String subtitle, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulePage() {
    Map<String, TableRow> rows = {};

    for (var hour = 8; hour <= 22; hour++) {
      for (var minute = 0; minute < 60; minute += 30) {
        String time =
            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        rows[time] = TableRow(
          children: [
            _buildTableCell(time),
            for (var day = 0; day < 7; day++) _buildEmptyTableCell(),
          ],
        );
      }
    }

    for (var sub in subjects) {
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
              sub['day']);
        }
        if (time == end) merging = false;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(1.0),
      child: Table(
        border: TableBorder.all(color: Colors.grey.shade300),
        columnWidths: const {
          0: FixedColumnWidth(50),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.blueAccent),
            children: [
              _buildTableHeaderCell('신간'),
              _buildTableHeaderCell('Mon'),
              _buildTableHeaderCell('Tue'),
              _buildTableHeaderCell('Wed'),
              _buildTableHeaderCell('Thu'),
              _buildTableHeaderCell('Fri'),
              _buildTableHeaderCell('Sat'),
              _buildTableHeaderCell('Sun'),
            ],
          ),
          ...rows.values,
        ],
      ),
    );
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
      child: Center(child: Text('')),
    );
  }

  Widget _buildMergedTableCell(String subject, String classroom, Color color,
      TimeOfDay startTime, TimeOfDay endTime, String day) {
    return GestureDetector(
      onLongPress: () =>
          _showRemoveSubjectDialog(subject, day, startTime, endTime),
      child: Container(
        margin: const EdgeInsets.all(2.0),
        padding: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          color: color.withOpacity(0.7),
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
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
