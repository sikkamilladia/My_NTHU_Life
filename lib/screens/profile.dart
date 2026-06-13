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
  late TextEditingController _nameController;
  late TextEditingController _idController;
  bool _isEditing = false;
  String _currentName = "NTHU Scholar";
  String _currentStudentID = "";

  int _currentStreak = 0;
  int _completedTasks = 0;
  int _totalTasks = 0;
  double _currentGpa = 0.0;
  int _enrolledCredits = 0;
  bool _isLoading = true;

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

      final petString = prefs.getString('streak_pet_${widget.studentID}');
      if (petString != null) {
        final Map<String, dynamic> petMap = jsonDecode(petString);
        _currentStreak = petMap['currentStreak'] ?? 0;
      }

      final tasksString = prefs.getString('tasks_${widget.studentID}');
      Map<String, int> tempActivity = {};
      if (tasksString != null) {
        final Map<String, dynamic> coursesMap = jsonDecode(tasksString);
        int total = 0, completed = 0;
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

      final gpaString = prefs.getString('gpa_courses_${widget.studentID}');
      if (gpaString != null) {
        final List<dynamic> decodedGpa = jsonDecode(gpaString);
        const gradePoints = {
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
        double totalPoints = 0;
        int totalCreditsWithGrades = 0;
        for (var course in decodedGpa) {
          final String? grade = course['grade'];
          final int credits = course['credits'] ?? 0;
          if (grade != null && grade != '-' && gradePoints.containsKey(grade)) {
            totalPoints += (gradePoints[grade]! * credits);
            totalCreditsWithGrades += credits;
          }
        }
        _currentGpa = totalCreditsWithGrades > 0
            ? totalPoints / totalCreditsWithGrades
            : 0.0;
      }

      final semestersString = prefs.getString('Semesters_${widget.studentID}');
      if (semestersString != null) {
        final List<dynamic> decodedSemesters = jsonDecode(semestersString);
        int credits = 0;
        for (var semester in decodedSemesters) {
          if (semester['courses'] != null) {
            for (var course in semester['courses']) {
              credits += (course['credits'] as num).toInt();
            }
          }
        }
        _enrolledCredits = credits;
      }
    } catch (e) {
      debugPrint("Error loading profile metrics: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Profile updated.",
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF7B2CBF),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error saving profile: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final consistencyVal = ((_currentStreak / 30) * 100).clamp(0.0, 100.0);
    final productivityVal = _totalTasks > 0
        ? ((_completedTasks / _totalTasks) * 100).clamp(0.0, 100.0)
        : 0.0;
    final intelligenceVal = ((_currentGpa / 4.3) * 100).clamp(0.0, 100.0);
    final ambitionVal = ((_enrolledCredits / 25) * 100).clamp(0.0, 100.0);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: cs.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "PROFILE",
          style: GoogleFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () {
                if (_isEditing) {
                  _saveProfileMeta();
                } else {
                  setState(() => _isEditing = true);
                }
              },
              icon: Icon(
                _isEditing
                    ? Icons.check_circle_outline_rounded
                    : Icons.edit_note_rounded,
                color: cs.primaryContainer,
                size: 18,
              ),
              label: Text(
                _isEditing ? "SAVE" : "EDIT",
                style: GoogleFonts.orbitron(
                  color: cs.primaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: cs.primaryContainer))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── AVATAR + ID CARD ──────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cs.outlineVariant, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cs.surfaceBright.withOpacity(0.4),
                            border: Border.all(
                              color: cs.primaryContainer.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            size: 32,
                            color: cs.primaryContainer,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "IDENTITY",
                                style: GoogleFonts.orbitron(
                                  fontSize: 9,
                                  color: cs.inversePrimary,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _currentName,
                                style: GoogleFonts.orbitron(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.studentID,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: cs.outline.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: cs.outline.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'NTHU',
                            style: GoogleFonts.orbitron(
                              fontSize: 9,
                              color: cs.primaryContainer,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── EDIT FIELDS (visible only when editing) ───────────────
                  if (_isEditing) ...[
                    _sectionLabel(cs, "EDIT INFO"),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: cs.outlineVariant,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          _themedTextField(
                            cs,
                            controller: _nameController,
                            label: "Name",
                          ),
                          // const SizedBox(height: 12),
                          // _themedTextField(
                          //   cs,
                          //   controller: _idController,
                          //   label: "Student ID",
                          // ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── STAT CHIPS ────────────────────────────────────────────
                  _sectionLabel(cs, "QUICK STATS"),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 2.8,
                    children: [
                      _statChip(
                        cs,
                        icon: Icons.local_fire_department_rounded,
                        iconColor: Colors.orange,
                        label: "Streak",
                        value: "$_currentStreak days",
                      ),
                      _statChip(
                        cs,
                        icon: Icons.task_alt_rounded,
                        iconColor: Colors.greenAccent.shade400,
                        label: "Completed",
                        value: "$_completedTasks / $_totalTasks",
                      ),
                      _statChip(
                        cs,
                        icon: Icons.trending_up_rounded,
                        iconColor: cs.primaryContainer,
                        label: "GPA",
                        value: _currentGpa.toStringAsFixed(2),
                      ),
                      _statChip(
                        cs,
                        icon: Icons.menu_book_rounded,
                        iconColor: Colors.lightBlueAccent,
                        label: "Credits",
                        value: "$_enrolledCredits CR",
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── RADAR CHART ───────────────────────────────────────────
                  _sectionLabel(cs, "STATS MATRIX"),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cs.outlineVariant, width: 1.5),
                    ),
                    child: SizedBox(
                      height: 220,
                      child: RadarChart(
                        RadarChartData(
                          radarShape: RadarShape.polygon,
                          isMinValueAtCenter: true,
                          dataSets: [
                            RadarDataSet(
                              fillColor: cs.primaryContainer.withOpacity(0.15),
                              borderColor: cs.primaryContainer,
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
                            const titles = [
                              'Consistency 🔥',
                              'Productivity ⚡',
                              'Intelligence 🧠',
                              'Ambition 🎯',
                            ];
                            return RadarChartTitle(
                              text: titles[index],
                              angle: angle,
                            );
                          },
                          tickCount: 4,
                          ticksTextStyle: const TextStyle(
                            color: Colors.transparent,
                          ),
                          gridBorderData: BorderSide(
                            color: cs.outlineVariant.withOpacity(0.4),
                            width: 1,
                          ),
                          radarBorderData: BorderSide(
                            color: cs.outlineVariant,
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── ACTIVITY HEATMAP ──────────────────────────────────────
                  _sectionLabel(cs, "ACTIVITY LOG"),
                  const SizedBox(height: 10),
                  _buildHeatmap(cs),
                ],
              ),
            ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _sectionLabel(ColorScheme cs, String text) {
    return Text(
      text,
      style: GoogleFonts.orbitron(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: cs.inversePrimary,
        letterSpacing: 1,
      ),
    );
  }

  Widget _statChip(
    ColorScheme cs, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: cs.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.orbitron(
                    color: cs.onSurface,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _themedTextField(
    ColorScheme cs, {
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      style: GoogleFonts.outfit(color: cs.onSurface, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(
          color: cs.onSurfaceVariant,
          fontSize: 12,
        ),
        filled: true,
        fillColor: cs.surfaceContainerHigh,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.primaryContainer, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildHeatmap(ColorScheme cs) {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final totalDays = lastDay.day;
    final paddingDays = firstDay.weekday == 7 ? 0 : firstDay.weekday;

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

    int totalDone = 0;
    for (int d = 1; d <= totalDays; d++) {
      final key = DateTime(
        now.year,
        now.month,
        d,
      ).toIso8601String().split('T')[0];
      totalDone += _activityHistory[key] ?? 0;
    }

    List<Widget> squares = [];
    for (int p = 0; p < paddingDays; p++) {
      squares.add(
        Expanded(
          child: Container(
            height: 32,
            margin: const EdgeInsets.all(3),
            color: Colors.transparent,
          ),
        ),
      );
    }

    for (int day = 1; day <= totalDays; day++) {
      final dateStr = DateTime(
        now.year,
        now.month,
        day,
      ).toIso8601String().split('T')[0];
      final count = _activityHistory[dateStr] ?? 0;
      final isToday = day == now.day;
      final opacity = count > 0 ? (0.25 + count * 0.25).clamp(0.25, 1.0) : 0.0;

      squares.add(
        Expanded(
          child: Container(
            height: 32,
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: count > 0
                  ? cs.primaryContainer.withOpacity(opacity)
                  : cs.surfaceContainerHigh.withOpacity(0.5),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isToday
                    ? cs.primaryContainer
                    : cs.outlineVariant.withOpacity(0.3),
                width: isToday ? 1.5 : 1,
              ),
            ),
            child: Center(
              child: Text(
                "$day",
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.w400,
                  color: count > 0
                      ? Colors.white
                      : (isToday
                            ? cs.primaryContainer
                            : cs.onSurfaceVariant.withOpacity(0.5)),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final trailing = (7 - (squares.length % 7)) % 7;
    for (int m = 0; m < trailing; m++) {
      squares.add(
        Expanded(
          child: Container(
            height: 32,
            margin: const EdgeInsets.all(3),
            color: Colors.transparent,
          ),
        ),
      );
    }

    List<Widget> rows = [];
    for (int i = 0; i < squares.length; i += 7) {
      rows.add(Row(children: squares.sublist(i, i + 7)));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${monthNames[now.month - 1].toUpperCase()} ${now.year}",
                style: GoogleFonts.orbitron(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              Text(
                "$totalDone completions",
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map(
                  (l) => Expanded(
                    child: Text(
                      l,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.orbitron(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurfaceVariant.withOpacity(0.5),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 6),
          ...rows,
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Less",
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 6),
              ...[0.0, 0.3, 0.6, 1.0].map(
                (o) => Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: o == 0.0
                        ? cs.surfaceContainerHigh.withOpacity(0.5)
                        : cs.primaryContainer.withOpacity(o),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                "More",
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
