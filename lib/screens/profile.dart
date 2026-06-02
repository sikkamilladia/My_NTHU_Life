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
  // Account Information Controllers & Data
  late TextEditingController _nameController;
  late TextEditingController _idController;
  bool _isEditing = false;
  String _currentName = "NTHU Scholar";
  String _currentStudentID = "";

  // Metric Stats Matrix data
  int _currentStreak = 0;
  int _completedTasks = 0;
  int _totalTasks = 0;
  double _currentGpa = 0.0;
  int _enrolledCredits = 0;
  bool _isLoading = true;

  // Task Activity Heatmap Map (String Date YYYY-MM-DD -> Count)
  Map<String, int> _activityHistory = {};

  @override
  void initState() {
    super.initState();
    _currentStudentID = widget.studentID;
    _nameController = TextEditingController(text: _currentName);
    _idController = TextEditingController(text: _currentStudentID);
    _loadAllMetrics();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    super.dispose();
  }

  Future<void> _loadAllMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _currentName =
          prefs.getString('profile_name_${widget.studentID}') ?? "NTHU Scholar";
      _currentStudentID =
          prefs.getString('profile_id_${widget.studentID}') ?? widget.studentID;

      _nameController.text = _currentName;
      _idController.text = _currentStudentID;

      // 1. Load Streak Data
      final petString = prefs.getString('streak_pet_${widget.studentID}');
      if (petString != null) {
        final Map<String, dynamic> petMap = jsonDecode(petString);
        _currentStreak = petMap['currentStreak'] ?? 0;
      }

      // 2. Load Tasks Completion Data
      final tasksString = prefs.getString('tasks_${widget.studentID}');
      Map<String, int> tempActivity = {};

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

                String dateKey = DateTime.now().toIso8601String().split('T')[0];
                if (task['completedDate'] != null) {
                  dateKey = task['completedDate'].toString().split('T')[0];
                } else if (task['dueDate'] != null) {
                  dateKey = task['dueDate'].toString().split('T')[0];
                }

                tempActivity[dateKey] = (tempActivity[dateKey] ?? 0) + 1;
              }
            }
          }
        });
        _totalTasks = total;
        _completedTasks = completed;
        _activityHistory = tempActivity;
      }

      // 3. Load Cumulative GPA
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

  Future<void> _saveProfileMeta() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'profile_name_${widget.studentID}',
        _nameController.text.trim(),
      );
      await prefs.setString(
        'profile_id_${widget.studentID}',
        _idController.text.trim(),
      );

      setState(() {
        _currentName = _nameController.text.trim();
        _currentStudentID = _idController.text.trim();
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Profile changes saved!",
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF7C3AED),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint("Error saving profile configurations: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const customDarkBackground = Color(0xFF121212);

    double consistencyVal = ((_currentStreak / 30) * 100).clamp(0.0, 100.0);
    double productivityVal = _totalTasks > 0
        ? ((_completedTasks / _totalTasks) * 100)
        : 0.0;
    double intelligenceVal = ((_currentGpa / 4.3) * 100).clamp(0.0, 100.0);
    double ambitionVal = ((_enrolledCredits / 25) * 100).clamp(0.0, 100.0);

    return Scaffold(
      backgroundColor: customDarkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 42,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton.icon(
              onPressed: () {
                if (_isEditing) {
                  _saveProfileMeta();
                } else {
                  setState(() {
                    _isEditing = true;
                  });
                }
              },
              icon: Icon(
                _isEditing
                    ? Icons.check_circle_outline_rounded
                    : Icons.edit_note_rounded,
                color: const Color(0xFF7C3AED),
                size: 18,
              ),
              label: Text(
                _isEditing ? "Save" : "Edit",
                style: GoogleFonts.outfit(
                  color: const Color(0xFF7C3AED),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 4.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Profile",
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: CircleAvatar(
                          radius: 38,
                          backgroundColor: const Color(
                            0xFF7C3AED,
                          ).withOpacity(0.12),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 42,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildFieldLabel("Name"),
                      const SizedBox(height: 4),
                      _buildEditableBlock(
                        controller: _nameController,
                        isEditable: _isEditing,
                        hintText: "Enter your name",
                      ),
                      const SizedBox(height: 14),

                      _buildFieldLabel("Student ID"),
                      const SizedBox(height: 4),
                      _buildEditableBlock(
                        controller: _idController,
                        isEditable: _isEditing,
                        hintText: "Enter student ID",
                      ),
                      const SizedBox(height: 14),

                      _buildFieldLabel("Identity"),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.04),
                          ),
                        ),
                        child: Text(
                          "NTHU Elite Student",
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      Text(
                        "Student Stats Matrix",
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: RadarChart(
                          RadarChartData(
                            radarShape: RadarShape.polygon,
                            isMinValueAtCenter: true,
                            dataSets: [
                              RadarDataSet(
                                fillColor: const Color(
                                  0xFF7C3AED,
                                ).withOpacity(0.18),
                                borderColor: const Color(0xFF7C3AED),
                                borderWidth: 2.0,
                                entryRadius: 3.5,
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
                              color: Colors.white.withOpacity(0.08),
                              width: 1,
                            ),
                            radarBorderData: BorderSide(
                              color: Colors.white.withOpacity(0.15),
                              width: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ===== THE PERFECTLY ALIGNED CALENDAR MODE HEATMAP GRID =====
                      _buildPerfectHeatmapCard(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildPerfectHeatmapCard() {
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;

    // 1. Calculate properties for the current month tracking calendar
    final firstDayOfMonth = DateTime(currentYear, currentMonth, 1);
    final lastDayOfMonth = DateTime(currentYear, currentMonth + 1, 0);

    final totalDaysInMonth = lastDayOfMonth.day;
    // Align weekday index (Convert 1-7 Mon-Sun chain to 0-6 Sun-Sat index system)
    final int aheadPaddingDays = firstDayOfMonth.weekday == 7
        ? 0
        : firstDayOfMonth.weekday;

    final weekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final monthNames = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];

    // 2. Aggregate actual completions metrics strictly inside this calendar month
    int totalCompletedInMonth = 0;
    for (int day = 1; day <= totalDaysInMonth; day++) {
      final dateStr = DateTime(
        currentYear,
        currentMonth,
        day,
      ).toIso8601String().split('T')[0];
      totalCompletedInMonth += _activityHistory[dateStr] ?? 0;
    }

    // 3. Compose inline list nodes sequence
    List<Widget> calendarSquares = [];

    // Prepend placeholder structures prior to the start of the first week day
    for (int p = 0; p < aheadPaddingDays; p++) {
      calendarSquares.add(
        Expanded(
          child: Container(
            height: 32,
            margin: const EdgeInsets.all(3.0),
            color: Colors.transparent,
          ),
        ),
      );
    }

    // Map through the days of the ongoing month sequentially
    for (int day = 1; day <= totalDaysInMonth; day++) {
      final blockDate = DateTime(currentYear, currentMonth, day);
      final dateStr = blockDate.toIso8601String().split('T')[0];
      final doneCount = _activityHistory[dateStr] ?? 0;

      double opacity = 0.04;
      if (doneCount > 0) {
        opacity = (0.25 + (doneCount * 0.25)).clamp(0.25, 1.0);
      }

      final bool isToday = day == now.day;

      calendarSquares.add(
        Expanded(
          child: Tooltip(
            message: "$dateStr : $doneCount done",
            preferBelow: false,
            textStyle: GoogleFonts.outfit(fontSize: 11, color: Colors.white),
            decoration: BoxDecoration(
              color: const Color(0xFF2E2E2E),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Container(
              height: 32,
              margin: const EdgeInsets.all(3.0),
              decoration: BoxDecoration(
                color: doneCount > 0
                    ? const Color(0xFF7C3AED).withOpacity(opacity)
                    : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isToday
                      ? const Color(0xFF7C3AED)
                      : Colors.white.withOpacity(0.02),
                  width: isToday ? 1.5 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  "$day",
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                    color: doneCount > 0
                        ? Colors.white
                        : (isToday
                              ? const Color(0xFF7C3AED)
                              : Colors.grey.shade500),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Fill lingering trailing row blocks elements to prevent wrapping layout breakage
    int totalItems = calendarSquares.length;
    int missingSlots = (7 - (totalItems % 7)) % 7;
    for (int m = 0; m < missingSlots; m++) {
      calendarSquares.add(
        Expanded(
          child: Container(
            height: 32,
            margin: const EdgeInsets.all(3.0),
            color: Colors.transparent,
          ),
        ),
      );
    }

    // 4. Fragment blocks elements chain array list strictly into chunks of 7 days per row
    List<Widget> calendarRows = [];
    for (int i = 0; i < calendarSquares.length; i += 7) {
      calendarRows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: calendarSquares.sublist(i, i + 7),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "${monthNames[currentMonth - 1]} $currentYear",
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "$totalCompletedInMonth completions this month",
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: weekdayLabels.map((label) {
              return Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade600,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          Column(mainAxisSize: MainAxisSize.min, children: calendarRows),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Less",
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              _buildLegendBox(Colors.white.withOpacity(0.05)),
              _buildLegendBox(const Color(0xFF7C3AED).withOpacity(0.3)),
              _buildLegendBox(const Color(0xFF7C3AED).withOpacity(0.6)),
              _buildLegendBox(const Color(0xFF7C3AED).withOpacity(1.0)),
              const SizedBox(width: 6),
              Text(
                "More",
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendBox(Color color) {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 2.5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade500,
      ),
    );
  }

  Widget _buildEditableBlock({
    required TextEditingController controller,
    required bool isEditable,
    required String hintText,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 120),
      child: isEditable
          ? TextField(
              controller: controller,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              cursorColor: const Color(0xFF7C3AED),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: GoogleFonts.outfit(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: const Color(0xFF7C3AED).withOpacity(0.35),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF7C3AED),
                    width: 1.5,
                  ),
                ),
              ),
            )
          : Container(
              key: ValueKey<String>(controller.text),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.04)),
              ),
              child: Text(
                controller.text.isEmpty ? hintText : controller.text,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: controller.text.isEmpty
                      ? Colors.grey.shade600
                      : Colors.white,
                ),
              ),
            ),
    );
  }
}
