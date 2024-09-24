import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'subject_detail_screen.dart';

class SubjectListScreen extends StatelessWidget {
  static const String id = 'subject_list_screen';
  const SubjectListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subjects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: SubjectSearchDelegate());
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.collection('subject_list').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final subjects = snapshot.data?.docs ?? [];

          return ListView.builder(
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              var subjectData = subjects[index].data() as Map<String, dynamic>;

              // Extract the timetable information
              final timetable = subjectData['시간표'] as Map<String, dynamic>?;

              // Prepare a string to show the time and date
              String timeAndClassroom = '';
              if (timetable != null) {
                timeAndClassroom = timetable.entries.map((entry) {
                  final key = entry.key;
                  final value = entry.value;
                  return '$key: ${value ?? 'Unknown'}';
                }).join('\n');
              } else {
                timeAndClassroom = 'Unknown';
              }

              return ListTile(
                title: Text(subjectData['교과목명'] ?? 'Unknown Subject'),
                subtitle: Text(
                    timeAndClassroom), // Displaying time and classroom details
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubjectDetailScreen(
                        subjectData: subjectData,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class SubjectSearchDelegate extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) {
    // Actions for the AppBar (e.g., clear the query)
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    // Leading icon on the left of the AppBar
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Show the results based on the search query
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('subject_list')
          .where('교과목명', isGreaterThanOrEqualTo: query)
          .where('교과목명', isLessThanOrEqualTo: query + '\uf8ff')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No subjects found'));
        }

        final subjects = snapshot.data!.docs;

        return ListView.builder(
          itemCount: subjects.length,
          itemBuilder: (context, index) {
            var subjectData = subjects[index].data() as Map<String, dynamic>;

            // Extract the timetable information
            final timetable = subjectData['시간표'] as Map<String, dynamic>?;

            // Prepare a string to show the time and date
            String timeAndClassroom = '';
            if (timetable != null) {
              timeAndClassroom = timetable.entries.map((entry) {
                final key = entry.key;
                final value = entry.value;
                return '$key: ${value ?? 'Unknown'}';
              }).join('\n');
            } else {
              timeAndClassroom = 'Unknown';
            }

            return ListTile(
              title: Text(subjectData['교과목명'] ?? 'Unknown Subject'),
              subtitle: Text(
                  timeAndClassroom), // Displaying time and classroom details
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SubjectDetailScreen(subjectData: subjectData),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Show suggestions based on the search query
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('subject_list')
          .where('교과목명', isGreaterThanOrEqualTo: query)
          .where('교과목명', isLessThanOrEqualTo: query + '\uf8ff')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No subjects found'));
        }

        final subjects = snapshot.data!.docs;

        return ListView.builder(
          itemCount: subjects.length,
          itemBuilder: (context, index) {
            var subjectData = subjects[index].data() as Map<String, dynamic>;

            // Extract the timetable information
            final timetable = subjectData['시간표'] as Map<String, dynamic>?;

            // Prepare a string to show the time and date
            String timeAndClassroom = '';
            if (timetable != null) {
              timeAndClassroom = timetable.entries.map((entry) {
                final key = entry.key;
                final value = entry.value;
                return '$key: ${value ?? 'Unknown'}';
              }).join('\n');
            } else {
              timeAndClassroom = 'Unknown';
            }

            return ListTile(
              title: Text(subjectData['교과목명'] ?? 'Unknown Subject'),
              subtitle: Text(
                  timeAndClassroom), // Displaying time and classroom details
              onTap: () {
                query = subjectData['교과목명'] ?? '';
                showResults(context);
              },
            );
          },
        );
      },
    );
  }
}
