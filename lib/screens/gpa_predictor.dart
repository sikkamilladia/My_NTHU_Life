import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

class GPAPredictor extends StatefulWidget {
  final String studentID;

  const GPAPredictor({super.key, required this.studentID});

  @override
  State<GPAPredictor> createState() => _GPAPredictorState();
}

class _GPAPredictorState extends State<GPAPredictor> {
  List<Map<String, dynamic>> _courses = [];

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

  @override
  void initState() {
    super.initState();
    loadCoursesFromCredit().then((_) {
      loadGrades();
    });
  }

  // LOAD COURSE
  Future<void> loadCoursesFromCredit() async {
    final prefs = await SharedPreferences.getInstance();
    String? encoded = prefs.getString("Semesters_${widget.studentID}");

    if (encoded != null) {
      final List<dynamic> decodedData = jsonDecode(encoded);

      List<Map<String, dynamic>> allCourses = [];

      for (var sem in decodedData) {
        List courses = sem['courses'];

        for (var course in courses) {
          allCourses.add({
            'name': course['name'] ?? 'Unknown',
            'credits': (course['credits'] ?? 0),
            'grade': null,
          });
        }
      }

      setState(() {
        _courses = allCourses;
      });
    }
  }

  // SAVE GRADE
  Future<void> saveGrades() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      "Grades_${widget.studentID}",
      jsonEncode(_courses),
    );
  }

  // LOAD GRADE
  Future<void> loadGrades() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString("Grades_${widget.studentID}");

    if (data != null) {
      List<Map<String, dynamic>> saved =
          List<Map<String, dynamic>>.from(jsonDecode(data));

      for (int i = 0; i < _courses.length; i++) {
        if (i < saved.length) {
          _courses[i]['grade'] = saved[i]['grade'];
        }
      }

      setState(() {});
    }
  }

  // CALCULATE GPA
  double _calculateGPA() {
    double totalPoints = 0;
    double totalCredits = 0;

    for (var course in _courses) {
      if (course['grade'] == null) continue;

      double credits = (course['credits'] as num).toDouble();
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
          // GPA DISPLAY
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

          // COURSE LIST
          Expanded(
            child: _courses.isEmpty
                ? const Center(child: Text("No courses found 😢"))
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 10, bottom: 80),
                    itemCount: _courses.length,
                    itemBuilder: (context, index) {
                      return Card(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              // COURSE NAME
                              Text(
                                _courses[index]['name'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                ),
                              ),

                              const Divider(),

                              Row(
                                children: [
                                  // CREDITS
                                  Expanded(
                                    child: Text(
                                      "${_courses[index]['credits']} credits",
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                  ),

                                  // DROPDOWN
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value:
                                          _courses[index]['grade'],
                                      dropdownColor: Theme.of(context)
                                          .colorScheme
                                          .surface,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                      hint: Text(
                                        '-',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                      items: _gradePoints.keys
                                          .map((g) {
                                        return DropdownMenuItem(
                                          value: g,
                                          child: Text(g),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          _courses[index]['grade'] =
                                              val;
                                        });
                                        saveGrades();
                                      },
                                    ),
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
    );
  }
}