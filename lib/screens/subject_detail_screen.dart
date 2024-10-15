import 'package:flutter/material.dart';

class SubjectDetailScreen extends StatelessWidget {
  static const String id = 'subject_detail_screen';
  final Map<String, dynamic> subjectData;

  const SubjectDetailScreen({super.key, required this.subjectData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subject Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              subjectData['교과목명'] ?? 'Unknown Subject',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('Code: ${subjectData['교과 코드'] ?? 'Unknown'}'),
            Text('Campus: ${subjectData['캠퍼스'] ?? 'Unknown'}'),
            Text('Lecturer: ${subjectData['담당교수'] ?? 'Unknown'}'),
            Text('Time: ${subjectData['시간'] ?? 'Unknown'}'),
            // Add more details as needed
          ],
        ),
      ),
    );
  }
}
