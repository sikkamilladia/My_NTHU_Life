import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

class GPAPredictor extends StatefulWidget {
  const GPAPredictor({super.key});

  @override
  State<GPAPredictor> createState() => _GPAPredictorState();
}

class _GPAPredictorState extends State<GPAPredictor> {
  final List<Map<String, dynamic>> _courses = [
    {'name': '', 'credits': 3, 'grade': 'A+'},
  ];

  final Map<String, double> _gradePoints = {
    'A+': 4.3,
    'A': 4.0,
    'A-': 3.7,
    'B+': 3.3,
    'B': 3.0,
    'B-': 2.7,
    'C+': 2.3,
    'C': 2.0,
    'C-': 1.7,
    'D': 1.0,
    'E': 0.0,
    'X': 0.0,
  };

  double _calculateGPA() {
    double totalPoints = 0;
    double totalCredits = 0;
    for (var course in _courses) {
      double credits = course['credits'].toDouble();
      double point = _gradePoints[course['grade']] ?? 0.0;
      totalPoints += (credits * point);
      totalCredits += credits;
    }
    return totalCredits == 0 ? 0.0 : totalPoints / totalCredits;
  }

  @override
  Widget build(BuildContext context) {
    final gpa = _calculateGPA();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'GPA Predictor',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'ESTIMATED GPA',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  gpa.toStringAsFixed(2),
                  style: GoogleFonts.outfit(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 10, bottom: 80),
              itemCount: _courses.length,
              itemBuilder: (context, index) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        TextField(
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Course Name (e.g. Calculus)',
                            hintStyle: TextStyle(color: Colors.white38),
                            border: InputBorder.none,
                            icon: Icon(Icons.book_outlined, size: 20),
                          ),
                          onChanged: (val) => _courses[index]['name'] = val,
                        ),
                        const Divider(color: Colors.white10),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: _courses[index]['credits'],
                                decoration: const InputDecoration(
                                  labelText: 'Credits',
                                ),
                                items: [1, 2, 3, 4]
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c,
                                        child: Text('$c'),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) => setState(
                                  () => _courses[index]['credits'] = val,
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _courses[index]['grade'],
                                decoration: const InputDecoration(
                                  labelText: 'Grade',
                                ),
                                items: _gradePoints.keys
                                    .map(
                                      (g) => DropdownMenuItem(
                                        value: g,
                                        child: Text(g),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) => setState(
                                  () => _courses[index]['grade'] = val,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              onPressed: () {
                                setState(() {
                                  if (_courses.length > 1)
                                    _courses.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 85),
        child: FloatingActionButton.extended(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
          onPressed: () => setState(
            () => _courses.add({'name': '', 'credits': 3, 'grade': 'A+'}),
          ),
          label: const Text('Add Subject'),
          icon: const Icon(Icons.add),
        ),
      ),
    );
  }
}
