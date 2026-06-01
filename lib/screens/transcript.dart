import 'package:flutter/material.dart';
import 'package:my_nthu_life/screens/gpa_calculator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_nthu_life/data/semester.dart';
import 'package:my_nthu_life/main.dart';
import 'package:my_nthu_life/screens/study.dart';
import 'package:my_nthu_life/services/firestore_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class CreditPage extends StatefulWidget {
  final String studentID;
  const CreditPage({super.key, required this.studentID});

  @override
  State<CreditPage> createState() => _CreditPageState();
}

class _CreditPageState extends State<CreditPage> {
  // ===== ACCENT COLORS =====
  static const purpleMain = Color(0xFF7C3AED);
  static const purpleDark = Color(0xFF6D28D9);
  static const purpleLight = Color(0xFFA78BFA);

  final int graduationCredits = 128;
  final FirestoreService _firestoreService = FirestoreService();

  List<Semester> semesters = [
    Semester(semesterName: "Semester 1", courses: []),
  ];
  int currentSemesterIndex = 0;

  @override
  void initState() {
    super.initState();
    loadCourses();
  }

  // ===== STORAGE =====
  Future<void> saveCourses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      "Semesters_${widget.studentID}",
      jsonEncode(semesters.map((e) => e.toJson()).toList()),
    );
    totalCreditsNotifier.value = totalCredits;
  }

  Future<void> loadCourses() async {
    // 1. Quick local storage fallback
    final prefs = await SharedPreferences.getInstance();
    String? encoded = prefs.getString("Semesters_${widget.studentID}");
    if (encoded != null) {
      final List<dynamic> decodedData = jsonDecode(encoded);
      setState(() {
        semesters = decodedData.map((item) => Semester.fromJson(item)).toList();
      });
      totalCreditsNotifier.value = totalCredits;
    }

    // 2. Fetch ground truth from Firebase Cloud Firestore and sort them
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.studentID)
          .get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;

        if (data['courses'] != null) {
          final Map<String, dynamic> cloudCourses = data['courses'];

          // Clear out existing local course listings to prepare for fresh cloud sorting slots
          List<Semester> freshSemesters = [
            Semester(semesterName: "Semester 1", courses: []),
          ];

          cloudCourses.forEach((courseCode, courseData) {
            final String targetSemesterName =
                courseData['semester'] ?? 'Semester 1';

            // Find if the semester block already exists in our temporary list
            int semIndex = freshSemesters.indexWhere(
              (s) => s.semesterName == targetSemesterName,
            );

            // If the semester doesn't exist yet, create it!
            if (semIndex == -1) {
              freshSemesters.add(
                Semester(semesterName: targetSemesterName, courses: []),
              );
              semIndex = freshSemesters.length - 1;
            }

            // Pack the course item into its matching targeted semester bucket
            freshSemesters[semIndex].courses.add({
              'code': courseCode,
              'name': courseData['courseName'] ?? '',
              'credits': courseData['credits'] ?? 0,
              'grade': courseData['grade'] ?? '–',
            });
          });

          // Sort semesters chronologically by name so Semester 1 is always first
          freshSemesters.sort(
            (a, b) => a.semesterName.compareTo(b.semesterName),
          );

          setState(() {
            semesters = freshSemesters;
            // Prevent the app from crashing if current semester index falls out of bounds
            if (currentSemesterIndex >= semesters.length) {
              currentSemesterIndex = semesters.length - 1;
            }
          });

          // Overwrite the local cache with the newly sorted cloud data structure
          await saveCourses();
        }
      }
    } catch (e) {
      debugPrint("Error pulling data down from Firebase: $e");
    }
  }

  // ===== CALCULATION =====
  int get totalCredits {
    int sum = 0;
    for (var sem in semesters) {
      for (var course in sem.courses) {
        sum += (course['credits'] as num).toInt();
      }
    }
    return sum;
  }

  Semester get currentSemester => semesters[currentSemesterIndex];

  int get semesterCredits {
    int sum = 0;
    for (var course in currentSemester.courses) {
      sum += (course['credits'] as num).toInt();
    }
    return sum;
  }

  double get semesterGPA {
    if (currentSemester.courses.isEmpty) return 0;
    final gradeMapping = {
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
      'F': 0.0,
    };
    double totalPoints = 0;
    int totalCreds = 0;
    for (var course in currentSemester.courses) {
      final grade = course['grade'] ?? 'F';
      final credits = (course['credits'] as num).toInt();
      totalPoints += (gradeMapping[grade] ?? 0) * credits;
      totalCreds += credits;
    }
    return totalCreds > 0 ? totalPoints / totalCreds : 0;
  }

  String getLetterGrade(double gpa) {
    if (gpa >= 4.3) return 'A+';
    if (gpa >= 4.0) return 'A';
    if (gpa >= 3.7) return 'A-';
    if (gpa >= 3.3) return 'B+';
    if (gpa >= 3.0) return 'B';
    if (gpa >= 2.7) return 'B-';
    if (gpa >= 2.3) return 'C+';
    if (gpa >= 2.0) return 'C';
    if (gpa >= 1.7) return 'C-';
    if (gpa >= 1.0) return 'D';
    return 'F';
  }

  void addCourse(String name, String code, int credits, String grade) {
    setState(() {
      semesters[currentSemesterIndex].courses.add({
        'name': name,
        'code': code,
        'credits': credits,
        'grade': grade,
      });
    });
    saveCourses();

    final String cleanCourseCode = code.trim().isNotEmpty
        ? code.trim()
        : name.trim().replaceAll(' ', '_');

    _firestoreService.saveOrUpdateCourse(
      uid: widget.studentID,
      semesterName: currentSemester.semesterName,
      courseCode: cleanCourseCode,
      courseName: name,
      grade: grade,
      credits: credits,
    );
  }

  void showAddCourseDialog() {
    String name = "";
    String code = "";
    String creditInput = "";
    String selectedGrade = "A+";
    final grades = [
      'A+',
      'A',
      'A-',
      'B+',
      'B',
      'B-',
      'C+',
      'C',
      'C-',
      'D',
      'F',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final cs = Theme.of(context).colorScheme;
            return Dialog(
              backgroundColor: cs.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Add Course",
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _dialogTextField(
                      context,
                      "Course Name",
                      onChanged: (v) => name = v,
                    ),
                    const SizedBox(height: 12),
                    _dialogTextField(
                      context,
                      "Course Code",
                      onChanged: (v) => code = v,
                    ),
                    const SizedBox(height: 12),
                    _dialogTextField(
                      context,
                      "Credits",
                      keyboardType: TextInputType.number,
                      onChanged: (v) => creditInput = v,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedGrade,
                          isExpanded: true,
                          dropdownColor: cs.surfaceContainerHigh,
                          style: TextStyle(color: cs.onSurface),
                          items: grades
                              .map(
                                (g) =>
                                    DropdownMenuItem(value: g, child: Text(g)),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setDialogState(() => selectedGrade = v!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: purpleMain,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              final credits = int.tryParse(creditInput);
                              if (name.isNotEmpty && credits != null) {
                                addCourse(name, code, credits, selectedGrade);
                              }
                              Navigator.pop(context);
                            },
                            child: const Text("Add"),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cs.surfaceContainerHighest,
                              foregroundColor: cs.onSurfaceVariant,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _dialogTextField(
    BuildContext context,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    required Function(String) onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      keyboardType: keyboardType,
      style: TextStyle(color: cs.onSurface),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(color: cs.onSurfaceVariant),
        filled: true,
        fillColor: cs.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: purpleMain),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final gpa = semesterGPA;

    final containerBg = cs.surfaceContainerLow;
    final containerBorder = cs.onSurface.withOpacity(0.10);
    final purpleOverlay = purpleMain.withOpacity(0.20);
    final purpleOverlayLight = purpleMain.withOpacity(0.15);

    return Scaffold(
      backgroundColor: cs.surface,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  GpaCalculatorPage(), // 👈 Pointed cleanly to GPAPredictor in study.dart
            ),
          ),
          backgroundColor: purpleMain,
          foregroundColor: Colors.white,
          tooltip: "GPA Calculator",
          child: const Icon(Icons.calculate_rounded),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.menu_book, color: purpleLight, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      "Transcript",
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: purpleOverlay,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: purpleMain.withOpacity(0.30)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.emoji_events,
                        color: Colors.amber.shade400,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${semesters.fold(0, (sum, s) => sum + s.courses.length)} courses",
                        style: TextStyle(
                          color: Colors.amber.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: containerBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: containerBorder),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total Credits",
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        "$totalCredits/$graduationCredits",
                        style: const TextStyle(color: purpleMain, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: (totalCredits / graduationCredits).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: containerBorder,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        purpleMain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ===== NEW COMBINED SEMESTER ROW WITH ADD BUTTON =====
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    if (currentSemesterIndex > 0) {
                      setState(() => currentSemesterIndex--);
                    }
                  },
                  icon: Icon(Icons.chevron_left, color: cs.onSurfaceVariant),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: purpleOverlayLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: purpleMain.withOpacity(0.30)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      currentSemester.semesterName,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (currentSemesterIndex < semesters.length - 1) {
                      setState(() => currentSemesterIndex++);
                    } else {
                      setState(() {
                        semesters.add(
                          Semester(
                            semesterName: "Semester ${semesters.length + 1}",
                            courses: [],
                          ),
                        );
                        currentSemesterIndex = semesters.length - 1;
                      });
                      saveCourses();
                    }
                  },
                  icon: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purpleMain,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onPressed: showAddCourseDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text(
                    "Add",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 3.5,
              children: [
                _statCard(
                  context,
                  icon: Icons.menu_book,
                  iconColor: purpleLight,
                  iconBg: purpleOverlay,
                  label: "Credits",
                  value: "$semesterCredits",
                ),
                _statCard(
                  context,
                  icon: Icons.trending_up,
                  iconColor: Colors.green.shade400,
                  iconBg: Colors.green.withOpacity(0.15),
                  label: "GPA",
                  value: currentSemester.courses.isEmpty
                      ? "0.00"
                      : "${gpa.toStringAsFixed(2)} (${getLetterGrade(gpa)})",
                ),
                _statCard(
                  context,
                  icon: Icons.school,
                  iconColor: Colors.blue.shade300,
                  iconBg: Colors.blue.withOpacity(0.12),
                  label: "T-Score",
                  value: "–",
                ),
                _statCard(
                  context,
                  icon: Icons.emoji_events,
                  iconColor: Colors.amber.shade400,
                  iconBg: Colors.amber.withOpacity(0.12),
                  label: "Rank",
                  value: "–",
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (currentSemester.courses.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.menu_book,
                        size: 40,
                        color: cs.onSurfaceVariant.withOpacity(0.4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "No courses for this semester",
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...currentSemester.courses.asMap().entries.map((entry) {
                final course = entry.value;
                final grade = course['grade'] ?? '–';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: containerBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: containerBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: purpleOverlay,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.menu_book,
                            color: purpleMain,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course['name'] ?? '',
                                style: TextStyle(
                                  color: cs.onSurface,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                course['code'] ?? 'Course Code',
                                style: TextStyle(
                                  color: cs.onSurfaceVariant.withOpacity(0.6),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Credits",
                              style: TextStyle(
                                color: cs.onSurfaceVariant.withOpacity(0.7),
                                fontSize: 9,
                              ),
                            ),
                            Text(
                              "${course['credits']}",
                              style: TextStyle(
                                color: cs.onSurface,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [purpleMain, purpleDark],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: purpleMain.withOpacity(0.4),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            grade,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: cs.onSurfaceVariant.withOpacity(0.5),
                            size: 18,
                          ),
                          onPressed: () {
                            final removedCourse =
                                currentSemester.courses[entry.key];
                            final String targetCode =
                                (removedCourse['code'] != null &&
                                    removedCourse['code'].toString().isNotEmpty)
                                ? removedCourse['code']
                                : removedCourse['name'].toString().replaceAll(
                                    ' ',
                                    '_',
                                  );

                            setState(
                              () => currentSemester.courses.removeAt(entry.key),
                            );
                            saveCourses();

                            // Remote cloud update
                            _firestoreService.deleteCourse(
                              uid: widget.studentID,
                              courseCode: targetCode,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _statCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.onSurface.withOpacity(0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBg,
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
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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
}
