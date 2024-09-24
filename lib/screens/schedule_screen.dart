import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SchedulePage extends StatelessWidget {
  static const String id = 'schedule_screen';
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.all(1.0),
          child: Table(
            border: TableBorder.all(color: Colors.grey),
            columnWidths: const {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
              4: FlexColumnWidth(1),
              5: FlexColumnWidth(1),
              6: FlexColumnWidth(1),
              7: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                children: [
                  _buildTableHeader('시간'),
                  _buildTableHeader('Mon'),
                  _buildTableHeader('Tue'),
                  _buildTableHeader('Wed'),
                  _buildTableHeader('Thu'),
                  _buildTableHeader('Fri'),
                  _buildTableHeader('Sat'),
                  _buildTableHeader('Sun'),
                ],
              ),
              ..._buildTimeSlots(),
            ],
          ),
        ),
      ),
    );
  }

  List<TableRow> _buildTimeSlots() {
    List<TableRow> rows = [];
    DateTime startTime = DateTime(2022, 1, 1, 8, 0); // Start at 8:00 AM
    DateTime endTime = DateTime(2022, 1, 1, 22, 35); // End at 10:35 PM

    while (startTime.isBefore(endTime) || startTime == endTime) {
      rows.add(
        TableRow(
          children: [
            _buildTableCell(
              '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
            ),
            ...List<Widget>.generate(7, (i) => _buildTableCell('')),
          ],
        ),
      );
      startTime = startTime.add(const Duration(minutes: 30));
    }

    return rows;
  }

  Widget _buildTableHeader(String text) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.blue.shade100,
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.lobster(textStyle: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Container(
      padding: const EdgeInsets.all(3.0),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}
