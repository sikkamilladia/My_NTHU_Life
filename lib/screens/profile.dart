import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  final String studentID;

  const ProfileScreen({super.key, required this.studentID});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _currentStreak = 0;
  int _completedTasks = 0;
  int _totalTasks = 0;
  double _currentGpa = 0.0;
  int _enrolledCredits = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllMetrics();
  }

  Future<void> _loadAllMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Load Streak Data from Pet Profile
      final petString = prefs.getString('streak_pet_${widget.studentID}');
      if (petString != null) {
        final Map<String, dynamic> petMap = jsonDecode(petString);
        _currentStreak = petMap['currentStreak'] ?? 0;
      }

      // 2. Load Tasks Completion Data
      final tasksString = prefs.getString('tasks_${widget.studentID}');
      if (tasksString != null) {
        final Map<String, dynamic> coursesMap = jsonDecode(tasksString);
        int total = 0;
        int completed = 0;
        coursesMap.forEach((courseName, taskList) {
          if (taskList is List) {
            for (var task in taskList) {
              total++;
              if (task['isDone'] == true) {
                completed++;
              }
            }
          }
        });
        _totalTasks = total;
        _completedTasks = completed;
      }

      // 3. Load Cumulative GPA from Predictor Profiles
      final gpaString = prefs.getString('gpa_courses_${widget.studentID}');
      if (gpaString != null) {
        final List<dynamic> decodedGpa = jsonDecode(gpaString);
        double totalPoints = 0;
        int totalCreditsWithGrades = 0;

        final Map<String, double> gradePoints = {
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

        for (var course in decodedGpa) {
          final String? grade = course['grade'];
          final int credits = course['credits'] ?? 0;
          if (grade != null && grade != '-' && gradePoints.containsKey(grade)) {
            totalPoints += (gradePoints[grade]! * credits);
            totalCreditsWithGrades += credits;
          }
        }
        _currentGpa = totalCreditsWithGrades > 0
            ? (totalPoints / totalCreditsWithGrades)
            : 0.0;
      }

      // 4. Load Enrolled Semester Credits
      final semestersString = prefs.getString('Semesters_${widget.studentID}');
      if (semestersString != null) {
        final List<dynamic> decodedSemesters = jsonDecode(semestersString);
        int creditsAccumulator = 0;
        for (var semester in decodedSemesters) {
          if (semester['courses'] != null) {
            for (var course in semester['courses']) {
              creditsAccumulator += (course['credits'] as num).toInt();
            }
          }
        }
        _enrolledCredits = creditsAccumulator;
      }
    } catch (e) {
      debugPrint("Error collecting radar data metrics: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Normalize values between 0.0 and 100.0
    double consistencyVal = ((_currentStreak / 30) * 100).clamp(0.0, 100.0);
    double productivityVal = _totalTasks > 0
        ? ((_completedTasks / _totalTasks) * 100)
        : 0.0;
    double intelligenceVal = ((_currentGpa / 4.3) * 100).clamp(0.0, 100.0);
    double ambitionVal = ((_enrolledCredits / 25) * 100).clamp(0.0, 100.0);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Profile",
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 46,
                              backgroundColor: const Color(
                                0xFF7C3AED,
                              ).withOpacity(0.1),
                              child: const Icon(
                                Icons.person_rounded,
                                size: 52,
                                color: Color(0xFF7C3AED),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),
                      _buildFieldLabel("Student ID"),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant.withOpacity(
                            0.15,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withOpacity(
                              0.2,
                            ),
                          ),
                        ),
                        child: Text(
                          widget.studentID,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildFieldLabel("Identity"),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant.withOpacity(
                            0.15,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withOpacity(
                              0.2,
                            ),
                          ),
                        ),
                        child: Text(
                          "NTHU Elite Student",
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        "Student Stats Matrix",
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 260,
                        width: double.infinity,
                        child: RadarChart(
                          RadarChartData(
                            radarShape: RadarShape.polygon,
                            isMinValueAtCenter: true,
                            dataSets: [
                              RadarDataSet(
                                fillColor: const Color(
                                  0xFF7C3AED,
                                ).withOpacity(0.2),
                                borderColor: const Color(0xFF7C3AED),
                                borderWidth: 2.5,
                                entryRadius: 4,
                                dataEntries: [
                                  RadarEntry(value: consistencyVal),
                                  RadarEntry(value: productivityVal),
                                  RadarEntry(value: intelligenceVal),
                                  RadarEntry(value: ambitionVal),
                                ],
                              ),
                            ],
                            getTitle: (index, angle) {
                              switch (index) {
                                case 0:
                                  return RadarChartTitle(
                                    text: 'Consistency 🔥',
                                    angle: angle,
                                  );
                                case 1:
                                  return RadarChartTitle(
                                    text: 'Productivity ⚡',
                                    angle: angle,
                                  );
                                case 2:
                                  return RadarChartTitle(
                                    text: 'Intelligence 🧠',
                                    angle: angle,
                                  );
                                case 3:
                                  return RadarChartTitle(
                                    text: 'Ambition 🎯',
                                    angle: angle,
                                  );
                                default:
                                  return const RadarChartTitle(text: '');
                              }
                            },
                            tickCount: 4,
                            ticksTextStyle: const TextStyle(
                              color: Colors.transparent,
                            ),
                            gridBorderData: BorderSide(
                              color: theme.colorScheme.outlineVariant
                                  .withOpacity(0.4),
                              width: 1,
                            ),
                            radarBorderData: BorderSide(
                              color: theme.colorScheme.outlineVariant
                                  .withOpacity(0.7),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade500,
      ),
    );
  }
}
