import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_nthu_life/data/semester.dart';
import 'package:my_nthu_life/main.dart';
import 'dart:convert';

class CreditPage extends StatefulWidget {
  final String studentID;
  const CreditPage({super.key, required this.studentID});

  @override
  State<CreditPage> createState() => _CreditPageState();
}

class _CreditPageState extends State<CreditPage> {
  final int graduationCredits = 128;
  List<Semester> semesters = [
    Semester(semesterName: "Semester 1", courses: []),
  ];
  int currentSemesterIndex = 0;

  // ===== COLORS =====
  static const bgColor = Color(0xFF1A1520);
  static const cardColor = Color(0xFF221E2A);
  static const borderColor = Color(0x33A78BFA);
  static const purpleMain = Color(0xFF7C3AED);
  static const purpleLight = Color(0xFFA78BFA);
  static const purpleDark = Color(0xFF6D28D9);

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
    final prefs = await SharedPreferences.getInstance();
    String? encoded = prefs.getString("Semesters_${widget.studentID}");
    if (encoded != null) {
      final List<dynamic> decodedData = jsonDecode(encoded);
      setState(() {
        semesters = decodedData.map((item) => Semester.fromJson(item)).toList();
      });
      totalCreditsNotifier.value = totalCredits;
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

  // ===== CRUD =====
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
            return Dialog(
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Add Course",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _dialogTextField("Course Name", onChanged: (v) => name = v),
                    const SizedBox(height: 12),
                    _dialogTextField("Course Code", onChanged: (v) => code = v),
                    const SizedBox(height: 12),
                    _dialogTextField(
                      "Credits",
                      keyboardType: TextInputType.number,
                      onChanged: (v) => creditInput = v,
                    ),
                    const SizedBox(height: 12),
                    // Grade dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3F3F46),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF52525B)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedGrade,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF3F3F46),
                          style: const TextStyle(color: Colors.white),
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
                              backgroundColor: const Color(0xFF6158E4),
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
                            child: const Text(
                              "Add",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3F3F46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(color: Colors.white),
                            ),
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
    String label, {
    TextInputType keyboardType = TextInputType.text,
    required Function(String) onChanged,
  }) {
    return TextField(
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: label,
        hintStyle: const TextStyle(color: Color(0xFF71717A)),
        filled: true,
        fillColor: const Color(0xFF3F3F46),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF52525B)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF52525B)),
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

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    final gpa = semesterGPA;

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 85),
        child: FloatingActionButton(
          onPressed: showAddCourseDialog,
          backgroundColor: purpleMain,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.menu_book, color: Color(0xFFD8B4FE), size: 24),
                    SizedBox(width: 8),
                    Text(
                      "Transcript",
                      style: TextStyle(
                        color: Colors.white,
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
                    gradient: const LinearGradient(
                      colors: [Color(0x4D7C3AED), Color(0x337C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        color: Color(0xFFFACC15),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${semesters.fold(0, (sum, s) => sum + s.courses.length)} courses",
                        style: const TextStyle(
                          color: Color(0xFFFDE047),
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

            // ── Total Credits Progress ──
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0x0DFFFFFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x1AFFFFFF)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total Credits",
                        style: TextStyle(
                          color: Color(0xCCFFFFFF),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        "$totalCredits/$graduationCredits",
                        style: const TextStyle(
                          color: Color(0xFFD8B4FE),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: (totalCredits / graduationCredits).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: const Color(0x1AFFFFFF),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        purpleMain,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Semester Selector ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    if (currentSemesterIndex > 0) {
                      setState(() => currentSemesterIndex--);
                    }
                  },
                  icon: const Icon(Icons.chevron_left, color: Colors.white70),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0x337C3AED), Color(0x267C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: Text(
                    currentSemester.semesterName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (currentSemesterIndex < semesters.length - 1) {
                      setState(() => currentSemesterIndex++);
                    } else {
                      // Add new semester
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
                  icon: const Icon(Icons.chevron_right, color: Colors.white70),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Stats Cards ──
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 3.5,
              children: [
                _statCard(
                  icon: Icons.menu_book,
                  iconColor: purpleLight,
                  iconBg: const Color(0x337C3AED),
                  label: "Credits",
                  value: "$semesterCredits",
                ),
                _statCard(
                  icon: Icons.trending_up,
                  iconColor: const Color(0xFF86EFAC),
                  iconBg: const Color(0x3322C55E),
                  label: "GPA",
                  value: currentSemester.courses.isEmpty
                      ? "0.00"
                      : "${gpa.toStringAsFixed(2)} (${getLetterGrade(gpa)})",
                  valueColor: Colors.white,
                ),
                _statCard(
                  icon: Icons.school,
                  iconColor: const Color(0xFF93C5FD),
                  iconBg: const Color(0x333B82F6),
                  label: "T-Score",
                  value: "–",
                ),
                _statCard(
                  icon: Icons.emoji_events,
                  iconColor: const Color(0xFFFDE047),
                  iconBg: const Color(0x33EAB308),
                  label: "Rank",
                  value: "–",
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Course List ──
            if (currentSemester.courses.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: const [
                      Icon(Icons.menu_book, size: 40, color: Color(0x4DFFFFFF)),
                      SizedBox(height: 12),
                      Text(
                        "No courses for this semester",
                        style: TextStyle(
                          color: Color(0x80FFFFFF),
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
                      color: const Color(0x0DFFFFFF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0x1AFFFFFF)),
                    ),
                    child: Row(
                      children: [
                        // Icon
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0x337C3AED),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.menu_book,
                            color: purpleLight,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Name & code
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course['name'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                course['code'] ?? 'Course Code',
                                style: const TextStyle(
                                  color: Color(0x66FFFFFF),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Credits
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              "Credits",
                              style: TextStyle(
                                color: Color(0x80FFFFFF),
                                fontSize: 9,
                              ),
                            ),
                            Text(
                              "${course['credits']}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        // Grade badge
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
                            border: Border.all(color: borderColor),
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
                        // Delete
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Color(0x80FFFFFF),
                            size: 18,
                          ),
                          onPressed: () {
                            setState(
                              () => currentSemester.courses.removeAt(entry.key),
                            );
                            saveCourses();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
    Color valueColor = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x1AFFFFFF)),
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
                  style: const TextStyle(
                    color: Color(0x99FFFFFF),
                    fontSize: 10,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor,
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
